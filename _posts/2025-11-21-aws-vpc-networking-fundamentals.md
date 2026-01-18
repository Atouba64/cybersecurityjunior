---
layout: post
title: "AWS VPC Networking: Building Secure Cloud Networks"
date: 2025-11-21 10:00:00 -0400
categories: [AWS, Cloud Security, Networking]
tags: [aws, vpc, networking, cloud-security, subnets, routing]
image: https://placehold.co/1000x400/FF9900/FFFFFF?text=AWS+VPC+Networking
excerpt: "VPC (Virtual Private Cloud) is like building your own private network in AWS. Just like how you'd design a secure office building with different floors and access controls, VPC lets you design secure network architectures. Let's learn how to build them properly."
---

> **Think of it this way:** When you create an AWS account, you get a default VPC - like a basic apartment building. It works, but it's not optimized for security. Building your own VPC is like designing a custom office building with proper security zones, controlled access, and network segmentation. Let's learn how to build secure VPC architectures.

## What is a VPC, Really?

A **VPC (Virtual Private Cloud)** is your own isolated network in AWS. Think of it as:

**Real-world analogy:** 
- **VPC** = Your company's private network
- **Subnets** = Different floors/departments (public, private, database)
- **Route Tables** = The building's directory (where traffic goes)
- **Internet Gateway** = The main entrance/exit
- **NAT Gateway** = The secure exit (private subnets can go out, but nothing comes in)

## Core VPC Components

### 1. VPC (Virtual Private Cloud)

The container for everything. Defined by a CIDR block (IP address range):

```
VPC: 10.0.0.0/16
This gives you 65,536 IP addresses (10.0.0.0 to 10.0.255.255)
```

### 2. Subnets

Subdivisions of your VPC. Usually organized by function:

- **Public Subnet** - Has direct internet access (web servers)
- **Private Subnet** - No direct internet access (application servers)
- **Database Subnet** - Isolated, no internet (databases)

```
Public Subnet:  10.0.1.0/24 (256 IPs)
Private Subnet: 10.0.2.0/24 (256 IPs)
Database Subnet: 10.0.3.0/24 (256 IPs)
```

### 3. Internet Gateway (IGW)

Allows resources in public subnets to access the internet.

**Think of it as:** The main door of your building that connects to the outside world.

### 4. NAT Gateway

Allows resources in private subnets to access the internet (outbound only).

**Think of it as:** A one-way door - private resources can go out, but nothing can come in directly.

### 5. Route Tables

Define where traffic goes. Like a GPS for your network.

```
Route Table for Public Subnet:
10.0.0.0/16 → local (stays in VPC)
0.0.0.0/0 → igw-xxxxx (goes to internet)

Route Table for Private Subnet:
10.0.0.0/16 → local (stays in VPC)
0.0.0.0/0 → nat-xxxxx (goes through NAT to internet)
```

## Building a Secure VPC Architecture

Let's build a production-ready VPC for the compliance tool:

### Architecture Overview

```
Internet
   │
   ▼
Internet Gateway
   │
   ├── Public Subnet (10.0.1.0/24)
   │   └── NAT Gateway
   │       │
   │       ├── Private Subnet (10.0.2.0/24)
   │       │   └── Application Servers
   │       │
   │       └── Database Subnet (10.0.3.0/24)
   │           └── Databases (isolated)
```

### Step 1: Create the VPC

```bash
# Create VPC
aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=ComplianceTool-VPC}]'
```

### Step 2: Create Subnets

```bash
# Get VPC ID (from previous step)
VPC_ID="vpc-12345678"

# Public Subnet (for NAT Gateway)
aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Public-Subnet-1a}]'

# Private Subnet (for application servers)
aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.2.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Private-Subnet-1a}]'

# Database Subnet (isolated)
aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.3.0/24 \
  --availability-zone us-east-1b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Database-Subnet-1b}]'
```

### Step 3: Create Internet Gateway

```bash
# Create Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=ComplianceTool-IGW}]' \
  --query 'InternetGateway.InternetGatewayId' --output text)

# Attach to VPC
aws ec2 attach-internet-gateway \
  --internet-gateway-id $IGW_ID \
  --vpc-id $VPC_ID
```

### Step 4: Create NAT Gateway

```bash
# Allocate Elastic IP for NAT Gateway
ALLOCATION_ID=$(aws ec2 allocate-address \
  --domain vpc \
  --query 'AllocationId' --output text)

# Get Public Subnet ID
PUBLIC_SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=Public-Subnet-1a" \
  --query 'Subnets[0].SubnetId' --output text)

# Create NAT Gateway
NAT_GW_ID=$(aws ec2 create-nat-gateway \
  --subnet-id $PUBLIC_SUBNET_ID \
  --allocation-id $ALLOCATION_ID \
  --tag-specifications 'ResourceType=nat-gateway,Tags=[{Key=Name,Value=ComplianceTool-NAT}]' \
  --query 'NatGateway.NatGatewayId' --output text)

# Wait for NAT Gateway to be available
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW_ID
```

### Step 5: Configure Route Tables

```bash
# Public Route Table
PUBLIC_RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Public-RouteTable}]' \
  --query 'RouteTable.RouteTableId' --output text)

# Add route to internet
aws ec2 create-route \
  --route-table-id $PUBLIC_RT_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID

# Associate public subnet
aws ec2 associate-route-table \
  --subnet-id $PUBLIC_SUBNET_ID \
  --route-table-id $PUBLIC_RT_ID

# Private Route Table
PRIVATE_RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Private-RouteTable}]' \
  --query 'RouteTable.RouteTableId' --output text)

# Add route through NAT Gateway
aws ec2 create-route \
  --route-table-id $PRIVATE_RT_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id $NAT_GW_ID

# Get Private Subnet ID
PRIVATE_SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=Private-Subnet-1a" \
  --query 'Subnets[0].SubnetId' --output text)

# Associate private subnet
aws ec2 associate-route-table \
  --subnet-id $PRIVATE_SUBNET_ID \
  --route-table-id $PRIVATE_RT_ID
```

## VPC Flow Logs: Monitoring Network Traffic

VPC Flow Logs record network traffic. Essential for security monitoring:

```bash
# Create CloudWatch Log Group
aws logs create-log-group --log-group-name /aws/vpc/flowlogs

# Create IAM role for Flow Logs
# (Create role with VPC Flow Logs permissions)

# Enable Flow Logs
aws ec2 create-flow-logs \
  --resource-type VPC \
  --resource-ids $VPC_ID \
  --traffic-type ALL \
  --log-destination-type cloud-watch-logs \
  --log-group-name /aws/vpc/flowlogs
```

**What this captures:**
- Source and destination IPs
- Ports
- Protocols
- Accepted/rejected traffic
- Timestamps

**Real-world use:** Detect suspicious traffic, investigate security incidents, compliance auditing.

## VPC Endpoints: Private AWS Service Access

VPC Endpoints allow private access to AWS services (S3, DynamoDB, etc.) without going through the internet:

```bash
# Create S3 VPC Endpoint
aws ec2 create-vpc-endpoint \
  --vpc-id $VPC_ID \
  --service-name com.amazonaws.us-east-1.s3 \
  --route-table-ids $PRIVATE_RT_ID
```

**Benefits:**
- No internet gateway needed
- No data transfer charges
- More secure (traffic stays in AWS network)
- Lower latency

## Python Script: Automated VPC Creation

Here's a complete script to create a secure VPC:

```python
import boto3
import time
from botocore.exceptions import ClientError

def create_secure_vpc(region='us-east-1'):
    """Create a secure VPC with public, private, and database subnets."""
    ec2_client = boto3.client('ec2', region_name=region)
    
    # Step 1: Create VPC
    print("Creating VPC...")
    vpc_response = ec2_client.create_vpc(
        CidrBlock='10.0.0.0/16',
        TagSpecifications=[
            {
                'ResourceType': 'vpc',
                'Tags': [{'Key': 'Name', 'Value': 'ComplianceTool-VPC'}]
            }
        ]
    )
    vpc_id = vpc_response['Vpc']['VpcId']
    print(f"✅ VPC created: {vpc_id}")
    
    # Enable DNS hostnames
    ec2_client.modify_vpc_attribute(
        VpcId=vpc_id,
        EnableDnsHostnames={'Value': True}
    )
    
    # Step 2: Create Internet Gateway
    print("Creating Internet Gateway...")
    igw_response = ec2_client.create_internet_gateway(
        TagSpecifications=[
            {
                'ResourceType': 'internet-gateway',
                'Tags': [{'Key': 'Name', 'Value': 'ComplianceTool-IGW'}]
            }
        ]
    )
    igw_id = igw_response['InternetGateway']['InternetGatewayId']
    ec2_client.attach_internet_gateway(InternetGatewayId=igw_id, VpcId=vpc_id)
    print(f"✅ Internet Gateway created and attached: {igw_id}")
    
    # Step 3: Get Availability Zones
    azs = ec2_client.describe_availability_zones()
    az1 = azs['AvailabilityZones'][0]['ZoneName']
    az2 = azs['AvailabilityZones'][1]['ZoneName']
    
    # Step 4: Create Subnets
    print("Creating subnets...")
    subnets = {}
    
    # Public Subnet
    public_subnet = ec2_client.create_subnet(
        VpcId=vpc_id,
        CidrBlock='10.0.1.0/24',
        AvailabilityZone=az1,
        TagSpecifications=[
            {
                'ResourceType': 'subnet',
                'Tags': [{'Key': 'Name', 'Value': 'Public-Subnet-1a'}]
            }
        ]
    )
    subnets['public'] = public_subnet['Subnet']['SubnetId']
    print(f"✅ Public subnet created: {subnets['public']}")
    
    # Private Subnet
    private_subnet = ec2_client.create_subnet(
        VpcId=vpc_id,
        CidrBlock='10.0.2.0/24',
        AvailabilityZone=az1,
        TagSpecifications=[
            {
                'ResourceType': 'subnet',
                'Tags': [{'Key': 'Name', 'Value': 'Private-Subnet-1a'}]
            }
        ]
    )
    subnets['private'] = private_subnet['Subnet']['SubnetId']
    print(f"✅ Private subnet created: {subnets['private']}")
    
    # Database Subnet
    db_subnet = ec2_client.create_subnet(
        VpcId=vpc_id,
        CidrBlock='10.0.3.0/24',
        AvailabilityZone=az2,
        TagSpecifications=[
            {
                'ResourceType': 'subnet',
                'Tags': [{'Key': 'Name', 'Value': 'Database-Subnet-1b'}]
            }
        ]
    )
    subnets['database'] = db_subnet['Subnet']['SubnetId']
    print(f"✅ Database subnet created: {subnets['database']}")
    
    # Step 5: Create NAT Gateway
    print("Creating NAT Gateway...")
    # Allocate Elastic IP
    eip = ec2_client.allocate_address(Domain='vpc')
    allocation_id = eip['AllocationId']
    
    # Create NAT Gateway
    nat_gw = ec2_client.create_nat_gateway(
        SubnetId=subnets['public'],
        AllocationId=allocation_id,
        TagSpecifications=[
            {
                'ResourceType': 'nat-gateway',
                'Tags': [{'Key': 'Name', 'Value': 'ComplianceTool-NAT'}]
            }
        ]
    )
    nat_gw_id = nat_gw['NatGateway']['NatGatewayId']
    print(f"✅ NAT Gateway created: {nat_gw_id}")
    
    # Wait for NAT Gateway to be available
    print("Waiting for NAT Gateway to be available...")
    waiter = ec2_client.get_waiter('nat_gateway_available')
    waiter.wait(NatGatewayIds=[nat_gw_id])
    print("✅ NAT Gateway is available")
    
    # Step 6: Create Route Tables
    print("Creating route tables...")
    
    # Public Route Table
    public_rt = ec2_client.create_route_table(
        VpcId=vpc_id,
        TagSpecifications=[
            {
                'ResourceType': 'route-table',
                'Tags': [{'Key': 'Name', 'Value': 'Public-RouteTable'}]
            }
        ]
    )
    public_rt_id = public_rt['RouteTable']['RouteTableId']
    
    # Add route to internet
    ec2_client.create_route(
        RouteTableId=public_rt_id,
        DestinationCidrBlock='0.0.0.0/0',
        GatewayId=igw_id
    )
    
    # Associate public subnet
    ec2_client.associate_route_table(
        SubnetId=subnets['public'],
        RouteTableId=public_rt_id
    )
    print(f"✅ Public route table configured")
    
    # Private Route Table
    private_rt = ec2_client.create_route_table(
        VpcId=vpc_id,
        TagSpecifications=[
            {
                'ResourceType': 'route-table',
                'Tags': [{'Key': 'Name', 'Value': 'Private-RouteTable'}]
            }
        ]
    )
    private_rt_id = private_rt['RouteTable']['RouteTableId']
    
    # Add route through NAT
    ec2_client.create_route(
        RouteTableId=private_rt_id,
        DestinationCidrBlock='0.0.0.0/0',
        NatGatewayId=nat_gw_id
    )
    
    # Associate private subnet
    ec2_client.associate_route_table(
        SubnetId=subnets['private'],
        RouteTableId=private_rt_id
    )
    print(f"✅ Private route table configured")
    
    return {
        'vpc_id': vpc_id,
        'igw_id': igw_id,
        'nat_gw_id': nat_gw_id,
        'subnets': subnets,
        'route_tables': {
            'public': public_rt_id,
            'private': private_rt_id
        }
    }

if __name__ == "__main__":
    result = create_secure_vpc()
    print("\n" + "=" * 60)
    print("VPC Creation Complete!")
    print("=" * 60)
    print(f"VPC ID: {result['vpc_id']}")
    print(f"Public Subnet: {result['subnets']['public']}")
    print(f"Private Subnet: {result['subnets']['private']}")
    print(f"Database Subnet: {result['subnets']['database']}")
```

## Security Best Practices

### 1. Network Segmentation

Separate your resources by function:
- Public subnets for load balancers
- Private subnets for application servers
- Isolated subnets for databases

### 2. Enable Flow Logs

Always enable VPC Flow Logs for:
- Security monitoring
- Compliance auditing
- Troubleshooting

### 3. Use VPC Endpoints

For AWS service access, use VPC endpoints instead of internet:
- More secure
- Lower cost
- Better performance

### 4. Restrict Subnet Access

Use Network ACLs (in addition to Security Groups) for defense in depth.

### 5. Multi-AZ Deployment

Deploy resources across multiple Availability Zones for high availability.

## Key Takeaways

1. **VPC = Your Private Network** - Isolated network in AWS
2. **Subnets = Network Segments** - Organize by function
3. **Internet Gateway = Public Access** - For public subnets
4. **NAT Gateway = Private Internet Access** - One-way outbound
5. **Route Tables = Traffic Direction** - Where packets go
6. **Flow Logs = Monitoring** - Essential for security
7. **VPC Endpoints = Private AWS Access** - More secure, cheaper

## Practice Exercise

Try this yourself:

1. Create a VPC with CIDR 10.0.0.0/16
2. Create public and private subnets
3. Create Internet Gateway and NAT Gateway
4. Configure route tables
5. Enable VPC Flow Logs
6. Launch an instance in the private subnet and test connectivity

## Resources to Learn More

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [VPC Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)
- [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)

## What's Next?

Now that you understand VPC networking, you're ready to:
- Build multi-tier architectures
- Configure secure application deployments
- Understand advanced networking concepts

Remember: Good network design is the foundation of secure cloud infrastructure!

> **💡 Pro Tip:** Start with AWS's VPC Wizard for your first VPC. It creates a basic setup you can then customize. Once you understand the components, build your own from scratch!

---

*Ready to learn about security monitoring? Check out our next post on Elasticsearch and SIEM, where we'll learn how to collect and analyze security events!*

