---
layout: post
title: "Event-Driven Architecture: S3 Triggers and Logic"
date: 2025-11-21 18:00:00 -0400
categories: [System Design]
tags: [EventDriven, S3, Lambda, Architecture, Automation]
excerpt: "In traditional programming, if you want to process a file, you write a script that checks a folder. In the cloud, we invert this control. We don't check for files; the file announces its arrival."
---

In traditional programming, if you want to process a file, you write a script that checks a folder, finds the file, and processes it. In the cloud, we invert this control. We don't check for files; the file announces its arrival. This is Event-Driven Architecture. By wiring our S3 bucket to our Lambda function, we create a system that is dormant when empty and instantly active when data arrives. This is the secret to cost-effective scaling, and today, we will build the connective tissue that makes it possible.

## The Difference: Polling vs. Events

**Polling (The Old Way):**
```python
# Check for files every minute
while True:
    files = check_folder()
    if files:
        process_files(files)
    time.sleep(60)  # Waste resources checking
```

**Events (The New Way):**
```python
# Function only runs when a file arrives
def lambda_handler(event, context):
    # Process the file that just arrived
    process_file(event)
```

Events are more efficient, more scalable, and more cost-effective. Your code only runs when there's work to do.

## The Trigger Mechanism

S3 can send events to Lambda when objects are created, deleted, or modified. Let's configure this:

```python
import boto3
import json

s3 = boto3.client('s3')
lambda_client = boto3.client('lambda')

def configure_s3_lambda_trigger(bucket_name, function_name):
    """Configure S3 to trigger Lambda on object creation."""
    
    # Get the Lambda function ARN
    function_response = lambda_client.get_function(FunctionName=function_name)
    function_arn = function_response['Configuration']['FunctionArn']
    
    # Create the notification configuration
    notification_config = {
        'LambdaFunctionConfigurations': [
            {
                'Id': 'ProcessNewObjects',
                'LambdaFunctionArn': function_arn,
                'Events': ['s3:ObjectCreated:*'],  # All object creation events
                'Filter': {
                    'Key': {
                        'FilterRules': [
                            {
                                'Name': 'prefix',
                                'Value': 'uploads/'  # Only files in uploads/ folder
                            },
                            {
                                'Name': 'suffix',
                                'Value': '.csv'  # Only CSV files
                            }
                        ]
                    }
                }
            }
        ]
    }
    
    # Apply the configuration
    s3.put_bucket_notification_configuration(
        Bucket=bucket_name,
        NotificationConfiguration=notification_config
    )
    
    print(f"✅ Configured S3 trigger for {bucket_name} -> {function_name}")
```

## Permissions: The Glue

S3 needs permission to invoke your Lambda function. This is done through a resource-based policy:

```python
def allow_s3_to_invoke_lambda(function_name, bucket_name):
    """Grant S3 permission to invoke Lambda function."""
    
    # Get account ID for the source ARN
    sts = boto3.client('sts')
    account_id = sts.get_caller_identity()['Account']
    
    source_arn = f'arn:aws:s3:::${bucket_name}'
    
    # Add permission
    lambda_client.add_permission(
        FunctionName=function_name,
        StatementId='AllowS3Invoke',
        Action='lambda:InvokeFunction',
        Principal='s3.amazonaws.com',
        SourceArn=source_arn
    )
    
    print(f"✅ Granted S3 permission to invoke {function_name}")
```

### Security: Scoping the Permission

Notice the `SourceArn` parameter. This restricts the permission to only the specific bucket. Without this, any S3 bucket in your account could invoke the function. Always scope permissions to the minimum required.

## Parsing the Event Payload

When S3 triggers your Lambda, the event structure looks like this:

```json
{
  "Records": [
    {
      "eventVersion": "2.1",
      "eventSource": "aws:s3",
      "awsRegion": "us-east-1",
      "eventTime": "2024-01-15T10:30:00.000Z",
      "eventName": "ObjectCreated:Put",
      "s3": {
        "bucket": {
          "name": "my-bucket",
          "arn": "arn:aws:s3:::my-bucket"
        },
        "object": {
          "key": "uploads/data.csv",
          "size": 1024
        }
      }
    }
  ]
}
```

### Extracting Bucket and Key

```python
def lambda_handler(event, context):
    """Process S3 object creation events."""
    
    s3_client = boto3.client('s3')
    
    # Process each record (S3 can batch multiple events)
    for record in event['Records']:
        # Extract bucket and key
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        
        # Handle URL encoding (spaces become +)
        key = key.replace('+', ' ')
        
        print(f"Processing: s3://{bucket}/{key}")
        
        # Download the file
        response = s3_client.get_object(Bucket=bucket, Key=key)
        content = response['Body'].read()
        
        # Process the content
        process_file(content, key)
    
    return {'statusCode': 200, 'body': 'Processed successfully'}
```

### Critical Insight: Event Contains Metadata, Not Content

The S3 event tells you **which file** was created, but it doesn't contain the file content. You must call `s3.get_object()` to read the actual file. This is important for large files—the event is small, but downloading the file might take time and memory.

### Handling URL Encoding

S3 keys are URL-encoded in events. A file named "my file.csv" becomes "my+file.csv" in the event. Always decode:

```python
import urllib.parse

key = urllib.parse.unquote_plus(record['s3']['object']['key'])
```

## Complete Example: Image Processing Pipeline

Let's build a complete example that processes images:

```python
import boto3
import json
from PIL import Image
import io

s3 = boto3.client('s3')

def lambda_handler(event, context):
    """Process images uploaded to S3."""
    
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = urllib.parse.unquote_plus(record['s3']['object']['key'])
        
        # Only process images
        if not key.lower().endswith(('.jpg', '.jpeg', '.png')):
            continue
        
        # Download image
        response = s3.get_object(Bucket=bucket, Key=key)
        image_data = response['Body'].read()
        
        # Process image
        image = Image.open(io.BytesIO(image_data))
        
        # Create thumbnail
        image.thumbnail((200, 200))
        
        # Save to buffer
        thumb_buffer = io.BytesIO()
        image.save(thumb_buffer, format='JPEG')
        thumb_buffer.seek(0)
        
        # Upload thumbnail
        thumb_key = f"thumbnails/{key}"
        s3.put_object(
            Bucket=bucket,
            Key=thumb_key,
            Body=thumb_buffer.getvalue(),
            ContentType='image/jpeg'
        )
        
        print(f"✅ Created thumbnail: {thumb_key}")
    
    return {'statusCode': 200}
```

## Error Handling

S3 events are "fire and forget." If your Lambda fails, S3 doesn't retry automatically. You need to handle errors:

```python
def lambda_handler(event, context):
    """Process S3 events with error handling."""
    
    failed_records = []
    
    for record in event['Records']:
        try:
            bucket = record['s3']['bucket']['name']
            key = record['s3']['object']['key']
            
            # Process the file
            process_file(bucket, key)
            
        except Exception as e:
            print(f"❌ Error processing {key}: {e}")
            failed_records.append({
                'bucket': bucket,
                'key': key,
                'error': str(e)
            })
    
    # If there are failures, you might want to:
    # 1. Send to Dead Letter Queue (DLQ)
    # 2. Store in DynamoDB for retry
    # 3. Send alert to SNS
    
    if failed_records:
        send_to_dlq(failed_records)
    
    return {'statusCode': 200}
```

## The Foundation Is Set

You've built the foundation of an event-driven data pipeline. Files arrive in S3, Lambda processes them automatically, and the system scales without manual intervention. This pattern is the backbone of modern data engineering.

In the next post, we'll dive deeper into S3, exploring lifecycle policies, versioning, and encryption—making your storage enterprise-ready.

