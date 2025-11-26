variable "region" {
  type        = string
  description = "region you want to use"
  default = "us-east-1"
}

variable "default_tags" {
  description = "Default tags too apply to all resources"
  default = ""
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
