---
layout: post
title: "Automating Governance: The IAM Auditor Script"
date: 2025-11-20 10:00:00 -0400
categories: [Cloud Security]
tags: [IAM, SecurityAudit, PythonAutomation, CyberSecurity, Compliance]
excerpt: "In the cloud, identity is the new perimeter. A single forgotten access key, generated for a contractor three years ago, can lead to a total account compromise."
---

In the cloud, identity is the new perimeter. Firewalls matter, but they cannot stop an attacker who has logged in with valid credentials. A single forgotten access key, generated for a contractor three years ago, can lead to a total account compromise. While AWS Trusted Advisor provides some checks, true governance requires custom automation. Today, we are going to build a 'Security Watchdog'—a Python script that proactively audits your AWS account. We will learn how to traverse the IAM hierarchy, calculate the age of credentials relative to UTC time, and flag security risks before they become breaches. This is your entry into DevSecOps: using code to enforce safety.

## The Risk of Dormant Accounts

Stale credentials are a leading vector for compromise. An access key that hasn't been used in 6 months is likely forgotten. If it's compromised, the owner won't notice because they're not using it. The CIS Benchmark requires 90-day key rotation, but many organizations don't enforce this consistently.

## The Audit Logic: Algorithm Design

Our script needs to:
1. List all IAM users
2. For each user, list their access keys
3. Calculate the age of each key
4. Flag keys older than 90 days
5. Report violations

### Defining "Stale"

We'll define stale as any access key older than 90 days. This aligns with compliance requirements and security best practices.

## Handling Time in Python: The UTC Problem

This is where many developers trip up. AWS returns timestamps in UTC, but your local machine might be in a different timezone. If you compare a UTC timestamp to a local time, you'll get incorrect results.

### The Solution: Always Use UTC

```python
from datetime import datetime, timezone

# Get current time in UTC
now = datetime.now(timezone.utc)

# AWS returns timestamps like this: '2024-01-15T10:30:00Z'
# Parse it correctly
key_created = datetime.fromisoformat(aws_timestamp.replace('Z', '+00:00'))

# Calculate age
age_days = (now - key_created).days
```

The key is using `timezone.utc` and parsing AWS timestamps correctly. The 'Z' suffix means UTC, so we replace it with '+00:00' for Python's `fromisoformat` to parse it correctly.

## Building the Watchdog Script

Here's a complete IAM audit script:

```python
import boto3
import csv
from datetime import datetime, timezone
from botocore.exceptions import ClientError

def audit_iam_keys(max_age_days=90):
    """Audit IAM access keys and flag stale credentials."""
    
    iam = boto3.client('iam')
    violations = []
    
    # Get all users
    paginator = iam.get_paginator('list_users')
    
    for page in paginator.paginate():
        for user in page['Users']:
            username = user['UserName']
            
            # Skip root account
            if username == 'root':
                continue
            
            # List access keys for this user
            try:
                response = iam.list_access_keys(UserName=username)
                
                for key_metadata in response['AccessKeyMetadata']:
                    key_id = key_metadata['AccessKeyId']
                    status = key_metadata['Status']
                    created_date = key_metadata['CreateDate']
                    
                    # Parse the timestamp (AWS returns timezone-aware datetime)
                    if isinstance(created_date, str):
                        created_date = datetime.fromisoformat(
                            created_date.replace('Z', '+00:00')
                        )
                    
                    # Calculate age
                    now = datetime.now(timezone.utc)
                    age_days = (now - created_date).days
                    
                    # Check if stale
                    if age_days > max_age_days:
                        violations.append({
                            'User': username,
                            'AccessKeyId': key_id,
                            'Status': status,
                            'Age (Days)': age_days,
                            'Created': created_date.strftime('%Y-%m-%d'),
                            'Risk': 'HIGH' if age_days > 180 else 'MEDIUM'
                        })
            
            except ClientError as e:
                print(f"Error processing user {username}: {e}")
                continue
    
    return violations

def generate_report(violations, filename='iam_audit_report.csv'):
    """Generate a CSV report of violations."""
    
    if not violations:
        print("✅ No stale access keys found!")
        return
    
    with open(filename, 'w', newline='') as csvfile:
        fieldnames = ['User', 'AccessKeyId', 'Status', 'Age (Days)', 'Created', 'Risk']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        
        writer.writeheader()
        for violation in violations:
            writer.writerow(violation)
    
    print(f"⚠️  Found {len(violations)} stale access keys. Report saved to {filename}")

if __name__ == '__main__':
    violations = audit_iam_keys(max_age_days=90)
    generate_report(violations)
```

## Advanced Remediation: Automatic Disabling

**Warning:** This is a destructive operation. Only use this in well-tested environments.

```python
def disable_stale_keys(violations, dry_run=True):
    """Disable access keys that exceed the age threshold."""
    
    iam = boto3.client('iam')
    
    for violation in violations:
        if violation['Risk'] == 'HIGH':
            if dry_run:
                print(f"[DRY RUN] Would disable key {violation['AccessKeyId']} for user {violation['User']}")
            else:
                try:
                    iam.update_access_key(
                        UserName=violation['User'],
                        AccessKeyId=violation['AccessKeyId'],
                        Status='Inactive'
                    )
                    print(f"✅ Disabled key {violation['AccessKeyId']} for user {violation['User']}")
                except ClientError as e:
                    print(f"❌ Error disabling key: {e}")
```

**Important:** Never delete keys immediately. Always disable them first (`Status='Inactive'`) to allow for rollback if something goes wrong.

## Integration with Slack

For production use, you'll want to send alerts:

```python
import requests
import json

def send_slack_alert(violations, webhook_url):
    """Send audit results to Slack."""
    
    message = {
        "text": f"🚨 IAM Audit Alert: {len(violations)} stale access keys found",
        "attachments": [
            {
                "color": "danger",
                "fields": [
                    {
                        "title": "User",
                        "value": v['User'],
                        "short": True
                    },
                    {
                        "title": "Age",
                        "value": f"{v['Age (Days)']} days",
                        "short": True
                    }
                ]
            }
            for v in violations[:10]  # Limit to first 10
        ]
    }
    
    requests.post(webhook_url, json=message)
```

## Moving from Passive to Active

You've just built a tool that moves from passive observation to active enforcement. This script can be:
- Scheduled to run daily via Lambda
- Integrated into your CI/CD pipeline
- Extended to check for other IAM issues (unused users, overly permissive policies)

The foundation is set. In the next post, we'll move from identity to infrastructure, learning how to build VPCs programmatically.

