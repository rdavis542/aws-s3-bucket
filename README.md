# aws-s3-bucket

Terraform project that provisions two cross-region S3 buckets with replication — a source bucket in `us-east-2` and a destination bucket in `us-west-2`. Includes the IAM role and policy required for S3 to perform replication.

## Structure

```
terraform/          # Main infrastructure
terraform-bootstrap/ # State backend infrastructure (S3 + DynamoDB)
.github/workflows/  # CI/CD pipelines
```

## Prerequisites

Run `terraform-bootstrap` once to create the S3 state backend before deploying the main configuration.

## Usage

```bash
cd terraform
terraform init
terraform plan -var-file="terraform-s3.tfvars"
terraform apply -var-file="terraform-s3.tfvars"
```

## Variables

| Name | Description | Default |
|---|---|---|
| `region` | AWS region for the default provider | `us-east-2` |
| `primary_region` | Primary region for the source bucket | `us-east-2` |
| `replica_region` | Replica region for the destination bucket | `us-west-2` |
| `bucket_prefix` | Prefix for bucket names | `tf-state-replication` |

## Outputs

| Name | Description |
|---|---|
| `source_bucket_id` | Name of the source bucket |
| `source_bucket_arn` | ARN of the source bucket |
| `destination_bucket_id` | Name of the destination bucket |
| `destination_bucket_arn` | ARN of the destination bucket |
| `replication_role_arn` | ARN of the IAM replication role |

## Workflows

| Workflow | Trigger | Description |
|---|---|---|
| `tf-create.yml` | Push/PR to main, manual | Plan on push/PR, apply on manual trigger |
| `tf-destroy.yml` | Manual only | Destroy with "destroy" confirmation required |
| `tf-drift-detection.yml` | Daily 9AM UTC, manual | Detects infrastructure drift and opens GitHub issues |
| `tfsec.yml` | Push/PR to main, weekly | Security scanning with SARIF upload |
