# AWS Serverless Image Processing Pipeline

An event-driven, serverless image processing pipeline built using **AWS Lambda, Amazon S3, Amazon DynamoDB, Amazon CloudWatch, Python, and Terraform**.

## Project Overview

This project demonstrates how AWS serverless services can work together to automatically process uploaded images without managing traditional servers.

When an image is uploaded to the `uploads/` prefix of an Amazon S3 bucket, an S3 event notification invokes an AWS Lambda function. The function uses Python and Pillow to generate a thumbnail, stores the processed image in S3, and records image metadata in DynamoDB.

Terraform is used to provision and manage the infrastructure as code.

## Architecture

```text
             User uploads image
                     |
                     v
              Amazon S3 Bucket
                 uploads/
                     |
                     v
             S3 Event Notification
                     |
                     v
               AWS Lambda
              (Python + Pillow)
                  /      \
                 v        v
         S3 processed/   DynamoDB
          (Thumbnail)    (Metadata)
                 |
          CloudWatch Logs
```

## AWS Services and Tools

| Service / Tool | Purpose |
|---|---|
| Amazon S3 | Store uploaded and processed images |
| AWS Lambda | Automatically process images |
| Amazon DynamoDB | Store image metadata |
| Amazon CloudWatch | Monitor execution logs |
| AWS IAM | Manage service permissions |
| Terraform | Provision AWS infrastructure |
| Python | Implement image processing logic |
| Pillow | Resize and convert images |
| Git and GitHub | Version control and project documentation |

## How It Works

1. An image is uploaded to the `uploads/` prefix in S3.
2. An S3 event notification invokes the Lambda function.
3. Lambda downloads the uploaded image.
4. Pillow resizes the image to fit within 300 × 300 pixels.
5. The thumbnail is saved as a JPEG under the `processed/` prefix.
6. Image metadata is written to the DynamoDB `ImageMetadata` table.
7. Execution details and errors are logged to Amazon CloudWatch.

## Image Metadata

The DynamoDB record includes:

- Image ID
- Original filename and processed filename
- Original file size
- Original image dimensions
- Resized image dimensions
- Original image format
- Processing status
- Processing timestamp

## Project Structure

```text
aws-serverless-image-processing-pipeline/
├── lambda/
│   ├── lambda_function.py
│   └── requirements.txt
├── terraform/
│   ├── providers.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── screenshots/
├── sample-images/
├── create_zip.py
├── .gitignore
└── README.md
```

## Deployment

The project is designed to be deployed using Terraform in an AWS account with the required permissions.

Before deployment:

1. Configure AWS credentials securely.
2. Build the Lambda deployment ZIP with Linux-compatible Python dependencies.
3. Supply a unique S3 bucket suffix.
4. Initialize Terraform.
5. Review the Terraform execution plan.
6. Apply the infrastructure configuration.

**Note:** The generated Lambda deployment ZIP, credentials, and Terraform state are excluded from version control.

## Security Considerations

- S3 public access is blocked.
- S3 server-side encryption is enabled.
- Lambda uses a dedicated IAM role with scoped permissions.
- DynamoDB stores metadata rather than image contents.
- Sensitive credentials and local Terraform state are not committed to GitHub.

## Project Status

Infrastructure code and Lambda application code have been prepared locally. AWS deployment and end-to-end testing are pending.

## Future Improvements

- Add automated deployment with GitHub Actions.
- Add image format and file-size validation.
- Implement dead-letter queues and retry monitoring.
- Add CI checks for Terraform and Python.
- Improve handling of duplicate S3 events.

## Author

Kartik Saxena

Cloud and DevOps enthusiast focused on AWS, infrastructure automation, and serverless technologies.
