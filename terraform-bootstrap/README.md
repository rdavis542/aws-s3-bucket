# Terraform State Backend Bootstrap

This directory contains the bootstrap configuration for creating AWS infrastructure to store Terraform state files with replication and locking.

## What This Creates

1. **Source S3 Bucket** (us-east-2) - Primary state file storage
2. **Destination S3 Bucket** (us-west-2) - Replicated backup
3. **DynamoDB Table** (us-east-2) - State locking to prevent concurrent modifications
4. **IAM Role** - For S3 cross-region replication

## Features

✅ **Versioning** - Keep history of state file changes (90-day retention)
✅ **Replication** - Automatic cross-region backup
✅ **Encryption** - AES256 server-side encryption
✅ **Locking** - DynamoDB prevents concurrent modifications
✅ **Public Access Blocked** - Security best practice
✅ **Point-in-Time Recovery** - DynamoDB backup capability

## Bootstrap Process

### Step 1: Deploy the Infrastructure

From this directory:

```bash
cd terraform-bootstrap

# Initialize Terraform (uses local state initially)
terraform init

# Review what will be created
terraform plan

# Create the infrastructure
terraform apply
```

### Step 2: Save the Outputs

After successful apply:

```bash
# Save bucket and table names
terraform output source_bucket_name
terraform output dynamodb_table_name

# Or get the full backend config
terraform output backend_config
```

Example output:
```
source_bucket_name = "tf-state-replication-source-123456789012"
dynamodb_table_name = "tf-state-replication-lock"
```

### Step 3: Migrate Bootstrap State to S3 (Optional but Recommended)

Once the buckets exist, you can migrate the bootstrap state itself to S3:

1. Add backend configuration to this directory's `main.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "tf-state-replication-source-123456789012"  # Use output value
    key            = "bootstrap/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "tf-state-replication-lock"
    encrypt        = true
  }
}
```

2. Run migration:

```bash
terraform init -migrate-state
```

3. Confirm migration when prompted

4. Delete local state files:

```bash
rm terraform.tfstate*
```

### Step 4: Use in Your Main Terraform Project

Update your main project's `terraform/provider.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "tf-state-replication-source-123456789012"  # From output
    key            = "s3-bucket-terraform.tfstate"               # Your state file name
    region         = "us-east-2"
    dynamodb_table = "tf-state-replication-lock"                # From output
    encrypt        = true
  }
}
```

Then migrate:

```bash
cd ../terraform
terraform init -migrate-state
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Terraform Workflow                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Primary Region (us-east-2)                      │
│                                                               │
│  ┌──────────────────────────┐   ┌────────────────────────┐  │
│  │   Source S3 Bucket       │   │  DynamoDB Lock Table   │  │
│  │  (State Files)           │   │  (Prevents conflicts)  │  │
│  │  - Versioned             │   │  - Pay per request     │  │
│  │  - Encrypted             │   │  - PITR enabled        │  │
│  └──────────────────────────┘   └────────────────────────┘  │
│              │                                                │
└──────────────┼────────────────────────────────────────────────┘
               │
               │ Automatic Replication
               ▼
┌─────────────────────────────────────────────────────────────┐
│              Replica Region (us-west-2)                      │
│                                                               │
│  ┌──────────────────────────┐                                │
│  │  Destination S3 Bucket   │                                │
│  │  (Backup Copy)           │                                │
│  │  - Versioned             │                                │
│  │  - Encrypted             │                                │
│  └──────────────────────────┘                                │
└─────────────────────────────────────────────────────────────┘
```

## Cost Estimate

### Monthly Costs (Approximate)

| Service | Usage | Cost |
|---------|-------|------|
| S3 Storage (Source) | 1GB state files | ~$0.023 |
| S3 Storage (Replica) | 1GB replicated | ~$0.023 |
| S3 Requests | ~1000/month | ~$0.01 |
| S3 Replication | 1GB transfer | ~$0.02 |
| DynamoDB | PAY_PER_REQUEST | ~$0.25 |
| **Total** | | **~$0.33/month** |

Very affordable for the reliability and safety benefits!

## Security Features

### S3 Buckets
- ✅ Public access completely blocked
- ✅ Versioning enabled (prevents accidental deletion)
- ✅ Server-side encryption (AES256)
- ✅ Bucket keys enabled (reduced KMS costs if you upgrade to KMS)

### DynamoDB
- ✅ Server-side encryption enabled
- ✅ Point-in-time recovery enabled
- ✅ Pay-per-request billing (cost-effective)

### IAM
- ✅ Least privilege permissions for replication role
- ✅ Role restricted to S3 service only

## Disaster Recovery

### Primary Region Failure
- State files automatically replicated to us-west-2
- Can switch backend region to replica bucket
- DynamoDB table would need manual failover

### State File Corruption
- Version history retained for 90 days
- Can restore previous version from S3
- Replica provides additional backup

### Recovery Procedure

1. List available versions:
```bash
aws s3api list-object-versions \
  --bucket tf-state-replication-source-123456789012 \
  --prefix s3-bucket-terraform.tfstate
```

2. Download specific version:
```bash
aws s3api get-object \
  --bucket tf-state-replication-source-123456789012 \
  --key s3-bucket-terraform.tfstate \
  --version-id <version-id> \
  terraform.tfstate.backup
```

## Troubleshooting

### Replication Not Working

Check IAM role permissions:
```bash
terraform output | grep replication
```

Verify replication status:
```bash
aws s3api get-bucket-replication \
  --bucket tf-state-replication-source-123456789012
```

### State Locking Issues

Check DynamoDB table:
```bash
aws dynamodb describe-table \
  --table-name tf-state-replication-lock
```

Force unlock (use with caution):
```bash
terraform force-unlock <lock-id>
```

### Access Denied Errors

Ensure your AWS credentials have permissions:
- `s3:GetObject`, `s3:PutObject` on state bucket
- `dynamodb:PutItem`, `dynamodb:GetItem`, `dynamodb:DeleteItem` on lock table

## Maintenance

### Update Lifecycle Policy

Modify retention period in `main.tf`:
```hcl
noncurrent_version_expiration = {
  days = 90  # Change this value
}
```

### Monitor Costs

```bash
# Check S3 storage
aws s3 ls s3://tf-state-replication-source-123456789012 --recursive --summarize

# Check DynamoDB usage
aws dynamodb describe-table \
  --table-name tf-state-replication-lock \
  --query 'Table.BillingModeSummary'
```

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `primary_region` | us-east-2 | Primary region for state storage |
| `replica_region` | us-west-2 | Replica region for backup |
| `bucket_prefix` | tf-state-replication | Prefix for resource names |

## Outputs

| Output | Description |
|--------|-------------|
| `source_bucket_name` | Primary bucket name for backend config |
| `destination_bucket_name` | Replica bucket name |
| `dynamodb_table_name` | Lock table name for backend config |
| `backend_config` | Complete backend configuration example |

## Best Practices

1. **Never commit state files** - Add `*.tfstate*` to `.gitignore`
2. **Use state locking** - Always include DynamoDB table in backend
3. **Enable versioning** - Already configured in this setup
4. **Regular backups** - Replication provides automatic backup
5. **Access control** - Limit who can read/write state files
6. **Encryption** - Already enabled (AES256)

## References

- [Terraform S3 Backend](https://www.terraform.io/docs/language/settings/backends/s3.html)
- [S3 Versioning](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html)
- [S3 Replication](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication.html)
- [DynamoDB State Locking](https://www.terraform.io/docs/language/settings/backends/s3.html#dynamodb-state-locking)
