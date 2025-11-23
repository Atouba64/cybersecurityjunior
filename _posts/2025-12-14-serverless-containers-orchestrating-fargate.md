---
layout: post
title: "Serverless Containers: Orchestrating Fargate"
date: 2025-11-16 10:00:00 -0400
categories: [Containers]
tags: [ECS, Fargate, Orchestration, Python, AWS]
excerpt: "We have our Docker image in the registry. Now we need to run it. Fargate allows us to run containers without managing the underlying servers."
---

We have our Docker image in the registry. Now we need to run it. In the old days, this meant provisioning a cluster of EC2 instances and managing them. Enter AWS Fargate. Fargate allows us to run containers without managing the underlying servers. In this tutorial, we will use Boto3 to 'order' a container execution. We will define the resources, attach it to our VPC, and watch it spin up, do its job, and shut down.

## Fargate: Containers Without Server Management

Fargate is serverless containers. You define:
- CPU and memory
- Container image
- Network configuration

AWS handles the rest.

## Task Definitions

A task definition is a blueprint for your container:

```python
import boto3

ecs = boto3.client('ecs')

def register_task_definition(task_family, image_uri, cpu='256', memory='512'):
    """Register an ECS task definition."""
    
    response = ecs.register_task_definition(
        family=task_family,
        networkMode='awsvpc',
        requiresCompatibilities=['FARGATE'],
        cpu=cpu,  # CPU units (256 = 0.25 vCPU)
        memory=memory,  # Memory in MB
        containerDefinitions=[
            {
                'name': 'app-container',
                'image': image_uri,
                'essential': True,
                'logConfiguration': {
                    'logDriver': 'awslogs',
                    'options': {
                        'awslogs-group': '/ecs/my-app',
                        'awslogs-region': 'us-east-1',
                        'awslogs-stream-prefix': 'ecs'
                    }
                },
                'environment': [
                    {'name': 'ENVIRONMENT', 'value': 'production'}
                ]
            }
        ],
        executionRoleArn='arn:aws:iam::123456789012:role/ecsTaskExecutionRole',
        taskRoleArn='arn:aws:iam::123456789012:role/ecsTaskRole'
    )
    
    task_def_arn = response['taskDefinition']['taskDefinitionArn']
    print(f"✅ Registered task definition: {task_def_arn}")
    return task_def_arn
```

## Running the Task

Now let's run a task using Fargate:

```python
def run_fargate_task(cluster_name, task_definition, subnets, security_groups):
    """Run a Fargate task."""
    
    response = ecs.run_task(
        cluster=cluster_name,
        taskDefinition=task_definition,
        launchType='FARGATE',
        networkConfiguration={
            'awsvpcConfiguration': {
                'subnets': subnets,
                'securityGroups': security_groups,
                'assignPublicIp': 'ENABLED'  # Or 'DISABLED' for private subnets
            }
        },
        desiredCount=1
    )
    
    task_arn = response['tasks'][0]['taskArn']
    print(f"✅ Started task: {task_arn}")
    return task_arn

def wait_for_task_completion(cluster_name, task_arn):
    """Wait for task to complete."""
    
    waiter = ecs.get_waiter('tasks_stopped')
    waiter.wait(
        cluster=cluster_name,
        tasks=[task_arn]
    )
    
    # Get task details
    response = ecs.describe_tasks(
        cluster=cluster_name,
        tasks=[task_arn]
    )
    
    task = response['tasks'][0]
    exit_code = task['containers'][0].get('exitCode', 'N/A')
    
    print(f"✅ Task completed with exit code: {exit_code}")
    return exit_code
```

## Network Configuration

Fargate tasks must be attached to your VPC:

```python
def run_task_in_vpc(cluster_name, task_definition, vpc_id):
    """Run a Fargate task in a VPC."""
    
    # Get subnets in the VPC
    ec2 = boto3.client('ec2')
    subnets = ec2.describe_subnets(
        Filters=[
            {'Name': 'vpc-id', 'Values': [vpc_id]},
            {'Name': 'tag:Type', 'Values': ['private']}  # Use private subnets
        ]
    )['Subnets']
    
    subnet_ids = [s['SubnetId'] for s in subnets]
    
    # Get or create security group
    security_groups = get_or_create_security_group(vpc_id)
    
    # Run the task
    task_arn = run_fargate_task(
        cluster_name,
        task_definition,
        subnet_ids,
        security_groups
    )
    
    return task_arn
```

## Troubleshooting: Debugging Pending Tasks

If a task stays in "PENDING" state, common causes:

1. **NAT Gateway issues**: Private subnets need NAT Gateway for internet access
2. **IAM permissions**: Task execution role needs ECR pull permissions
3. **Resource limits**: Not enough CPU/memory available

```python
def debug_task(cluster_name, task_arn):
    """Debug a Fargate task."""
    
    response = ecs.describe_tasks(
        cluster=cluster_name,
        tasks=[task_arn]
    )
    
    task = response['tasks'][0]
    
    print(f"Task Status: {task['lastStatus']}")
    print(f"Desired Status: {task['desiredStatus']}")
    
    if task['lastStatus'] == 'PENDING':
        print("⚠️  Task is pending. Check:")
        print("   - NAT Gateway in private subnets")
        print("   - IAM permissions for task execution role")
        print("   - Resource availability")
    
    # Get container logs
    log_group = '/ecs/my-app'
    logs = boto3.client('logs')
    
    try:
        log_streams = logs.describe_log_streams(
            logGroupName=log_group,
            orderBy='LastEventTime',
            descending=True,
            limit=1
        )
        
        if log_streams['logStreams']:
            stream_name = log_streams['logStreams'][0]['logStreamName']
            events = logs.get_log_events(
                logGroupName=log_group,
                logStreamName=stream_name
            )
            
            print("\n📋 Recent logs:")
            for event in events['events'][-10:]:
                print(event['message'])
    
    except Exception as e:
        print(f"Could not retrieve logs: {e}")
```

## Compute That Scales with Your Needs

Fargate provides serverless container execution. You pay only for the time your containers run, and AWS handles all the infrastructure management. This is perfect for batch jobs, scheduled tasks, and on-demand processing.

In the next post, we'll explore CI/CD with GitHub Actions and OIDC, automating deployments securely.

