---
layout: post
title: "Identity Hygiene: Rotating IAM Keys with Lambda"
date: 2025-12-11 10:00:00 -0400
categories: [Identity Management]
tags: [IAM, KeyRotation, Python, Lambda, SecurityBestPractices]
excerpt: "Static access keys are a ticking time bomb. The longer they exist, the higher the probability they will be leaked."
---

Static access keys are a ticking time bomb. The longer they exist, the higher the probability they will be leaked. Best practice dictates rotating them every 90 days, but doing this manually for 50 users is a full-time job. In this post, we will automate the lifecycle of identity. We will build a Lambda function that checks key age daily, warns users via email when they approach expiration, and automatically rotates and secures new credentials in AWS Secrets Manager when the deadline hits.

## The Risk of Static Credentials

Compliance standards (PCI-DSS, HIPAA, SOC 2) require credential rotation. Manual rotation is error-prone and often forgotten. Automation ensures consistency and reduces risk.

## The Rotation Logic

Our function will:
1. Check key age daily (CloudWatch Event trigger)
2. Warn users at 80 days
3. Rotate keys at 90 days
4. Store new keys in Secrets Manager

```python
import boto3
from datetime import datetime, timezone, timedelta
import json

iam = boto3.client('iam')
secrets_manager = boto3.client('secretsmanager')
ses = boto3.client('ses')

def lambda_handler(event, context):
    """Daily IAM key rotation check."""
    
    # Check all users
    paginator = iam.get_paginator('list_users')
    
    for page in paginator.paginate():
        for user in page['Users']:
            username = user['UserName']
            
            # Skip root
            if username == 'root':
                continue
            
            # Check user's access keys
            check_and_rotate_keys(username)
    
    return {'statusCode': 200}

def check_and_rotate_keys(username):
    """Check key age and rotate if needed."""
    
    try:
        response = iam.list_access_keys(UserName=username)
        
        for key_metadata in response['AccessKeyMetadata']:
            key_id = key_metadata['AccessKeyId']
            status = key_metadata['Status']
            created_date = key_metadata['CreateDate']
            
            # Calculate age
            now = datetime.now(timezone.utc)
            if isinstance(created_date, str):
                created_date = datetime.fromisoformat(created_date.replace('Z', '+00:00'))
            
            age_days = (now - created_date).days
            
            # Warn at 80 days
            if age_days >= 80 and age_days < 90:
                send_rotation_warning(username, key_id, age_days)
            
            # Rotate at 90 days
            elif age_days >= 90:
                rotate_access_key(username, key_id)
    
    except Exception as e:
        print(f"❌ Error processing user {username}: {e}")

def send_rotation_warning(username, key_id, age_days):
    """Send email warning about key expiration."""
    
    # Get user's email (if tagged)
    try:
        user_tags = iam.list_user_tags(UserName=username)['Tags']
        email = next((tag['Value'] for tag in user_tags if tag['Key'] == 'Email'), None)
        
        if not email:
            print(f"No email found for user {username}")
            return
        
        # Send warning email
        ses.send_email(
            Source='security@example.com',
            Destination={'ToAddresses': [email]},
            Message={
                'Subject': {'Data': f'Access Key Rotation Required - {username}'},
                'Body': {
                    'Text': {
                        'Data': f"""
Your AWS access key {key_id} is {age_days} days old and will be automatically rotated in {90 - age_days} days.

Please prepare to update any applications using this key.
                        """
                    }
                }
            }
        )
        
        print(f"✅ Sent rotation warning to {username}")
    
    except Exception as e:
        print(f"❌ Error sending warning: {e}")

def rotate_access_key(username, key_id):
    """Rotate an access key."""
    
    try:
        # Create new key
        new_key_response = iam.create_access_key(UserName=username)
        new_key_id = new_key_response['AccessKey']['AccessKeyId']
        new_secret = new_key_response['AccessKey']['SecretAccessKey']
        
        # Disable old key (don't delete immediately)
        iam.update_access_key(
            UserName=username,
            AccessKeyId=key_id,
            Status='Inactive'
        )
        
        # Store new key in Secrets Manager
        secret_name = f"iam-key-{username}-{new_key_id}"
        secrets_manager.create_secret(
            Name=secret_name,
            SecretString=json.dumps({
                'AccessKeyId': new_key_id,
                'SecretAccessKey': new_secret,
                'UserName': username,
                'RotatedAt': datetime.now(timezone.utc).isoformat()
            }),
            Description=f'Rotated access key for {username}'
        )
        
        # Notify user
        notify_key_rotated(username, new_key_id, secret_name)
        
        print(f"✅ Rotated key for {username}")
        
        # Delete old key after 7 days (separate cleanup job)
        # This allows rollback if needed
    
    except Exception as e:
        print(f"❌ Error rotating key: {e}")

def notify_key_rotated(username, new_key_id, secret_name):
    """Notify user that key was rotated."""
    
    try:
        user_tags = iam.list_user_tags(UserName=username)['Tags']
        email = next((tag['Value'] for tag in user_tags if tag['Key'] == 'Email'), None)
        
        if email:
            ses.send_email(
                Source='security@example.com',
                Destination={'ToAddresses': [email]},
                Message={
                    'Subject': {'Data': f'Access Key Rotated - {username}'},
                    'Body': {
                        'Text': {
                            'Data': f"""
Your AWS access key has been automatically rotated.

New Key ID: {new_key_id}
Secret stored in: {secret_name}

The old key has been disabled. Please update your applications.
                            """
                        }
                    }
                }
            )
    except Exception as e:
        print(f"❌ Error sending notification: {e}")
```

## Zero-Touch Credential Management

You've automated the entire credential lifecycle:
- Daily monitoring
- Proactive warnings
- Automatic rotation
- Secure storage

This ensures compliance and reduces the risk of credential compromise. In the next post, we'll tackle FinOps with a garbage collection script.

