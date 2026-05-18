variable "primary_region" {
  description = "Primary AWS region for state bucket"
  type        = string
  default     = "us-east-2"
}

variable "replica_region" {
  description = "Replica AWS region for disaster recovery"
  type        = string
  default     = "us-west-2"
}

variable "bucket_prefix" {
  description = "Prefix for bucket and DynamoDB table names"
  type        = string
  default     = "tf-state-replication"
}
