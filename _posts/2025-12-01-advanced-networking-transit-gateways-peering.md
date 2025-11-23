---
layout: post
title: "Advanced Networking: Transit Gateways and Peering"
date: 2025-11-22 14:00:00 -0400
categories: [Advanced Networking]
tags: [TransitGateway, VPC, EnterpriseArchitecture, Python, NetworkDesign]
excerpt: "As your cloud footprint grows, you will eventually outgrow a single VPC. The simple path is VPC Peering, but as the number of VPCs increases, the mesh becomes a management nightmare."
---

As your cloud footprint grows, you will eventually outgrow a single VPC. You might have a 'Dev' VPC, a 'Prod' VPC, and a 'Shared Services' VPC. Connecting these requires a strategy. The simple path is VPC Peering, but as the number of VPCs increases, the mesh of connections becomes a management nightmare. The enterprise path is the AWS Transit Gateway, a central hub that simplifies your network topology. In this advanced networking tutorial, we will write Boto3 scripts to implement both patterns, and discuss the architectural trade-offs that decide which one you should use.

## The Limitations of VPC Peering at Scale

VPC Peering creates a direct connection between two VPCs. It's simple and works well for 2-3 VPCs. But consider this: with 5 VPCs, you need 10 peering connections (N*(N-1)/2). With 10 VPCs, you need 45 connections. This is the N² complexity problem—each new VPC requires connections to all existing VPCs.

Additionally, peering is non-transitive. If VPC A peers with VPC B, and VPC B peers with VPC C, VPC A cannot reach VPC C through VPC B. You need a direct peering connection between A and C.

## Implementing VPC Peering: The Basic Way

Let's start with the simpler approach:

```python
import boto3
from botocore.exceptions import ClientError

ec2 = boto3.client('ec2')

def create_vpc_peering_connection(requester_vpc_id, accepter_vpc_id, peer_name='vpc-peer'):
    """Create a VPC peering connection."""
    
    try:
        # Create the peering connection
        response = ec2.create_vpc_peering_connection(
            VpcId=requester_vpc_id,
            PeerVpcId=accepter_vpc_id
        )
        
        peering_connection_id = response['VpcPeeringConnection']['VpcPeeringConnectionId']
        
        # Tag it
        ec2.create_tags(
            Resources=[peering_connection_id],
            Tags=[
                {'Key': 'Name', 'Value': peer_name}
            ]
        )
        
        print(f"✅ Created peering connection: {peering_connection_id}")
        print(f"   Status: {response['VpcPeeringConnection']['Status']['Code']}")
        
        return peering_connection_id
    
    except ClientError as e:
        print(f"❌ Error creating peering connection: {e}")
        return None

def accept_vpc_peering_connection(peering_connection_id):
    """Accept a VPC peering connection."""
    
    try:
        response = ec2.accept_vpc_peering_connection(
            VpcPeeringConnectionId=peering_connection_id
        )
        
        print(f"✅ Accepted peering connection: {peering_connection_id}")
        return response['VpcPeeringConnection']
    
    except ClientError as e:
        print(f"❌ Error accepting peering connection: {e}")
        return None
```

### The Acceptance Handshake

VPC peering requires both parties to accept the connection. The requester creates it, and the accepter must explicitly accept it. This is a security feature—you can't force a peering connection on someone else's VPC.

### Updating Route Tables

After peering is established, you need to update route tables in both VPCs:

```python
def add_peering_route(route_table_id, destination_cidr, peering_connection_id):
    """Add a route through a peering connection."""
    
    try:
        ec2.create_route(
            RouteTableId=route_table_id,
            DestinationCidrBlock=destination_cidr,
            VpcPeeringConnectionId=peering_connection_id
        )
        print(f"✅ Added route for {destination_cidr} via peering connection")
    except ClientError as e:
        if e.response['Error']['Code'] == 'RouteAlreadyExists':
            print(f"⏭️  Route already exists")
        else:
            print(f"❌ Error adding route: {e}")
```

## Implementing Transit Gateway: The Enterprise Way

Transit Gateway solves the scaling problem by creating a central hub. All VPCs connect to the hub, not to each other. This reduces complexity from N² to N.

### Creating the Transit Gateway

```python
def create_transit_gateway(name='production-tgw'):
    """Create a Transit Gateway."""
    
    try:
        response = ec2.create_transit_gateway(
            Description=f'Transit Gateway for {name}',
            Options={
                'AmazonSideAsn': 64512,  # Private ASN
                'AutoAcceptSharedAttachments': 'disable',
                'DefaultRouteTableAssociation': 'enable',
                'DefaultRouteTablePropagation': 'enable',
                'VpnEcmpSupport': 'enable',
                'DnsSupport': 'enable'
            },
            TagSpecifications=[
                {
                    'ResourceType': 'transit-gateway',
                    'Tags': [
                        {'Key': 'Name', 'Value': name}
                    ]
                }
            ]
        )
        
        tgw_id = response['TransitGateway']['TransitGatewayId']
        
        # Wait for it to be available
        waiter = ec2.get_waiter('transit_gateway_available')
        waiter.wait(TransitGatewayIds=[tgw_id])
        
        print(f"✅ Created Transit Gateway: {tgw_id}")
        return tgw_id
    
    except ClientError as e:
        print(f"❌ Error creating Transit Gateway: {e}")
        return None
```

### Attaching VPCs to Transit Gateway

```python
def attach_vpc_to_transit_gateway(tgw_id, vpc_id, subnet_ids, name='tgw-attachment'):
    """Attach a VPC to a Transit Gateway."""
    
    try:
        response = ec2.create_transit_gateway_vpc_attachment(
            TransitGatewayId=tgw_id,
            VpcId=vpc_id,
            SubnetIds=subnet_ids,  # At least one subnet per AZ
            Options={
                'DnsSupport': 'enable',
                'Ipv6Support': 'disable'
            },
            TagSpecifications=[
                {
                    'ResourceType': 'transit-gateway-attachment',
                    'Tags': [
                        {'Key': 'Name', 'Value': name}
                    ]
                }
            ]
        )
        
        attachment_id = response['TransitGatewayVpcAttachment']['TransitGatewayAttachmentId']
        
        # Wait for attachment to be available
        waiter = ec2.get_waiter('transit_gateway_attachment_available')
        waiter.wait(TransitGatewayAttachmentIds=[attachment_id])
        
        print(f"✅ Attached VPC {vpc_id} to Transit Gateway")
        return attachment_id
    
    except ClientError as e:
        print(f"❌ Error attaching VPC: {e}")
        return None
```

### Route Propagation

One of Transit Gateway's key advantages is automatic route propagation. When you attach a VPC, its routes are automatically propagated to the Transit Gateway route table. You don't need to manually update routes like you do with peering.

```python
def enable_route_propagation(tgw_route_table_id, attachment_id):
    """Enable route propagation for a Transit Gateway attachment."""
    
    try:
        ec2.enable_transit_gateway_route_table_propagation(
            TransitGatewayRouteTableId=tgw_route_table_id,
            TransitGatewayAttachmentId=attachment_id
        )
        print(f"✅ Enabled route propagation for attachment")
    except ClientError as e:
        print(f"❌ Error enabling propagation: {e}")
```

## Architectural Decision Record: Peering vs. Transit Gateway

### When to Use VPC Peering

- **Simple, high bandwidth**: Direct connection with low latency
- **Low cost**: No per-hour charges, only data transfer
- **2-3 VPCs**: Complexity is manageable
- **Specific use case**: Connecting two VPCs with predictable traffic patterns

### When to Use Transit Gateway

- **Complex, centralized**: Hub-and-spoke architecture
- **Scalability**: More than 3-4 VPCs
- **Multi-account**: Centralized networking across AWS accounts
- **VPN integration**: Connecting on-premises networks
- **Route management**: Automatic route propagation

### Cost Comparison

**VPC Peering:**
- No hourly charges
- Data transfer costs apply

**Transit Gateway:**
- ~$0.05/hour per attachment
- Data processing: $0.02/GB
- Can get expensive with many attachments

## Complete Example: Building a Multi-VPC Architecture

```python
def build_multi_vpc_architecture():
    """Build a production architecture with Transit Gateway."""
    
    # Create Transit Gateway
    tgw_id = create_transit_gateway(name='production-tgw')
    
    # Get the default route table
    response = ec2.describe_transit_gateway_route_tables(
        Filters=[
            {'Name': 'transit-gateway-id', 'Values': [tgw_id]},
            {'Name': 'default-association-route-table', 'Values': ['true']}
        ]
    )
    route_table_id = response['TransitGatewayRouteTables'][0]['TransitGatewayRouteTableId']
    
    # Attach VPCs (assuming you have VPC IDs and subnet IDs)
    vpcs = [
        {'vpc_id': 'vpc-12345678', 'subnets': ['subnet-111', 'subnet-222'], 'name': 'prod-vpc'},
        {'vpc_id': 'vpc-87654321', 'subnets': ['subnet-333', 'subnet-444'], 'name': 'dev-vpc'},
        {'vpc_id': 'vpc-11223344', 'subnets': ['subnet-555', 'subnet-666'], 'name': 'shared-vpc'}
    ]
    
    for vpc in vpcs:
        attachment_id = attach_vpc_to_transit_gateway(
            tgw_id,
            vpc['vpc_id'],
            vpc['subnets'],
            name=f"{vpc['name']}-attachment"
        )
        
        # Enable route propagation
        enable_route_propagation(route_table_id, attachment_id)
    
    print("✅ Multi-VPC architecture complete!")
    return tgw_id
```

## Preparing for Multi-Account Future

Transit Gateway is essential for multi-account architectures. You can share a Transit Gateway across AWS accounts using Resource Access Manager (RAM), creating a centralized networking hub for your entire organization.

In the next post, we'll move from networking to compute, learning how to automate EC2 instance launches with proper bootstrapping.

