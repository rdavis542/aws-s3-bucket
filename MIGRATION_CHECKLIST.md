# Terraform State Migration Checklist

## Overview
This guide helps you migrate your current Terraform state from `tfstategit` bucket to your new replicated S3 bucket setup with DynamoDB locking.

## Prerequisites
- [ ] AWS CLI configured with appropriate credentials
- [ ] Access to existing state bucket: `tfstategit`
- [ ] Terraform 1.1.0+ installed

## Phase 1: Create State Backend Infrastructure

### 1.1 Deploy Bootstrap Infrastructure
```bash
cd terraform-bootstrap
terraform init
terraform plan
terraform apply
```

**Expected Resources Created:**
- Source S3 bucket: `tf-state-replication-source-{account-id}`
- Destination S3 bucket: `tf-state-replication-destination-{account-id}`
- DynamoDB table: `tf-state-replication-lock`
- IAM replication role

### 1.2 Capture Outputs
```bash
# Save these values - you'll need them!
terraform output source_bucket_name > ../bucket-name.txt
terraform output dynamodb_table_name > ../dynamodb-name.txt
terraform output backend_config
```

**Save these values:**
- Source bucket: ________________
- DynamoDB table: ________________
- Primary region: us-east-2

---

## Phase 2: Migrate Bootstrap State (Optional)

### 2.1 Update Bootstrap Backend
Edit `terraform-bootstrap/main.tf` and add backend config after line 13:

```hcl
terraform {
  backend "s3" {
    bucket         = "tf-state-replication-source-XXXXXXXX"  # Use your actual bucket name
    key            = "bootstrap/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "tf-state-replication-lock"
    encrypt        = true
  }
}
```

### 2.2 Run Migration
```bash
cd terraform-bootstrap
terraform init -migrate-state
# Type 'yes' when prompted
```

### 2.3 Verify Migration
```bash
# Check state is in S3
aws s3 ls s3://tf-state-replication-source-XXXXXXXX/bootstrap/

# Delete local state files
rm terraform.tfstate*
```

---

## Phase 3: Migrate Main Project State

### 3.1 Backup Current State
```bash
cd terraform

# Download current state from tfstategit bucket
aws s3 cp s3://tfstategit/s3-bucket-terraform.tfstate ./terraform.tfstate.backup

# Keep local backup too
cp terraform.tfstate terraform.tfstate.local-backup
```

### 3.2 Update Backend Configuration
Edit `terraform/provider.tf` lines 9-14:

**Before:**
```hcl
backend "s3" {
  bucket  = "tfstategit"
  key     = "s3-bucket-terraform.tfstate"
  region  = "us-east-1"
  encrypt = true
}
```

**After:**
```hcl
backend "s3" {
  bucket         = "tf-state-replication-source-XXXXXXXX"  # Your new bucket
  key            = "projects/s3-bucket-terraform.tfstate"
  region         = "us-east-2"
  dynamodb_table = "tf-state-replication-lock"
  encrypt        = true
}
```

### 3.3 Update Provider Region
Edit `terraform/provider.tf` line 20:

**Before:**
```hcl
provider "aws" {
  region = "us-east-1"
}
```

**After:**
```hcl
provider "aws" {
  region = "us-east-2"  # Match backend region
}
```

### 3.4 Run Migration
```bash
cd terraform
terraform init -migrate-state
```

**You'll see:**
```
Initializing the backend...
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "s3" backend to the
  newly configured "s3" backend. No existing state was found in the newly
  configured "s3" backend. Do you want to copy this state to the new "s3"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: yes
```

Type `yes` and press Enter.

### 3.5 Verify Migration
```bash
# Check state is in new bucket
aws s3 ls s3://tf-state-replication-source-XXXXXXXX/projects/

# Verify lock table works
terraform plan  # Should acquire lock successfully

# Check replication to backup bucket
aws s3 ls s3://tf-state-replication-destination-XXXXXXXX/projects/
```

### 3.6 Test State Locking
Open two terminal windows and try running `terraform plan` in both simultaneously. One should wait for the lock.

---

## Phase 4: Update GitHub Workflows

### 4.1 Update Workflow Environment Variables
The workflows already have the correct regions set, but verify:

**Files to check:**
- `.github/workflows/tf-create.yml`
- `.github/workflows/tf-destroy.yml`
- `.github/workflows/tf-drift-detection.yml`

All should have:
```yaml
env:
  AWS_REGION: us-east-2  # Should match backend region
```

### 4.2 Test Workflow
```bash
# Commit changes
git add .
git commit -m "Migrate to replicated state backend with DynamoDB locking"
git push origin feat/initial-build

# Create PR and verify workflow runs successfully
```

---

## Phase 5: Cleanup (Optional)

### 5.1 Verify Old State Not Used
```bash
# Check last modified date of old state
aws s3 ls s3://tfstategit/ --recursive

# If no recent activity, old bucket is not being used
```

### 5.2 Archive Old State (Don't Delete Yet!)
```bash
# Download archive copy
aws s3 cp s3://tfstategit/s3-bucket-terraform.tfstate ./old-state-archive.tfstate

# Tag old bucket for deletion in 90 days
aws s3api put-bucket-tagging \
  --bucket tfstategit \
  --tagging 'TagSet=[{Key=DeleteAfter,Value=2026-04-15}]'
```

**Wait 90 days before deleting** to ensure everything works.

---

## Verification Checklist

After migration, verify:

- [ ] `terraform plan` runs successfully
- [ ] State locking works (try concurrent plans)
- [ ] State file visible in primary bucket (us-east-2)
- [ ] State file replicated to backup bucket (us-west-2)
- [ ] GitHub workflows run successfully
- [ ] Can restore from backup if needed
- [ ] Old state backed up locally
- [ ] Team members updated on new backend

---

## Rollback Procedure (If Issues Arise)

### Option 1: Quick Rollback
```bash
cd terraform

# Restore original backend config
git checkout HEAD -- provider.tf

# Re-initialize with old backend
terraform init -reconfigure

# Copy backup state back
cp terraform.tfstate.local-backup terraform.tfstate
```

### Option 2: Restore from S3
```bash
# Get version ID of last working state
aws s3api list-object-versions \
  --bucket tf-state-replication-source-XXXXXXXX \
  --prefix projects/s3-bucket-terraform.tfstate

# Download specific version
aws s3api get-object \
  --bucket tf-state-replication-source-XXXXXXXX \
  --key projects/s3-bucket-terraform.tfstate \
  --version-id <version-id> \
  terraform.tfstate
```

---

## Troubleshooting

### "Error acquiring the state lock"
**Cause:** Another process is using the state, or stale lock

**Solution:**
```bash
# Check who has the lock
aws dynamodb get-item \
  --table-name tf-state-replication-lock \
  --key '{"LockID":{"S":"tf-state-replication-source-XXXXXXXX/projects/s3-bucket-terraform.tfstate-md5"}}'

# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

### "AccessDenied" when accessing new bucket
**Cause:** IAM permissions not configured

**Solution:**
```bash
# Verify credentials
aws sts get-caller-identity

# Test bucket access
aws s3 ls s3://tf-state-replication-source-XXXXXXXX/
```

### Replication not working
**Cause:** IAM role or bucket policy issue

**Solution:**
```bash
# Check replication status
aws s3api get-bucket-replication \
  --bucket tf-state-replication-source-XXXXXXXX

# Check IAM role
cd terraform-bootstrap
terraform output | grep replication
```

---

## Benefits After Migration

✅ **State Locking** - No more concurrent modification risks
✅ **Automatic Backup** - Cross-region replication
✅ **Version History** - 90-day retention of state versions
✅ **Better Security** - Encrypted, private buckets
✅ **Disaster Recovery** - Multi-region redundancy
✅ **Cost Effective** - ~$0.33/month

---

## Timeline

| Phase | Duration | Can Rollback? |
|-------|----------|---------------|
| Phase 1: Create infrastructure | 5 minutes | N/A |
| Phase 2: Migrate bootstrap | 2 minutes | Yes (local state exists) |
| Phase 3: Migrate main state | 5 minutes | Yes (backup exists) |
| Phase 4: Update workflows | 2 minutes | Yes (via git) |
| Phase 5: Cleanup | 1 minute | Yes (90 day retention) |
| **Total** | **~15 minutes** | |

---

## Support

If you encounter issues:
1. Check troubleshooting section above
2. Review Terraform logs: `TF_LOG=DEBUG terraform plan`
3. Verify AWS credentials: `aws sts get-caller-identity`
4. Check bucket permissions: `aws s3api get-bucket-policy --bucket <bucket-name>`

## Notes

- **Bucket naming:** Uses format `{prefix}-{type}-{account-id}` for global uniqueness
- **Regions:** Primary (us-east-2) and Replica (us-west-2)
- **Costs:** Very low (~$0.33/month), mostly DynamoDB
- **Recovery:** 90-day version retention allows point-in-time recovery
