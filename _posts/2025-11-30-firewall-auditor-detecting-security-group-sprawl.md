---
layout: post
title: "The Firewall Auditor: Detecting Security Group Sprawl"
date: 2025-11-22 10:00:00 -0400
categories: [Network Security]
tags: [NetworkSecurity, Python, AWS, Audit, FinOps]
excerpt: "One of the most common findings in a cloud security audit is 'Security Group Sprawl.' Developers create a group for a quick test, open port 22 to the world, detach it, and then forget it exists."
---

One of the most common findings in a cloud security audit is 'Security Group Sprawl.' Developers create a group for a quick test, open port 22 to the world, detach it, and then forget it exists. Months later, you have hundreds of defined firewalls, and you have no idea which ones are safe to use. Today, we play the role of the digital janitor. We will write a Python script that correlates Network Interfaces (ENIs) with Security Groups to identify exactly which groups are orphans. We will also add a compliance check to scan for rules that allow the entire internet to access your administrative ports.

## The Risk of Unused Groups

Unused security groups are a latent security risk. They often contain permissive rules (like 0.0.0.0/0 for SSH) that are forgotten until they're accidentally re-attached to a production instance. In a breach scenario, an attacker might enumerate your security groups and find one with overly permissive rules that they can exploit.

## The Audit Algorithm

Our script needs to:
1. List all Security Groups
2. List all Network Interfaces to see what's actually attached
3. Use set theory to find unused groups: All_SGs - Attached_SGs = Unused_SGs
4. Scan for dangerous rules

### Step 1: List All Security Groups

```python
import boto3
from collections import defaultdict

ec2 = boto3.client('ec2')

def get_all_security_groups():
    """Get all security groups in the account."""
    paginator = ec2.get_paginator('describe_security_groups')
    
    all_sgs = set()
    for page in paginator.paginate():
        for sg in page['SecurityGroups']:
            all_sgs.add(sg['GroupId'])
    
    return all_sgs
```

### Step 2: Find Attached Security Groups

```python
def get_attached_security_groups():
    """Get security groups that are actually in use."""
    paginator = ec2.get_paginator('describe_network_interfaces')
    
    attached_sgs = set()
    for page in paginator.paginate():
        for eni in page['NetworkInterfaces']:
            # Each ENI can have multiple security groups
            for sg in eni.get('Groups', []):
                attached_sgs.add(sg['GroupId'])
    
    return attached_sgs
```

### Step 3: Calculate Unused Groups

```python
def find_unused_security_groups():
    """Find security groups that aren't attached to any ENI."""
    all_sgs = get_all_security_groups()
    attached_sgs = get_attached_security_groups()
    
    # Set difference: groups that exist but aren't attached
    unused_sgs = all_sgs - attached_sgs
    
    return unused_sgs, all_sgs, attached_sgs
```

## Dangerous Rule Detection

Now let's scan for security group rules that are too permissive:

```python
def scan_dangerous_rules():
    """Scan for overly permissive security group rules."""
    
    dangerous_ports = {
        22: 'SSH',
        3389: 'RDP',
        3306: 'MySQL',
        5432: 'PostgreSQL',
        1433: 'SQL Server'
    }
    
    violations = []
    
    paginator = ec2.get_paginator('describe_security_groups')
    for page in paginator.paginate():
        for sg in page['SecurityGroups']:
            sg_id = sg['GroupId']
            sg_name = sg['GroupName']
            
            # Check inbound rules
            for rule in sg.get('IpPermissions', []):
                port = rule.get('FromPort')
                
                if port in dangerous_ports:
                    # Check if rule allows 0.0.0.0/0 (entire internet)
                    for ip_range in rule.get('IpRanges', []):
                        if ip_range.get('CidrIp') == '0.0.0.0/0':
                            violations.append({
                                'SecurityGroupId': sg_id,
                                'SecurityGroupName': sg_name,
                                'Port': port,
                                'Service': dangerous_ports[port],
                                'Risk': 'CRITICAL',
                                'Rule': f"Allows {dangerous_ports[port]} from entire internet"
                            })
    
    return violations
```

## The Cleanup Script

Now let's build a script that can safely delete unused security groups:

```python
def delete_unused_security_groups(dry_run=True):
    """Delete security groups that aren't in use."""
    
    unused_sgs, all_sgs, attached_sgs = find_unused_security_groups()
    
    print(f"Total Security Groups: {len(all_sgs)}")
    print(f"Attached Security Groups: {len(attached_sgs)}")
    print(f"Unused Security Groups: {len(unused_sgs)}")
    
    deleted = []
    errors = []
    
    for sg_id in unused_sgs:
        # Get SG details for logging
        response = ec2.describe_security_groups(GroupIds=[sg_id])
        sg_name = response['SecurityGroups'][0]['GroupName']
        
        # Skip default security groups
        if sg_name.startswith('default'):
            print(f"⏭️  Skipping default security group: {sg_id}")
            continue
        
        if dry_run:
            print(f"[DRY RUN] Would delete: {sg_id} ({sg_name})")
        else:
            try:
                ec2.delete_security_group(GroupId=sg_id)
                deleted.append(sg_id)
                print(f"✅ Deleted: {sg_id} ({sg_name})")
            except ClientError as e:
                error_code = e.response['Error']['Code']
                if error_code == 'DependencyViolation':
                    errors.append({
                        'sg_id': sg_id,
                        'error': 'Still has dependencies (may be attached to ENI or other SG)'
                    })
                else:
                    errors.append({
                        'sg_id': sg_id,
                        'error': str(e)
                    })
    
    return deleted, errors
```

### Handling DependencyViolation Errors

Security groups can't be deleted if they:
- Are referenced by another security group's rules
- Are attached to a network interface (even if detached, there's a delay)
- Are the default security group for a VPC

The script handles these gracefully by catching the `DependencyViolation` error.

## Complete Audit Script

Here's the complete script that combines everything:

```python
import boto3
import csv
from botocore.exceptions import ClientError

def security_group_audit():
    """Complete security group audit and cleanup."""
    
    # Find unused groups
    unused_sgs, all_sgs, attached_sgs = find_unused_security_groups()
    
    # Find dangerous rules
    dangerous_rules = scan_dangerous_rules()
    
    # Generate report
    with open('sg_audit_report.csv', 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['Type', 'SecurityGroupId', 'SecurityGroupName', 'Details'])
        
        # Write unused groups
        for sg_id in unused_sgs:
            response = ec2.describe_security_groups(GroupIds=[sg_id])
            sg_name = response['SecurityGroups'][0]['GroupName']
            writer.writerow(['UNUSED', sg_id, sg_name, 'Not attached to any ENI'])
        
        # Write dangerous rules
        for violation in dangerous_rules:
            writer.writerow([
                'DANGEROUS_RULE',
                violation['SecurityGroupId'],
                violation['SecurityGroupName'],
                violation['Rule']
            ])
    
    print(f"\n📊 Audit Complete:")
    print(f"   Unused Groups: {len(unused_sgs)}")
    print(f"   Dangerous Rules: {len(dangerous_rules)}")
    print(f"   Report saved to: sg_audit_report.csv")
    
    return unused_sgs, dangerous_rules

if __name__ == '__main__':
    security_group_audit()
    # Uncomment to actually delete (after reviewing the report)
    # delete_unused_security_groups(dry_run=False)
```

## Automating Hygiene

This script can be scheduled to run weekly via Lambda to maintain a minimal attack surface. Regular cleanup prevents security group sprawl and reduces the risk of accidentally using overly permissive rules.

In the next post, we'll explore advanced networking patterns: VPC Peering and Transit Gateways for multi-account architectures.

