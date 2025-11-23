---
layout: post
title: "Serverless Python: Your First AWS Lambda Function"
date: 2025-11-21 14:00:00 -0400
categories: [Serverless Computing]
tags: [Lambda, Serverless, Python, CloudCompute, AWS]
excerpt: "Imagine running your Python code without ever installing an operating system, patching a server, or paying for idle time. This is the promise of AWS Lambda."
---

Imagine running your Python code without ever installing an operating system, patching a server, or paying for idle time. This is the promise of AWS Lambda. It is the compute engine of the modern cloud, allowing you to run code in response to events. In this tutorial, we will write a 'Hello World' on steroids. We won't just print text; we will create a function that inspects its own environment and configuration. We will also look at how to deploy this code using Boto3, moving us closer to fully automated infrastructure where the code deploys itself.

## What is Serverless?

Serverless doesn't mean there are no servers. It means you don't manage them. AWS handles:
- Operating system patches
- Capacity planning
- Scaling (up to 1,000 concurrent executions)
- High availability

You just write code. AWS runs it when triggered.

### The Cost Model

Lambda charges you per millisecond of execution time and per request. If your function doesn't run, you pay nothing. This is perfect for:
- Event-driven processing
- Scheduled tasks
- API backends
- Data transformation

## The Lambda Handler Signature

Every Lambda function has a specific signature:

```python
def lambda_handler(event, context):
    """
    Lambda handler function.
    
    Args:
        event: The event that triggered the function (dict)
        context: Runtime information (LambdaContext)
    
    Returns:
        Response dictionary
    """
    return {
        'statusCode': 200,
        'body': 'Hello from Lambda!'
    }
```

### Understanding the Event Object

The `event` parameter contains the data that triggered your function. Its structure depends on the trigger:

**API Gateway event:**
```python
{
    'httpMethod': 'GET',
    'path': '/hello',
    'headers': {...},
    'queryStringParameters': {...},
    'body': '...'
}
```

**S3 event:**
```python
{
    'Records': [
        {
            's3': {
                'bucket': {'name': 'my-bucket'},
                'object': {'key': 'file.txt'}
            }
        }
    ]
}
```

**Scheduled event (CloudWatch Events):**
```python
{
    'version': '0',
    'id': '...',
    'detail-type': 'Scheduled Event',
    'source': 'aws.events',
    'time': '2024-01-15T10:30:00Z'
}
```

### Understanding the Context Object

The `context` object provides runtime information:

```python
def lambda_handler(event, context):
    print(f"Function name: {context.function_name}")
    print(f"Function version: {context.function_version}")
    print(f"Request ID: {context.aws_request_id}")
    print(f"Remaining time: {context.get_remaining_time_in_millis()}ms")
    
    return {'statusCode': 200}
```

The `get_remaining_time_in_millis()` method is crucial for long-running functions—it tells you how much time you have left before Lambda terminates your function.

## Writing Your First Function

Let's create a function that inspects its environment:

```python
import os
import json

def lambda_handler(event, context):
    """Inspect Lambda environment and configuration."""
    
    # Get environment variables
    env_vars = {
        key: value for key, value in os.environ.items()
        if not key.startswith('AWS_')  # Filter AWS internal vars
    }
    
    # Get context information
    context_info = {
        'function_name': context.function_name,
        'function_version': context.function_version,
        'request_id': context.aws_request_id,
        'remaining_time_ms': context.get_remaining_time_in_millis(),
        'memory_limit_mb': context.memory_limit_in_mb
    }
    
    # Inspect the event
    event_info = {
        'event_keys': list(event.keys()),
        'event_type': type(event).__name__,
        'event_size': len(json.dumps(event))
    }
    
    response = {
        'statusCode': 200,
        'environment_variables': env_vars,
        'context': context_info,
        'event': event_info,
        'message': 'Lambda function is running!'
    }
    
    return response
```

## Deploying Code via Boto3

Now let's deploy this function using Boto3:

```python
import boto3
import zipfile
import io

lambda_client = boto3.client('lambda')

def create_lambda_function(function_name, role_arn, handler='lambda_function.lambda_handler'):
    """Create a Lambda function from code."""
    
    # Create a zip file in memory
    zip_buffer = io.BytesIO()
    
    with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zip_file:
        # Add your Python file
        zip_file.writestr('lambda_function.py', '''
import os
import json

def lambda_handler(event, context):
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Hello from Lambda!',
            'function_name': context.function_name,
            'remaining_time_ms': context.get_remaining_time_in_millis()
        })
    }
''')
    
    zip_buffer.seek(0)
    
    # Create the function
    try:
        response = lambda_client.create_function(
            FunctionName=function_name,
            Runtime='python3.11',
            Role=role_arn,  # IAM role with Lambda execution permissions
            Handler=handler,
            Code={'ZipFile': zip_buffer.read()},
            Description='My first Lambda function',
            Timeout=30,  # seconds
            MemorySize=128,  # MB
            Environment={
                'Variables': {
                    'ENVIRONMENT': 'production',
                    'LOG_LEVEL': 'INFO'
                }
            }
        )
        
        function_arn = response['FunctionArn']
        print(f"✅ Created Lambda function: {function_arn}")
        return function_arn
    
    except lambda_client.exceptions.ResourceConflictException:
        print(f"Function {function_name} already exists. Updating...")
        return update_lambda_function(function_name, zip_buffer)

def update_lambda_function(function_name, zip_buffer):
    """Update an existing Lambda function."""
    
    zip_buffer.seek(0)
    
    response = lambda_client.update_function_code(
        FunctionName=function_name,
        ZipFile=zip_buffer.read()
    )
    
    print(f"✅ Updated Lambda function: {function_name}")
    return response['FunctionArn']
```

## Environment Variables

Environment variables separate configuration from code. This is essential for:
- Database connection strings
- API keys (stored in Secrets Manager, not directly)
- Feature flags
- Environment-specific settings

```python
def update_lambda_environment(function_name, env_vars):
    """Update Lambda function environment variables."""
    
    response = lambda_client.update_function_configuration(
        FunctionName=function_name,
        Environment={
            'Variables': env_vars
        }
    )
    
    print(f"✅ Updated environment variables for {function_name}")
    return response
```

### Accessing Environment Variables

In your Lambda function:

```python
import os

def lambda_handler(event, context):
    db_table = os.environ.get('DB_TABLE_NAME')
    api_key = os.environ.get('API_KEY')
    
    # Use the variables
    return {'statusCode': 200}
```

## Invoking the Function

You can invoke Lambda functions programmatically:

```python
def invoke_lambda_function(function_name, payload=None):
    """Invoke a Lambda function."""
    
    response = lambda_client.invoke(
        FunctionName=function_name,
        InvocationType='RequestResponse',  # Synchronous
        Payload=json.dumps(payload) if payload else '{}'
    )
    
    # Read the response
    result = json.loads(response['Payload'].read())
    return result

# Or invoke asynchronously
def invoke_async(function_name, payload=None):
    """Invoke Lambda function asynchronously."""
    
    response = lambda_client.invoke(
        FunctionName=function_name,
        InvocationType='Event',  # Asynchronous
        Payload=json.dumps(payload) if payload else '{}'
    )
    
    return response
```

## You Have Deployed Your First Serverless Compute Unit

Lambda is the foundation of event-driven architecture. In the next post, we'll connect Lambda to S3 events, creating a system that automatically processes files when they're uploaded.

