---
layout: post
title: "EC2 Automation: Launch Templates and User Data"
date: 2025-12-02 10:00:00 -0400
categories: [Compute]
tags: [EC2, Automation, Python, DevOps, Linux]
excerpt: "In the era of the cloud, we do not manually install software on servers. We automate the provisioning process so that a server is ready to work the second it boots up."
---

In the era of the cloud, we do not manually install software on servers. We do not SSH in to run updates. We automate the provisioning process so that a server is ready to work the second it boots up. This post explores the run_instances API in Boto3. We will tackle the complexities of AMI selection—how to programmatically find the latest Amazon Linux 2023 image—and deeply explore 'User Data,' the mechanism that allows us to inject shell scripts into our instances at boot time. By the end of this post, you will have a script that launches a fully configured web server in seconds.

## Servers as Cattle, not Pets

The old way: manually configure each server, give it a name, treat it like a pet. The new way: servers are cattle. If one dies, you launch another. They're identical, disposable, and reproducible. This philosophy requires automation.

## The run_instances API

Let's start with the basics of launching an EC2 instance:

```python
import boto3
import base64

ec2 = boto3.client('ec2')

def launch_instance():
    """Launch a basic EC2 instance."""
    
    response = ec2.run_instances(
        ImageId='ami-0c55b159cbfafe1f0',  # Amazon Linux 2023
        MinCount=1,
        MaxCount=1,
        InstanceType='t3.micro',
        KeyName='my-key-pair',
        SecurityGroupIds=['sg-12345678'],
        SubnetId='subnet-12345678'
    )
    
    instance_id = response['Instances'][0]['InstanceId']
    print(f"✅ Launched instance: {instance_id}")
    return instance_id
```

### Finding the Latest AMI

Hardcoding AMI IDs is a bad practice—they change as AWS releases updates. Let's find the latest AMI programmatically:

```python
def get_latest_ami(owner='amazon', name_pattern='al2023-ami-*'):
    """Get the latest AMI matching a pattern."""
    
    response = ec2.describe_images(
        Owners=[owner],
        Filters=[
            {'Name': 'name', 'Values': [name_pattern]},
            {'Name': 'state', 'Values': ['available']}
        ]
    )
    
    # Sort by creation date, get the latest
    images = sorted(
        response['Images'],
        key=lambda x: x['CreationDate'],
        reverse=True
    )
    
    if images:
        latest_ami = images[0]['ImageId']
        print(f"✅ Latest AMI: {latest_ami} ({images[0]['Name']})")
        return latest_ami
    else:
        raise ValueError(f"No AMI found matching pattern: {name_pattern}")
```

## Bootstrapping with User Data

User Data is a script that runs when your instance first boots. It's executed as root, so it has full system access. This is where you install software, configure services, and prepare your instance for work.

### What is User Data?

User Data can be:
- **Bash scripts** (Linux)
- **PowerShell scripts** (Windows)
- **Cloud-init directives** (Linux)

The script runs only once, on first boot. If you need it to run again, you'd need to use a different mechanism (like Systems Manager).

### Base64 Encoding Requirement

Boto3 requires User Data to be base64-encoded:

```python
def create_user_data_script():
    """Create a User Data script for bootstrapping."""
    
    script = """#!/bin/bash
# Update system
yum update -y

# Install web server
yum install -y httpd

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Create a simple index page
echo "<h1>Hello from User Data!</h1>" > /var/www/html/index.html

# Pull content from S3 (if needed)
aws s3 cp s3://my-bucket/web-content/ /var/www/html/ --recursive
"""
    
    # Encode to base64
    encoded = base64.b64encode(script.encode('utf-8')).decode('utf-8')
    return encoded
```

### Launching with User Data

```python
def launch_configured_instance():
    """Launch an instance with User Data bootstrapping."""
    
    # Get latest AMI
    ami_id = get_latest_ami()
    
    # Create User Data script
    user_data = create_user_data_script()
    
    response = ec2.run_instances(
        ImageId=ami_id,
        MinCount=1,
        MaxCount=1,
        InstanceType='t3.micro',
        KeyName='my-key-pair',
        SecurityGroupIds=['sg-12345678'],
        SubnetId='subnet-12345678',
        UserData=user_data,  # Base64-encoded script
        IamInstanceProfile={
            'Name': 'EC2-S3-Access'  # For S3 access from instance
        }
    )
    
    instance_id = response['Instances'][0]['InstanceId']
    
    # Wait for instance to be running
    waiter = ec2.get_waiter('instance_running')
    waiter.wait(InstanceIds=[instance_id])
    
    print(f"✅ Instance {instance_id} is running and bootstrapping...")
    return instance_id
```

## Tagging on Creation

Tagging during creation is better than tagging after. It ensures cost allocation integrity from the moment the resource exists:

```python
def launch_tagged_instance():
    """Launch an instance with proper tags."""
    
    ami_id = get_latest_ami()
    user_data = create_user_data_script()
    
    response = ec2.run_instances(
        ImageId=ami_id,
        MinCount=1,
        MaxCount=1,
        InstanceType='t3.micro',
        KeyName='my-key-pair',
        SecurityGroupIds=['sg-12345678'],
        SubnetId='subnet-12345678',
        UserData=user_data,
        TagSpecifications=[
            {
                'ResourceType': 'instance',
                'Tags': [
                    {'Key': 'Name', 'Value': 'web-server-01'},
                    {'Key': 'Environment', 'Value': 'Production'},
                    {'Key': 'Project', 'Value': 'Website'},
                    {'Key': 'ManagedBy', 'Value': 'Python'}
                ]
            }
        ]
    )
    
    instance_id = response['Instances'][0]['InstanceId']
    return instance_id
```

## Advanced User Data: Pulling from S3

For more complex setups, you might store configuration files in S3:

```python
def create_advanced_user_data():
    """User Data script that pulls configuration from S3."""
    
    script = """#!/bin/bash
# Install dependencies
yum update -y
yum install -y httpd python3

# Create application directory
mkdir -p /opt/myapp

# Pull application code from S3
aws s3 sync s3://my-bucket/app-code/ /opt/myapp/

# Pull configuration
aws s3 cp s3://my-bucket/config/app.conf /opt/myapp/config.conf

# Set permissions
chmod +x /opt/myapp/start.sh

# Create systemd service
cat > /etc/systemd/system/myapp.service <<EOF
[Unit]
Description=My Application
After=network.target

[Service]
Type=simple
ExecStart=/opt/myapp/start.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
systemctl daemon-reload
systemctl enable myapp
systemctl start myapp
"""
    
    return base64.b64encode(script.encode('utf-8')).decode('utf-8')
```

## Launch Templates: Reusable Configurations

Launch Templates are reusable configurations for launching instances. They're better than hardcoding parameters:

```python
def create_launch_template():
    """Create a launch template for reusable instance launches."""
    
    ami_id = get_latest_ami()
    user_data = create_user_data_script()
    
    response = ec2.create_launch_template(
        LaunchTemplateName='web-server-template',
        LaunchTemplateData={
            'ImageId': ami_id,
            'InstanceType': 't3.micro',
            'KeyName': 'my-key-pair',
            'SecurityGroupIds': ['sg-12345678'],
            'UserData': user_data,
            'IamInstanceProfile': {
                'Name': 'EC2-S3-Access'
            },
            'TagSpecifications': [
                {
                    'ResourceType': 'instance',
                    'Tags': [
                        {'Key': 'Environment', 'Value': 'Production'},
                        {'Key': 'ManagedBy', 'Value': 'LaunchTemplate'}
                    ]
                }
            ]
        }
    )
    
    template_id = response['LaunchTemplate']['LaunchTemplateId']
    print(f"✅ Created launch template: {template_id}")
    return template_id

def launch_from_template(template_id):
    """Launch an instance from a launch template."""
    
    response = ec2.run_instances(
        LaunchTemplate={'LaunchTemplateId': template_id},
        MinCount=1,
        MaxCount=1
    )
    
    instance_id = response['Instances'][0]['InstanceId']
    return instance_id
```

## Moving Toward Immutable Infrastructure

With User Data and Launch Templates, you're moving toward immutable infrastructure. Instances are launched in a configured state. If you need to change something, you update the template and launch a new instance, then terminate the old one. This is the foundation of Auto Scaling and modern cloud architecture.

In the next post, we'll explore serverless computing with AWS Lambda, where you don't manage servers at all.

