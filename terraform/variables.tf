variable "region" {
  type        = string
  description = "AWS region for the default provider"
  default     = "us-east-2"
}

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-2"
}

variable "replica_region" {
  description = "Replica AWS region"
  type        = string
  default     = "us-west-2"
}

variable "bucket_prefix" {
  description = "Prefix for bucket names"
  type        = string
  default     = "tf-state-replication"
}
