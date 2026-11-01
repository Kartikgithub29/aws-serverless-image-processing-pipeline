
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix for AWS resource names"
  type        = string
  default     = "serverless-image-pipeline"
}

variable "bucket_suffix" {
  description = "Unique suffix for the S3 bucket name"
  type        = string
}
