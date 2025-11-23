---
layout: post
title: "FinOps: The 'Garbage Collector' Script"
date: 2025-11-17 14:00:00 -0400
categories: [Cloud Management]
tags: [FinOps, CostOptimization, Python, AWS, Scripting]
excerpt: "The final skill of a Cloud Architect is not technical; it is financial. It is easy to build a system that works; it is hard to build a system that is profitable."
---

The final skill of a Cloud Architect is not technical; it is financial. It is easy to build a system that works; it is hard to build a system that is profitable. AWS bills based on provisioned capacity, not just usage. A 500GB hard drive detached from a terminated server still costs money every month. In this post, we will write a 'Janitor' script that hunts down these financial vampires—unused volumes and idle IPs—and terminates them, keeping your cloud bill lean.

## The Concept of Cloud Waste

Unused resources are both a security risk (shadow IT) and a financial drain. Common culprits:
- Detached EBS volumes
- Unassociated Elastic IPs
- Unused snapshots
- Idle load balancers

## The EBS Hunter

Let's find and clean up detached EBS volumes:

```python
import boto3
from datetime import datetime, timedelta

ec2 = boto3.client('ec2')

def find_unused_volumes():
    """Find EBS volumes that are available (detached)."""
    
    response = ec2.describe_volumes(
        Filters=[
            {'Name': 'status', 'Values': ['available']}
        ]
    )
    
    unused_volumes = []
    
    for volume in response['Volumes']:
        volume_id = volume['VolumeId']
        size_gb = volume['Size']
        created = volume['CreateTime']
        
        # Check if volume has a "Keep" tag
        tags = {tag['Key']: tag['Value'] for tag in volume.get('Tags', [])}
        
        if tags.get('Keep') == 'True':
            print(f"⏭️  Skipping {volume_id} (tagged to keep)")
            continue
        
        # Calculate age
        age_days = (datetime.now(created.tzinfo) - created).days
        
        unused_volumes.append({
            'VolumeId': volume_id,
            'Size': size_gb,
            'AgeDays': age_days,
            'Created': created
        })
    
    return unused_volumes

def delete_unused_volumes(dry_run=True, min_age_days=7):
    """Delete unused EBS volumes."""
    
    volumes = find_unused_volumes()
    deleted = []
    errors = []
    
    for volume in volumes:
        if volume['AgeDays'] < min_age_days:
            print(f"⏭️  Skipping {volume['VolumeId']} (only {volume['AgeDays']} days old)")
            continue
        
        if dry_run:
            print(f"[DRY RUN] Would delete: {volume['VolumeId']} ({volume['Size']}GB, {volume['AgeDays']} days old)")
        else:
            try:
                ec2.delete_volume(VolumeId=volume['VolumeId'])
                deleted.append(volume['VolumeId'])
                print(f"✅ Deleted volume: {volume['VolumeId']}")
            except Exception as e:
                errors.append({'volume_id': volume['VolumeId'], 'error': str(e)})
                print(f"❌ Error deleting {volume['VolumeId']}: {e}")
    
    return deleted, errors
```

## The Elastic IP Releaser

Unassociated Elastic IPs cost money:

```python
def find_unassociated_eips():
    """Find Elastic IPs that aren't associated with any instance."""
    
    response = ec2.describe_addresses()
    
    unassociated = []
    
    for address in response['Addresses']:
        if 'AssociationId' not in address:
            unassociated.append({
                'AllocationId': address['AllocationId'],
                'PublicIp': address['PublicIp']
            })
    
    return unassociated

def release_unassociated_eips(dry_run=True):
    """Release unassociated Elastic IPs."""
    
    eips = find_unassociated_eips()
    released = []
    
    for eip in eips:
        if dry_run:
            print(f"[DRY RUN] Would release: {eip['PublicIp']}")
        else:
            try:
                ec2.release_address(AllocationId=eip['AllocationId'])
                released.append(eip['PublicIp'])
                print(f"✅ Released EIP: {eip['PublicIp']}")
            except Exception as e:
                print(f"❌ Error releasing {eip['PublicIp']}: {e}")
    
    return released
```

## Complete Garbage Collection Script

Here's a complete script that cleans up multiple resource types:

```python
def garbage_collect(dry_run=True):
    """Complete garbage collection across resource types."""
    
    print("🧹 Starting garbage collection...")
    
    # EBS Volumes
    print("\n📦 Checking EBS volumes...")
    deleted_volumes, volume_errors = delete_unused_volumes(dry_run=dry_run)
    
    # Elastic IPs
    print("\n🌐 Checking Elastic IPs...")
    released_eips = release_unassociated_eips(dry_run=dry_run)
    
    # Snapshots (optional - be careful!)
    # print("\n📸 Checking old snapshots...")
    # deleted_snapshots = delete_old_snapshots(dry_run=dry_run, days=90)
    
    # Summary
    print("\n📊 Summary:")
    print(f"   Deleted volumes: {len(deleted_volumes)}")
    print(f"   Released EIPs: {len(released_eips)}")
    
    if volume_errors:
        print(f"   Errors: {len(volume_errors)}")
    
    return {
        'volumes_deleted': len(deleted_volumes),
        'eips_released': len(released_eips)
    }
```

## Automation: Scheduled Cleanup

Run this as a scheduled Lambda to clean up Dev environments:

```python
def lambda_handler(event, context):
    """Scheduled garbage collection."""
    
    # Only run in non-production
    environment = os.environ.get('ENVIRONMENT', 'dev')
    
    if environment == 'production':
        print("⏭️  Skipping garbage collection in production")
        return {'statusCode': 200}
    
    # Run cleanup (dry_run=False for actual deletion)
    result = garbage_collect(dry_run=False)
    
    # Send summary email
    send_cleanup_report(result)
    
    return {'statusCode': 200}
```

## Saving Money While Sleeping

This script can save hundreds of dollars per month by cleaning up forgotten resources. Schedule it to run weekly on Friday nights to keep your Dev environment clean without manual intervention.

In the next post, we'll explore containers, moving from Lambda to Docker and ECR.

