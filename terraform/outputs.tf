
output "s3_bucket_name" {
  description = "Name of the image storage bucket"
  value       = aws_s3_bucket.images.bucket
}

output "dynamodb_table_name" {
  description = "DynamoDB table storing image metadata"
  value       = aws_dynamodb_table.metadata.name
}

output "lambda_function_name" {
  description = "Image processing Lambda function"
  value       = aws_lambda_function.processor.function_name
}

output "aws_region" {
  description = "AWS deployment region"
  value       = var.aws_region
}
