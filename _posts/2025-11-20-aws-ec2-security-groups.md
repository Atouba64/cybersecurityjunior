---
layout: post
title: "EC2 Security Groups: Your Virtual Firewall in the Cloud"
date: 2025-11-20 10:00:00 -0400
categories: [AWS, Cloud Security, Networking]
tags: [aws, ec2, security-groups, networking, firewall, cloud-security]
image: https://placehold.co/1000x400/FF9900/FFFFFF?text=EC2+Security+Groups
excerpt: "Security Groups are like bouncers at a club, but for your virtual servers. They decide what traffic is allowed in and what's blocked. Understanding them is crucial for securing your AWS infrastructure. Let's learn how they work and how to configure them properly."
---

> **Imagine this:** You've launched an EC2 instance (a virtual server) in AWS. By default, it's completely isolated - nothing can reach it, and it can't reach anything. That's actually good for security, but you probably need it to do something. Security Groups are your virtual firewall that controls exactly what traffic is allowed. Let me show you how to configure them properly.

## What are Security Groups, Really?

Think of Security Groups like this:

**Real-world analogy:** Your EC2 instance is a house. Security Groups are the security system that controls:
- Who can knock on the door (inbound traffic)
- What doors/windows are open (ports)
- Where traffic can come from (source IPs)
- Where traffic can go (outbound traffic)

**Key characteristics:**
- **Stateful** - If you allow traffic in, the response is automatically allowed out
- **Default deny** - Everything is blocked unless explicitly allowed
- **Virtual firewall** - Applied at the instance level, not the network level

## Security Groups vs Network ACLs

You might hear about Network ACLs (Access Control Lists). Here's the difference:

| Feature | Security Groups | Network ACLs |
|---------|----------------|--------------|
| Level | Instance level | Subnet level |
| Stateful | Yes (automatic return traffic) | No (stateless) |
| Rules | Allow only | Allow and Deny |
| Evaluation | All rules evaluated | Rules evaluated in order |

**For most use cases, Security Groups are what you need.** Network ACLs are for additional subnet-level security.

## Understanding Security Group Rules

Security Group rules have 4 components:

1. **Type** - The protocol (TCP, UDP, ICMP, etc.)
2. **Protocol** - Usually TCP for web traffic
3. **Port Range** - Which ports (e.g., 80 for HTTP, 443 for HTTPS)
4. **Source/Destination** - Where traffic can come from/go to

### Inbound Rules (Ingress)

Control what traffic can reach your instance:

```
Type: SSH
Protocol: TCP
Port: 22
Source: 10.0.0.0/16 (your VPC)
```

This says: "Allow SSH (port 22) traffic from IPs in the 10.0.0.0/16 range."

### Outbound Rules (Egress)

Control what traffic can leave your instance:

```
Type: HTTPS
Protocol: TCP
Port: 443
Destination: 0.0.0.0/0 (anywhere)
```

This says: "Allow HTTPS (port 443) traffic to anywhere."

**Important:** By default, outbound traffic is allowed to anywhere. You should restrict this for better security!

## Common Security Group Patterns

### Pattern 1: Web Server

A web server needs:
- HTTP (port 80) from the internet
- HTTPS (port 443) from the internet
- SSH (port 22) from your office IP only

**Inbound Rules:**
```
HTTP (80)    | TCP | 80  | 0.0.0.0/0
HTTPS (443)  | TCP | 443 | 0.0.0.0/0
SSH (22)     | TCP | 22  | YOUR_OFFICE_IP/32
```

**Outbound Rules:**
```
HTTPS (443)  | TCP | 443 | 0.0.0.0/0  (for API calls)
HTTP (80)    | TCP | 80  | 0.0.0.0/0  (for package updates)
```

### Pattern 2: Database Server

A database should NEVER be accessible from the internet:

**Inbound Rules:**
```
MySQL (3306) | TCP | 3306 | 10.0.1.0/24  (only from app servers)
SSH (22)     | TCP | 22   | 10.0.0.0/16  (only from VPC)
```

**Outbound Rules:**
```
HTTPS (443)  | TCP | 443 | 0.0.0.0/0  (for updates)
```

### Pattern 3: Compliance Scanner

Your compliance scanner needs:
- Outbound access to AWS APIs
- SSH from your management network
- No inbound access from internet

**Inbound Rules:**
```
SSH (22)     | TCP | 22  | 10.0.0.0/16  (management network)
```

**Outbound Rules:**
```
HTTPS (443)  | TCP | 443 | 0.0.0.0/0  (AWS APIs)
```

## Creating Security Groups with AWS CLI

### Create a Security Group

```bash
# Create security group
aws ec2 create-security-group \
  --group-name compliance-scanner-sg \
  --description "Security group for compliance scanner" \
  --vpc-id vpc-12345678
```

**Output:**
```json
{
  "GroupId": "sg-1234567890abcdef0"
}
```

### Add Inbound Rules

```bash
# Allow SSH from VPC
aws ec2 authorize-security-group-ingress \
  --group-id sg-1234567890abcdef0 \
  --protocol tcp \
  --port 22 \
  --cidr 10.0.0.0/16
```

### Add Outbound Rules

```bash
# Allow HTTPS outbound
aws ec2 authorize-security-group-egress \
  --group-id sg-1234567890abcdef0 \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0
```

## Creating Security Groups with Python (Boto3)

Here's how to create and configure security groups programmatically:

```python
import boto3
from botocore.exceptions import ClientError

def create_security_group(vpc_id, group_name, description):
    """Create a security group."""
    ec2_client = boto3.client('ec2')
    
    try:
        response = ec2_client.create_security_group(
            GroupName=group_name,
            Description=description,
            VpcId=vpc_id
        )
        group_id = response['GroupId']
        print(f"Created security group: {group_id}")
        return group_id
    except ClientError as e:
        if e.response['Error']['Code'] == 'InvalidGroup.Duplicate':
            # Group already exists, get its ID
            response = ec2_client.describe_security_groups(
                GroupNames=[group_name]
            )
            return response['SecurityGroups'][0]['GroupId']
        else:
            print(f"Error creating security group: {e}")
            return None

def add_inbound_rule(group_id, protocol, port, source):
    """Add an inbound rule to a security group."""
    ec2_client = boto3.client('ec2')
    
    try:
        ec2_client.authorize_security_group_ingress(
            GroupId=group_id,
            IpPermissions=[
                {
                    'IpProtocol': protocol,
                    'FromPort': port,
                    'ToPort': port,
                    'IpRanges': [
                        {
                            'CidrIp': source,
                            'Description': f'Allow {protocol} from {source}'
                        }
                    ]
                }
            ]
        )
        print(f"Added inbound rule: {protocol}:{port} from {source}")
    except ClientError as e:
        if e.response['Error']['Code'] == 'InvalidPermission.Duplicate':
            print(f"Rule already exists: {protocol}:{port} from {source}")
        else:
            print(f"Error adding rule: {e}")

def add_outbound_rule(group_id, protocol, port, destination):
    """Add an outbound rule to a security group."""
    ec2_client = boto3.client('ec2')
    
    try:
        ec2_client.authorize_security_group_egress(
            GroupId=group_id,
            IpPermissions=[
                {
                    'IpProtocol': protocol,
                    'FromPort': port,
                    'ToPort': port,
                    'IpRanges': [
                        {
                            'CidrIp': destination,
                            'Description': f'Allow {protocol} to {destination}'
                        }
                    ]
                }
            ]
        )
        print(f"Added outbound rule: {protocol}:{port} to {destination}")
    except ClientError as e:
        if e.response['Error']['Code'] == 'InvalidPermission.Duplicate':
            print(f"Rule already exists: {protocol}:{port} to {destination}")
        else:
            print(f"Error adding rule: {e}")

def create_compliance_scanner_sg(vpc_id):
    """Create a security group for compliance scanner."""
    group_id = create_security_group(
        vpc_id,
        'compliance-scanner-sg',
        'Security group for automated compliance scanner'
    )
    
    if group_id:
        # Inbound: SSH from VPC only
        add_inbound_rule(group_id, 'tcp', 22, '10.0.0.0/16')
        
        # Outbound: HTTPS for AWS APIs
        add_outbound_rule(group_id, 'tcp', 443, '0.0.0.0/0')
        
        # Outbound: HTTP for package updates (optional, can be restricted)
        add_outbound_rule(group_id, 'tcp', 80, '0.0.0.0/0')
        
        return group_id
    return None

# Example usage
if __name__ == "__main__":
    vpc_id = "vpc-12345678"  # Your VPC ID
    sg_id = create_compliance_scanner_sg(vpc_id)
    print(f"Security group ready: {sg_id}")
```

## Auditing Security Groups for Risks

Here's a script to find risky security group configurations:

```python
import boto3

# Risky ports that shouldn't be open to the internet
RISKY_PORTS = {
    22: "SSH",
    3389: "RDP",
    445: "SMB",
    139: "NetBIOS",
    1433: "SQL Server",
    3306: "MySQL",
    5432: "PostgreSQL",
    27017: "MongoDB"
}

def audit_security_groups():
    """Audit all security groups for risky configurations."""
    ec2_client = boto3.client('ec2')
    
    # Get all security groups
    response = ec2_client.describe_security_groups()
    
    print("=" * 70)
    print("Security Group Security Audit")
    print("=" * 70)
    
    for sg in response['SecurityGroups']:
        sg_id = sg['GroupId']
        sg_name = sg['GroupName']
        vpc_id = sg['VpcId']
        
        print(f"\nSecurity Group: {sg_name} ({sg_id})")
        print(f"VPC: {vpc_id}")
        print("-" * 70)
        
        issues = []
        
        # Check inbound rules
        for rule in sg.get('IpPermissions', []):
            port = rule.get('FromPort')
            protocol = rule.get('IpProtocol')
            
            # Check if port is risky
            if port in RISKY_PORTS:
                # Check if open to internet (0.0.0.0/0)
                for ip_range in rule.get('IpRanges', []):
                    cidr = ip_range.get('CidrIp', '')
                    if cidr == '0.0.0.0/0':
                        issues.append(
                            f"CRITICAL: Port {port} ({RISKY_PORTS[port]}) "
                            f"is open to the internet (0.0.0.0/0)"
                        )
            
            # Check for overly permissive rules
            for ip_range in rule.get('IpRanges', []):
                cidr = ip_range.get('CidrIp', '')
                if cidr == '0.0.0.0/0' and protocol != '-1':
                    if port not in [80, 443]:  # HTTP/HTTPS might be OK
                        issues.append(
                            f"WARNING: Port {port} ({protocol}) open to "
                            f"internet (0.0.0.0/0)"
                        )
        
        if issues:
            print("⚠️  Security Issues Found:")
            for issue in issues:
                print(f"   - {issue}")
        else:
            print("✅ No obvious security issues found")
        
        # Show current rules
        print("\nCurrent Inbound Rules:")
        if sg.get('IpPermissions'):
            for rule in sg['IpPermissions']:
                port = rule.get('FromPort', 'All')
                protocol = rule.get('IpProtocol', 'all')
                sources = [ip.get('CidrIp', '') for ip in rule.get('IpRanges', [])]
                print(f"   {protocol}:{port} from {', '.join(sources) if sources else 'N/A'}")

if __name__ == "__main__":
    audit_security_groups()
```

## Security Best Practices

### 1. Principle of Least Privilege

**Bad:**
```
Allow: All traffic (0.0.0.0/0) on all ports
```

**Good:**
```
Allow: SSH (22) from 10.0.0.0/16 only
Allow: HTTPS (443) from 0.0.0.0/0 (if needed for web server)
```

### 2. Restrict Outbound Traffic

**Bad:**
```
Allow: All outbound traffic (default)
```

**Good:**
```
Allow: HTTPS (443) to 0.0.0.0/0 (for AWS APIs)
Allow: HTTP (80) to specific update servers only
Block: Everything else
```

### 3. Use Specific IP Ranges

**Bad:**
```
Source: 0.0.0.0/0 (entire internet)
```

**Good:**
```
Source: 10.0.1.0/24 (specific subnet)
Source: YOUR_OFFICE_IP/32 (your office IP only)
```

### 4. Reference Other Security Groups

Instead of IP addresses, reference other security groups:

```bash
# Allow app servers to access database
aws ec2 authorize-security-group-ingress \
  --group-id sg-database \
  --protocol tcp \
  --port 3306 \
  --source-group sg-app-servers
```

This is more secure and flexible than IP addresses!

### 5. Regular Audits

Run security group audits regularly:

```bash
# Use AWS Config to monitor security groups
aws configservice put-config-rule \
  --config-rule file://sg-audit-rule.json
```

## Common Mistakes

### Mistake 1: Opening SSH to Internet

**Don't do this:**
```
SSH (22) from 0.0.0.0/0
```

**Do this instead:**
```
SSH (22) from YOUR_IP/32
# Or use AWS Systems Manager Session Manager (no SSH needed!)
```

### Mistake 2: Opening Database Ports to Internet

**Don't do this:**
```
MySQL (3306) from 0.0.0.0/0
```

**Do this instead:**
```
MySQL (3306) from 10.0.1.0/24 (app servers only)
# Or use RDS with proper security groups
```

### Mistake 3: Not Restricting Outbound Traffic

**Don't do this:**
```
Allow all outbound (default)
```

**Do this instead:**
```
Allow only what's needed:
- HTTPS (443) for AWS APIs
- Specific ports for specific services
```

## Key Takeaways

1. **Security Groups = Virtual Firewall** - Control traffic to/from instances
2. **Default Deny** - Everything blocked unless explicitly allowed
3. **Stateful** - Return traffic automatically allowed
4. **Least Privilege** - Only allow what's needed
5. **Restrict Outbound** - Don't allow all outbound traffic
6. **Use Specific IPs** - Not 0.0.0.0/0 when possible
7. **Reference Other SGs** - More secure than IP addresses
8. **Regular Audits** - Check for risky configurations

## Practice Exercise

Try this yourself:

1. Create a security group for a web server
2. Add rules for HTTP, HTTPS, and SSH
3. Restrict SSH to your IP only
4. Audit your security groups for risks
5. Create a security group that references another

## Resources to Learn More

- [AWS Security Groups Documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/working-with-security-groups.html)
- [Security Group Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html)
- [AWS Network ACLs](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html)

## What's Next?

Now that you understand Security Groups, you're ready to:
- Learn about VPC networking (our next post!)
- Configure secure multi-tier architectures
- Build properly secured applications

Remember: Security Groups are your first line of defense. Configure them carefully!

> **💡 Pro Tip:** Use AWS Systems Manager Session Manager instead of SSH when possible. It doesn't require opening port 22, and all sessions are logged. Much more secure!

---

*Ready to dive deeper into networking? Check out our next post on AWS VPC, where we'll learn how to build secure network architectures!*

