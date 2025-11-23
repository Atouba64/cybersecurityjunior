---
layout: post
title: "Automated Defense: GuardDuty & IPS Blocking"
date: 2025-11-18 14:00:00 -0400
categories: [Cloud Security]
tags: [GuardDuty, SecurityAutomation, Python, IncidentResponse, NACL]
excerpt: "In a modern cyber-security landscape, human reaction time is too slow. If an attacker is enumerating your bucket, you cannot wait for an email alert to wake you up."
---

In a modern cyber-security landscape, human reaction time is too slow. If an attacker is enumerating your bucket, you cannot wait for an email alert to wake you up. You need a system that fights back. In this post, we will turn Amazon GuardDuty from a passive log generator into an active defense system. We will write a Python Lambda function that listens for 'High Severity' alerts and automatically updates your Network Access Control Lists (NACLs) to ban the attacking IP address. This is the pinnacle of the 'Security as Code' philosophy.

## The Limitation of Human Response Time

Detection without response is just expensive logging. GuardDuty can detect threats, but if you're manually reviewing alerts, the attacker has already moved on. Automation closes the response gap from hours to seconds.

## GuardDuty vs. Security Hub vs. Inspector

Before we build, let's understand the AWS security services:

- **GuardDuty**: Threat detection using ML and threat intelligence
- **Security Hub**: Centralized security findings aggregation
- **Inspector**: Vulnerability scanning for EC2 and containers

GuardDuty is our focus because it detects active threats in real-time.

## The Event Loop

GuardDuty findings are published to EventBridge. We'll create a rule that triggers our Lambda function:

```python
import boto3
import json

eventbridge = boto3.client('events')
lambda_client = boto3.client('lambda')

def create_guardduty_rule(function_name):
    """Create EventBridge rule for GuardDuty findings."""
    
    function_arn = lambda_client.get_function(FunctionName=function_name)['Configuration']['FunctionArn']
    
    # Create rule
    rule_response = eventbridge.put_rule(
        Name='guardduty-high-severity',
        EventPattern=json.dumps({
            'source': ['aws.guardduty'],
            'detail-type': ['GuardDuty Finding'],
            'detail': {
                'severity': {
                    'numeric': [{'numeric': ['>', 7.0]}]  # High severity
                }
            }
        }),
        State='ENABLED'
    )
    
    rule_arn = rule_response['RuleArn']
    
    # Add Lambda as target
    eventbridge.put_targets(
        Rule='guardduty-high-severity',
        Targets=[
            {
                'Id': '1',
                'Arn': function_arn
            }
        ]
    )
    
    # Grant EventBridge permission to invoke Lambda
    lambda_client.add_permission(
        FunctionName=function_name,
        StatementId='AllowEventBridge',
        Action='lambda:InvokeFunction',
        Principal='events.amazonaws.com',
        SourceArn=rule_arn
    )
    
    print(f"✅ Created GuardDuty event rule")
```

## The Remediation Code

Now let's build the Lambda function that blocks attacking IPs:

```python
import boto3
import json
from ipaddress import ip_address, IPv4Address

ec2 = boto3.client('ec2')

def lambda_handler(event, context):
    """Automatically block IPs from GuardDuty findings."""
    
    finding = event['detail']
    
    # Extract the attacking IP
    service = finding.get('service', {})
    action = service.get('action', {})
    network_connection = action.get('networkConnectionAction', {})
    
    remote_ip = network_connection.get('remoteIpDetails', {}).get('ipAddressV4')
    
    if not remote_ip:
        print("No IP address found in finding")
        return {'statusCode': 200}
    
    # Validate it's an IPv4 address
    try:
        ip_address(remote_ip)
    except ValueError:
        print(f"Invalid IP address: {remote_ip}")
        return {'statusCode': 200}
    
    # Get finding details
    finding_id = finding['id']
    severity = finding.get('severity', 0)
    finding_type = finding.get('type', 'Unknown')
    
    print(f"🚨 GuardDuty Finding: {finding_type}")
    print(f"   Severity: {severity}")
    print(f"   Attacking IP: {remote_ip}")
    
    # Block the IP
    if severity > 7.0:  # High severity
        block_ip_in_nacl(remote_ip, finding_id)
    
    return {'statusCode': 200}

def block_ip_in_nacl(ip_address, reason):
    """Block an IP address using Network ACL."""
    
    # Get all VPCs
    vpcs = ec2.describe_vpcs()['Vpcs']
    
    for vpc in vpcs:
        vpc_id = vpc['VpcId']
        
        # Get default NACL for the VPC
        nacls = ec2.describe_network_acls(
            Filters=[
                {'Name': 'vpc-id', 'Values': [vpc_id]},
                {'Name': 'default', 'Values': ['true']}
            ]
        )['NetworkAcls']
        
        if not nacls:
            continue
        
        nacl_id = nacls[0]['NetworkAclId']
        
        # Find the highest rule number
        existing_rules = nacls[0].get('Entries', [])
        rule_numbers = [rule['RuleNumber'] for rule in existing_rules if not rule.get('Egress')]
        max_rule = max(rule_numbers) if rule_numbers else 0
        
        # Create deny rule (lower number = higher priority)
        new_rule_number = max_rule + 1
        
        try:
            ec2.create_network_acl_entry(
                NetworkAclId=nacl_id,
                RuleNumber=new_rule_number,
                Protocol='-1',  # All protocols
                RuleAction='deny',
                CidrBlock=f"{ip_address}/32",
                Egress=False
            )
            
            print(f"✅ Blocked {ip_address} in VPC {vpc_id} (Rule #{new_rule_number})")
        
        except ec2.exceptions.ClientError as e:
            if 'already exists' in str(e).lower():
                print(f"⏭️  IP {ip_address} already blocked")
            else:
                print(f"❌ Error blocking IP: {e}")
```

## Testing the Defense

Let's create a test script to verify our defense works:

```python
def test_guardduty_response():
    """Simulate a GuardDuty finding to test the response."""
    
    test_event = {
        'version': '0',
        'id': 'test-event-id',
        'detail-type': 'GuardDuty Finding',
        'source': 'aws.guardduty',
        'detail': {
            'id': 'test-finding-123',
            'type': 'Recon:EC2/PortProbeUnprotectedPort',
            'severity': 8.5,
            'service': {
                'action': {
                    'networkConnectionAction': {
                        'remoteIpDetails': {
                            'ipAddressV4': '192.0.2.1'  # Test IP
                        }
                    }
                }
            }
        }
    }
    
    # Invoke the Lambda function
    lambda_client = boto3.client('lambda')
    response = lambda_client.invoke(
        FunctionName='guardduty-auto-block',
        InvocationType='RequestResponse',
        Payload=json.dumps(test_event)
    )
    
    result = json.loads(response['Payload'].read())
    print(f"Test result: {result}")
```

## Active Defense Implementation

You've built a system that:
- Detects threats automatically (GuardDuty)
- Responds instantly (Lambda)
- Blocks attackers (NACL updates)

This is active defense—your infrastructure fights back automatically. In the next post, we'll automate vulnerability management with Amazon Inspector.

