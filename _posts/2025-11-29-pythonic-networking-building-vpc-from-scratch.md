---
layout: post
title: "Pythonic Networking: Building a VPC from Scratch"
date: 2025-11-21 10:00:00 -0400
categories: [Infrastructure]
tags: [VPC, Networking, Python, InfrastructureAsCode, AWS]
excerpt: "The Virtual Private Cloud (VPC) is the foundation of your cloud security posture. While the AWS console wizard makes it easy, relying on defaults is a security antipattern."
---

The Virtual Private Cloud (VPC) is the foundation of your cloud security posture. It allows you to isolate your resources in a virtual network that you define. While the AWS console wizard makes it easy to click a button and get a 'Default VPC,' relying on defaults is a security antipattern. When you write the code to build a VPC, you are forced to understand the relationship between a Subnet, a Route Table, and an Internet Gateway. In this tutorial, we will write a Python script that generates a resilient, 3-tier network architecture. We won't just build it; we will tag it, route it, and prepare it for production workloads.

## The VPC as Virtual Data Center

A VPC is your virtual data center in the cloud. It's a logically isolated network where you have complete control over IP addressing, routing, and security. Building it with code ensures reproducibility and makes disaster recovery possible—you can rebuild your entire network in minutes, not days.

## The Core Object: Creating the VPC

Let's start by creating the VPC itself:

```python
import boto3
from botocore.exceptions import ClientError

ec2 = boto3.client('ec2')

def create_vpc(cidr_block='10.0.0.0/16', name='production-vpc'):
    """Create a VPC with proper tagging."""
    
    try:
        # Create the VPC
        response = ec2.create_vpc(
            CidrBlock=cidr_block,
            AmazonProvidedIpv6CidrBlock=False
        )
        
        vpc_id = response['Vpc']['VpcId']
        
        # Wait for the VPC to be available
        waiter = ec2.get_waiter('vpc_available')
        waiter.wait(VpcIds=[vpc_id])
        
        # Tag the VPC
        ec2.create_tags(
            Resources=[vpc_id],
            Tags=[
                {'Key': 'Name', 'Value': name},
                {'Key': 'Environment', 'Value': 'Production'},
                {'Key': 'ManagedBy', 'Value': 'Python'}
            ]
        )
        
        print(f"✅ Created VPC: {vpc_id}")
        return vpc_id
    
    except ClientError as e:
        print(f"❌ Error creating VPC: {e}")
        return None
```

### Why Waiters Matter

Notice the `waiter.wait()` call. VPCs are created asynchronously. If you try to create subnets immediately after creating the VPC, you might get an error because the VPC isn't ready yet. Waiters prevent these race conditions.

### Tagging for Cost Allocation

Tags aren't just for organization—they're essential for cost allocation. When you have multiple VPCs across different projects, tags help you understand where your cloud spend is going.

## Subnetting Strategy: Availability Zones

A production VPC needs subnets in multiple Availability Zones (AZs) for high availability. Let's create a 3-tier architecture: public subnets for load balancers, private subnets for application servers, and database subnets for data.

```python
def get_availability_zones():
    """Get available AZs in the current region."""
    response = ec2.describe_availability_zones(
        Filters=[
            {'Name': 'state', 'Values': ['available']}
        ]
    )
    return [az['ZoneName'] for az in response['AvailabilityZones']]

def create_subnets(vpc_id, availability_zones):
    """Create public and private subnets in each AZ."""
    
    subnets = {
        'public': [],
        'private': [],
        'database': []
    }
    
    # Calculate CIDR blocks for each subnet
    # We'll use /24 subnets (256 IPs each)
    base_cidr = '10.0.0.0/16'
    
    for idx, az in enumerate(availability_zones[:2]):  # Use first 2 AZs
        # Public subnet: 10.0.1.x, 10.0.2.x
        public_cidr = f'10.0.{idx+1}.0/24'
        public_subnet = ec2.create_subnet(
            VpcId=vpc_id,
            CidrBlock=public_cidr,
            AvailabilityZone=az
        )
        public_subnet_id = public_subnet['Subnet']['SubnetId']
        subnets['public'].append(public_subnet_id)
        
        # Private subnet: 10.0.11.x, 10.0.12.x
        private_cidr = f'10.0.{idx+11}.0/24'
        private_subnet = ec2.create_subnet(
            VpcId=vpc_id,
            CidrBlock=private_cidr,
            AvailabilityZone=az
        )
        private_subnet_id = private_subnet['Subnet']['SubnetId']
        subnets['private'].append(private_subnet_id)
        
        # Database subnet: 10.0.21.x, 10.0.22.x
        db_cidr = f'10.0.{idx+21}.0/24'
        db_subnet = ec2.create_subnet(
            VpcId=vpc_id,
            CidrBlock=db_cidr,
            AvailabilityZone=az
        )
        db_subnet_id = db_subnet['Subnet']['SubnetId']
        subnets['database'].append(db_subnet_id)
        
        # Tag subnets
        for subnet_type, subnet_id in [
            ('public', public_subnet_id),
            ('private', private_subnet_id),
            ('database', db_subnet_id)
        ]:
            ec2.create_tags(
                Resources=[subnet_id],
                Tags=[
                    {'Key': 'Name', 'Value': f'{subnet_type}-{az}'},
                    {'Key': 'Type', 'Value': subnet_type}
                ]
            )
    
    return subnets
```

### Using Python's ipaddress Library

For more complex subnetting, you can use Python's built-in `ipaddress` library:

```python
import ipaddress

def calculate_subnets(vpc_cidr, subnet_size=24):
    """Calculate subnet CIDR blocks programmatically."""
    network = ipaddress.ip_network(vpc_cidr)
    subnets = list(network.subnets(new_prefix=subnet_size))
    return [str(subnet) for subnet in subnets]
```

## The Gateways: IGW vs. NAT

Public subnets need an Internet Gateway (IGW) for internet access. Private subnets need a NAT Gateway for outbound internet access (but no inbound access).

### Creating the Internet Gateway

```python
def create_internet_gateway(vpc_id):
    """Create and attach an Internet Gateway."""
    
    # Create the IGW
    igw_response = ec2.create_internet_gateway()
    igw_id = igw_response['InternetGateway']['InternetGatewayId']
    
    # Attach it to the VPC
    ec2.attach_internet_gateway(
        InternetGatewayId=igw_id,
        VpcId=vpc_id
    )
    
    print(f"✅ Created and attached IGW: {igw_id}")
    return igw_id
```

### NAT Gateway Considerations

NAT Gateways are expensive (~$32/month + data transfer). For development, consider NAT Instances instead. For production, NAT Gateways provide better availability and performance.

```python
def create_nat_gateway(public_subnet_id, allocation_id):
    """Create a NAT Gateway in a public subnet."""
    
    response = ec2.create_nat_gateway(
        SubnetId=public_subnet_id,
        AllocationId=allocation_id  # Elastic IP allocation
    )
    
    nat_gateway_id = response['NatGateway']['NatGatewayId']
    
    # Wait for it to be available
    waiter = ec2.get_waiter('nat_gateway_available')
    waiter.wait(NatGatewayIds=[nat_gateway_id])
    
    return nat_gateway_id
```

## Routing Tables: Defining Traffic Flow

Route tables determine where traffic goes. Public subnets route 0.0.0.0/0 to the IGW. Private subnets route 0.0.0.0/0 to the NAT Gateway.

```python
def create_route_tables(vpc_id, igw_id, nat_gateway_id, subnets):
    """Create and configure route tables."""
    
    # Public route table
    public_rt = ec2.create_route_table(VpcId=vpc_id)
    public_rt_id = public_rt['RouteTable']['RouteTableId']
    
    # Add route to internet
    ec2.create_route(
        RouteTableId=public_rt_id,
        DestinationCidrBlock='0.0.0.0/0',
        GatewayId=igw_id
    )
    
    # Associate public subnets
    for subnet_id in subnets['public']:
        ec2.associate_route_table(
            RouteTableId=public_rt_id,
            SubnetId=subnet_id
        )
    
    # Private route table
    private_rt = ec2.create_route_table(VpcId=vpc_id)
    private_rt_id = private_rt['RouteTable']['RouteTableId']
    
    # Add route to NAT Gateway
    ec2.create_route(
        RouteTableId=private_rt_id,
        DestinationCidrBlock='0.0.0.0/0',
        NatGatewayId=nat_gateway_id
    )
    
    # Associate private and database subnets
    for subnet_id in subnets['private'] + subnets['database']:
        ec2.associate_route_table(
            RouteTableId=private_rt_id,
            SubnetId=subnet_id
        )
    
    return public_rt_id, private_rt_id
```

## Putting It All Together

```python
def build_production_vpc():
    """Build a complete production-ready VPC."""
    
    # Create VPC
    vpc_id = create_vpc(cidr_block='10.0.0.0/16', name='production-vpc')
    
    # Get availability zones
    azs = get_availability_zones()
    
    # Create subnets
    subnets = create_subnets(vpc_id, azs)
    
    # Create Internet Gateway
    igw_id = create_internet_gateway(vpc_id)
    
    # Allocate Elastic IP for NAT Gateway
    eip = ec2.allocate_address(Domain='vpc')
    allocation_id = eip['AllocationId']
    
    # Create NAT Gateway
    nat_gw_id = create_nat_gateway(subnets['public'][0], allocation_id)
    
    # Create route tables
    create_route_tables(vpc_id, igw_id, nat_gw_id, subnets)
    
    print("✅ Production VPC architecture complete!")
    return vpc_id

if __name__ == '__main__':
    build_production_vpc()
```

## You Now Have a Deployable Network Template

This script creates a production-ready, 3-tier network architecture. You can run it to create identical VPCs across multiple regions or accounts. The network is tagged, routed, and ready for workloads.

In the next post, we'll learn how to audit and clean up security groups—another critical network security task.

