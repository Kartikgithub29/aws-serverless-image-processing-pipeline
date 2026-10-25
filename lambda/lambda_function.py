
import os
import json
import uuid
import logging
from io import BytesIO
from urllib.parse import unquote_plus
from datetime import datetime, timezone

import boto3
from PIL import Image, UnidentifiedImageError

# AWS clients
s3 = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")

# Configuration supplied by Terraform
TABLE_NAME = os.environ.get("TABLE_NAME", "ImageMetadata")
OUTPUT_PREFIX = "processed/"
MAX_SIZE = (300, 300)

table = dynamodb.Table(TABLE_NAME)

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    for record in event.get("Records", []):
        bucket = record["s3"]["bucket"]["name"]
        key = unquote_plus(record["s3"]["object"]["key"])

        # Avoid processing our own output files
        if not key.startswith("uploads/"):
            logger.info("Skipping key: %s", key)
            continue

        logger.info("Processing: s3://%s/%s", bucket, key)

        try:
            response = s3.get_object(Bucket=bucket, Key=key)
            image_bytes = response["Body"].read()
            file_size = len(image_bytes)

            with Image.open(BytesIO(image_bytes)) as image:
                original_width, original_height = image.size
                image_format = image.format

                # Convert to RGB so the output can be saved as JPEG
                if image.mode in ("RGBA", "P"):
                    image = image.convert("RGB")
                elif image.mode != "RGB":
                    image = image.convert("RGB")

                image.thumbnail(MAX_SIZE)

                resized_width, resized_height = image.size

                output_buffer = BytesIO()
                image.save(
                    output_buffer,
                    format="JPEG",
                    quality=85
                )

            # Unique output name for each processed event
            image_id = str(uuid.uuid4())
            output_key = f"{OUTPUT_PREFIX}{image_id}.jpg"

            s3.put_object(
                Bucket=bucket,
                Key=output_key,
                Body=output_buffer.getvalue(),
                ContentType="image/jpeg"
            )

            table.put_item(
                Item={
                    "ImageId": image_id,
                    "OriginalFile": key,
                    "ProcessedFile": output_key,
                    "FileSizeBytes": file_size,
                    "OriginalWidth": original_width,
                    "OriginalHeight": original_height,
                    "ResizedWidth": resized_width,
                    "ResizedHeight": resized_height,
                    "OriginalFormat": image_format or "UNKNOWN",
                    "Status": "SUCCESS",
                    "ProcessedAt": datetime.now(timezone.utc).isoformat()
                }
            )

            logger.info(
                "Successfully processed %s -> %s",
                key,
                output_key
            )

        except (UnidentifiedImageError, OSError) as error:
            logger.error("Invalid image %s: %s", key, error)
            raise

        except Exception:
            logger.exception("Processing failed for %s", key)
            raise

    return {
        "statusCode": 200,
        "body": json.dumps("Image processing completed")
    }
