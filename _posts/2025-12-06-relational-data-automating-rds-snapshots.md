---
layout: post
title: "Relational Data: Automating RDS Snapshots"
date: 2025-12-06 10:00:00 -0400
categories: [Database]
tags: [RDS, PostgreSQL, Database, Python, DisasterRecovery]
excerpt: "Databases are the crown jewels of any organization. While AWS provides automated backup windows, there are critical moments when you need an immediate, manual snapshot."
---

Databases are the crown jewels of any organization. While AWS provides automated backup windows, there are critical moments—before a major schema migration or deployment—when you need an immediate, manual snapshot. More importantly, you need to know how to restore it. A backup that hasn't been tested is just a hope. In this post, we will build a 'Time Machine' for our RDS instance. We will write Python code that triggers a snapshot, waits for completion, and then spins up a brand new database instance from that point in time to verify data integrity.

## The Importance of Testing Backups

Schrödinger's Backup: A backup exists and doesn't exist until you restore it. Many organizations discover their backups are corrupted only when they need them. Regular restoration testing is essential.

## Snapshot Management

Let's start by creating and managing snapshots:

```python
import boto3
from datetime import datetime

rds = boto3.client('rds')

def create_db_snapshot(db_instance_identifier, snapshot_identifier=None):
    """Create a manual RDS snapshot."""
    
    if not snapshot_identifier:
        timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
        snapshot_identifier = f"{db_instance_identifier}-manual-{timestamp}"
    
    response = rds.create_db_snapshot(
        DBSnapshotIdentifier=snapshot_identifier,
        DBInstanceIdentifier=db_instance_identifier
    )
    
    snapshot_arn = response['DBSnapshot']['DBSnapshotArn']
    print(f"✅ Created snapshot: {snapshot_identifier}")
    
    # Wait for completion
    waiter = rds.get_waiter('db_snapshot_completed')
    waiter.wait(DBSnapshotIdentifier=snapshot_identifier)
    
    print(f"✅ Snapshot completed: {snapshot_identifier}")
    return snapshot_identifier

def tag_snapshot(snapshot_identifier, tags):
    """Tag a snapshot for retention policies."""
    
    tag_list = [{'Key': k, 'Value': v} for k, v in tags.items()]
    
    rds.add_tags_to_resource(
        ResourceName=f"arn:aws:rds:us-east-1:123456789012:snapshot:{snapshot_identifier}",
        Tags=tag_list
    )
    
    print(f"✅ Tagged snapshot: {snapshot_identifier}")

def list_snapshots(db_instance_identifier=None):
    """List all snapshots, optionally filtered by instance."""
    
    if db_instance_identifier:
        response = rds.describe_db_snapshots(
            DBInstanceIdentifier=db_instance_identifier
        )
    else:
        response = rds.describe_db_snapshots()
    
    snapshots = []
    for snapshot in response['DBSnapshots']:
        snapshots.append({
            'SnapshotIdentifier': snapshot['DBSnapshotIdentifier'],
            'Status': snapshot['Status'],
            'SnapshotCreateTime': snapshot['SnapshotCreateTime'],
            'AllocatedStorage': snapshot['AllocatedStorage']
        })
    
    return snapshots
```

## The Restore Workflow

Now let's restore a snapshot to verify it works:

```python
def restore_from_snapshot(snapshot_identifier, new_instance_identifier, instance_class='db.t3.micro'):
    """Restore a database instance from a snapshot."""
    
    # Get snapshot details
    snapshot = rds.describe_db_snapshots(
        DBSnapshotIdentifier=snapshot_identifier
    )['DBSnapshots'][0]
    
    # Restore the instance
    response = rds.restore_db_instance_from_db_snapshot(
        DBInstanceIdentifier=new_instance_identifier,
        DBSnapshotIdentifier=snapshot_identifier,
        DBInstanceClass=instance_class,
        PubliclyAccessible=False,
        MultiAZ=False,
        AutoMinorVersionUpgrade=True
    )
    
    instance_arn = response['DBInstance']['DBInstanceArn']
    print(f"✅ Restoring instance: {new_instance_identifier}")
    
    # Wait for availability
    waiter = rds.get_waiter('db_instance_available')
    waiter.wait(DBInstanceIdentifier=new_instance_identifier)
    
    # Get endpoint
    instance = rds.describe_db_instances(
        DBInstanceIdentifier=new_instance_identifier
    )['DBInstances'][0]
    
    endpoint = instance['Endpoint']['Address']
    port = instance['Endpoint']['Port']
    
    print(f"✅ Instance restored. Endpoint: {endpoint}:{port}")
    return endpoint, port
```

### Why This Is Useful

Restoring snapshots is useful for:
- **Staging environments**: Test migrations on real data
- **Disaster recovery drills**: Verify your backup process works
- **Data analysis**: Create temporary databases for reporting

## Loading Data: Migration Patterns

Once you have a database, you'll need to load data. Here's how to do it efficiently:

```python
import psycopg2
import csv
from io import StringIO

def connect_to_rds(endpoint, port, database, username, password):
    """Connect to an RDS PostgreSQL instance."""
    
    conn = psycopg2.connect(
        host=endpoint,
        port=port,
        database=database,
        user=username,
        password=password
    )
    
    return conn

def bulk_load_csv(conn, table_name, csv_file_path):
    """Efficiently load CSV data into PostgreSQL."""
    
    cursor = conn.cursor()
    
    with open(csv_file_path, 'r') as f:
        # Skip header
        next(f)
        
        # Use copy_from for bulk loading (much faster than INSERT)
        cursor.copy_from(
            f,
            table_name,
            sep=',',
            null=''
        )
    
    conn.commit()
    cursor.close()
    print(f"✅ Loaded data into {table_name}")

def load_from_s3_to_rds(s3_bucket, s3_key, rds_endpoint, table_name):
    """Load CSV from S3 into RDS."""
    
    s3 = boto3.client('s3')
    
    # Download from S3
    response = s3.get_object(Bucket=s3_bucket, Key=s3_key)
    csv_content = response['Body'].read().decode('utf-8')
    
    # Connect to RDS
    conn = connect_to_rds(rds_endpoint, 5432, 'mydb', 'admin', 'password')
    cursor = conn.cursor()
    
    # Use copy_expert for in-memory data
    cursor.copy_expert(
        f"COPY {table_name} FROM STDIN WITH CSV HEADER",
        StringIO(csv_content)
    )
    
    conn.commit()
    cursor.close()
    conn.close()
    
    print(f"✅ Loaded {s3_key} into {table_name}")
```

### Performance: copy_from vs. INSERT

For bulk loading, `copy_from` is 10-100x faster than INSERT loops:
- **INSERT loop**: ~1000 rows/second
- **copy_from**: ~100,000 rows/second

## Automated Snapshot Before Deployment

Here's a complete workflow that creates a snapshot before a deployment:

```python
def pre_deployment_snapshot(db_instance_identifier):
    """Create a snapshot before deployment."""
    
    timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
    snapshot_id = f"{db_instance_identifier}-pre-deploy-{timestamp}"
    
    # Create snapshot
    create_db_snapshot(db_instance_identifier, snapshot_id)
    
    # Tag it
    tag_snapshot(snapshot_id, {
        'Purpose': 'PreDeployment',
        'Retention': '30Days',
        'CreatedBy': 'Automation'
    })
    
    return snapshot_id

def verify_snapshot(snapshot_identifier):
    """Restore snapshot to verify it works."""
    
    test_instance_id = f"test-{snapshot_identifier}"
    
    try:
        endpoint, port = restore_from_snapshot(
            snapshot_identifier,
            test_instance_id
        )
        
        # Verify connection
        conn = connect_to_rds(endpoint, port, 'mydb', 'admin', 'password')
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM users")
        count = cursor.fetchone()[0]
        cursor.close()
        conn.close()
        
        print(f"✅ Snapshot verified. Record count: {count}")
        
        # Clean up test instance
        rds.delete_db_instance(
            DBInstanceIdentifier=test_instance_id,
            SkipFinalSnapshot=True
        )
        
        return True
    
    except Exception as e:
        print(f"❌ Snapshot verification failed: {e}")
        return False
```

## Verified Recoverability

You now have a system that:
1. Creates snapshots before critical operations
2. Tags them for retention policies
3. Verifies they can be restored
4. Loads data efficiently

This is the foundation of reliable database operations. In the next post, we'll explore NoSQL with DynamoDB, learning how to handle high-scale writes.

