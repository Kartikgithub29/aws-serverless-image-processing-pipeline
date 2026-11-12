# ----------------------------------------
# DATA
# ----------------------------------------

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "lambda_trust" {

  statement {

    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {

      type = "Service"

      identifiers = [
        "lambda.amazonaws.com"
      ]

    }
  }
}



# ----------------------------------------
# 1. S3 BUCKET
# ----------------------------------------

resource "aws_s3_bucket" "images" {

  bucket = "${var.project_name}-${data.aws_caller_identity.current.account_id}"

  tags = {

    Project     = var.project_name
    Owner       = "Kartik"
    ManagedBy   = "Terraform"
    Environment = "Dev"

  }

}



resource "aws_s3_bucket_public_access_block" "images" {

  bucket = aws_s3_bucket.images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

}



resource "aws_s3_bucket_server_side_encryption_configuration" "images" {

  bucket = aws_s3_bucket.images.id

  rule {

    apply_server_side_encryption_by_default {

      sse_algorithm = "AES256"

    }

  }

}



resource "aws_s3_bucket_versioning" "images" {

  bucket = aws_s3_bucket.images.id

  versioning_configuration {

    status = "Enabled"

  }

}



# ----------------------------------------
# 2. DYNAMODB
# ----------------------------------------

resource "aws_dynamodb_table" "metadata" {

  name = "ImageMetadata"

  billing_mode = "PAY_PER_REQUEST"

  hash_key = "ImageId"


  attribute {

    name = "ImageId"

    type = "S"

  }


  tags = {

    Project     = var.project_name
    Owner       = "Kartik"
    ManagedBy   = "Terraform"
    Environment = "Dev"

  }

}



# ----------------------------------------
# 3. IAM ROLE
# ----------------------------------------

resource "aws_iam_role" "lambda_role" {

  name = "${var.project_name}-lambda-role"


  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json


  tags = {

    Project     = var.project_name
    Owner       = "Kartik"
    ManagedBy   = "Terraform"
    Environment = "Dev"

  }

}



data "aws_iam_policy_document" "lambda_permissions" {


  statement {

    sid = "ReadUploads"

    effect = "Allow"

    actions = [

      "s3:GetObject"

    ]

    resources = [

      "${aws_s3_bucket.images.arn}/uploads/*"

    ]

  }



  statement {

    sid = "WriteProcessed"

    effect = "Allow"

    actions = [

      "s3:PutObject"

    ]

    resources = [

      "${aws_s3_bucket.images.arn}/processed/*"

    ]

  }



  statement {

    sid = "DynamoDBWrite"

    effect = "Allow"

    actions = [

      "dynamodb:PutItem"

    ]

    resources = [

      aws_dynamodb_table.metadata.arn

    ]

  }



  statement {

    sid = "Logs"

    effect = "Allow"

    actions = [

      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"

    ]

    resources = [

      "*"

    ]

  }

}



resource "aws_iam_role_policy" "lambda_policy" {

  name = "${var.project_name}-policy"

  role = aws_iam_role.lambda_role.id

  policy = data.aws_iam_policy_document.lambda_permissions.json

}



# ----------------------------------------
# 4. CLOUDWATCH
# ----------------------------------------

resource "aws_cloudwatch_log_group" "lambda" {

  name = "/aws/lambda/${var.project_name}-processor"

  retention_in_days = 7


  tags = {

    Project     = var.project_name
    Owner       = "Kartik"
    ManagedBy   = "Terraform"
    Environment = "Dev"

  }

}



# ----------------------------------------
# 5. LAMBDA
# ----------------------------------------

resource "aws_lambda_function" "processor" {


  function_name = "${var.project_name}-processor"


  role = aws_iam_role.lambda_role.arn


  filename = "${path.module}/../build/lambda-deployment.zip"


  source_code_hash = filebase64sha256(
    "${path.module}/../build/lambda-deployment.zip"
  )


  handler = "lambda_function.lambda_handler"


  runtime = "python3.12"


  timeout = 60


  memory_size = 512


  environment {

    variables = {

      TABLE_NAME = aws_dynamodb_table.metadata.name

    }

  }


  depends_on = [

    aws_iam_role_policy.lambda_policy

  ]


  tags = {

    Project     = var.project_name
    Owner       = "Kartik"
    ManagedBy   = "Terraform"
    Environment = "Dev"

  }

}



# ----------------------------------------
# 6. ALLOW S3 TO CALL LAMBDA
# ----------------------------------------

resource "aws_lambda_permission" "allow_s3" {

  statement_id = "AllowS3Invoke"

  action = "lambda:InvokeFunction"

  function_name = aws_lambda_function.processor.function_name

  principal = "s3.amazonaws.com"

  source_arn = aws_s3_bucket.images.arn

}



# ----------------------------------------
# 7. S3 EVENT
# ----------------------------------------

resource "aws_s3_bucket_notification" "image_upload" {


  bucket = aws_s3_bucket.images.id


  lambda_function {

    lambda_function_arn = aws_lambda_function.processor.arn

    events = [

      "s3:ObjectCreated:*"

    ]

    filter_prefix = "uploads/"

  }


  depends_on = [

    aws_lambda_permission.allow_s3

  ]

}