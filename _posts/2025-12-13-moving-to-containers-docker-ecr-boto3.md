---
layout: post
title: "Moving to Containers: Docker, ECR, and Boto3"
date: 2025-12-13 10:00:00 -0400
categories: [Containers]
tags: [Docker, ECR, Containers, Python, AWS]
excerpt: "Serverless is great, but sometimes you need a heavy lifter. Whether it's a legacy application or a machine learning model, sometimes you need a container."
---

Serverless is great, but sometimes you need a heavy lifter. Whether it's a legacy application or a machine learning model, sometimes you need a container. In this post, we wrap our Python application in Docker, ensuring it runs exactly the same way in the cloud as it does on your laptop. We will use Boto3 to provision an Elastic Container Registry (ECR) and learn the specific authentication handshake required to push our images to AWS.

## Lambda vs. Containers: When to Switch

**Use Lambda when:**
- Short execution time (< 15 minutes)
- Event-driven workloads
- Minimal dependencies

**Use Containers when:**
- Long-running processes
- Heavy dependencies (ML models, large libraries)
- Legacy applications
- Need for consistent environments

## The Registry: ECR

ECR is AWS's container registry. Let's create one:

```python
import boto3
import base64
import subprocess

ecr = boto3.client('ecr')

def create_ecr_repository(repo_name):
    """Create an ECR repository."""
    
    try:
        response = ecr.create_repository(
            repositoryName=repo_name,
            imageTagMutability='MUTABLE',
            imageScanningConfiguration={
                'scanOnPush': True  # Automatically scan for vulnerabilities
            }
        )
        
        repo_uri = response['repository']['repositoryUri']
        print(f"✅ Created ECR repository: {repo_uri}")
        return repo_uri
    
    except ecr.exceptions.RepositoryAlreadyExistsException:
        print(f"Repository {repo_name} already exists")
        # Get existing repo URI
        response = ecr.describe_repositories(repositoryNames=[repo_name])
        return response['repositories'][0]['repositoryUri']
```

## The Auth Dance: Docker Login

ECR requires authentication. Here's how to get credentials:

```python
def get_ecr_login_token():
    """Get ECR login token."""
    
    response = ecr.get_authorization_token()
    token = response['authorizationData'][0]['authorizationToken']
    
    # Decode base64
    decoded = base64.b64decode(token).decode('utf-8')
    username, password = decoded.split(':')
    
    registry_url = response['authorizationData'][0]['proxyEndpoint']
    
    return username, password, registry_url

def docker_login():
    """Login to ECR using Docker."""
    
    username, password, registry_url = get_ecr_login_token()
    
    # Run docker login
    subprocess.run([
        'docker', 'login',
        '--username', username,
        '--password-stdin',
        registry_url
    ], input=password.encode(), check=True)
    
    print("✅ Logged into ECR")
```

## The Build Process

Now let's build and push a Docker image:

```python
def build_and_push_image(repo_uri, dockerfile_path='.', tag='latest'):
    """Build Docker image and push to ECR."""
    
    # Extract repo name from URI
    repo_name = repo_uri.split('/')[-1]
    image_uri = f"{repo_uri}:{tag}"
    
    # Build the image
    print(f"🔨 Building Docker image...")
    subprocess.run([
        'docker', 'build',
        '-t', repo_name,
        '-f', dockerfile_path,
        '.'
    ], check=True)
    
    # Tag for ECR
    subprocess.run([
        'docker', 'tag',
        repo_name,
        image_uri
    ], check=True)
    
    # Push to ECR
    print(f"📤 Pushing to ECR...")
    subprocess.run([
        'docker', 'push',
        image_uri
    ], check=True)
    
    print(f"✅ Image pushed: {image_uri}")
    return image_uri
```

## Example Dockerfile

Here's a sample Dockerfile for a Python application:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Run the application
CMD ["python", "app.py"]
```

## Complete Workflow

Here's the complete workflow:

```python
def deploy_container_app(repo_name, dockerfile_path='.'):
    """Complete container deployment workflow."""
    
    # Create ECR repository
    repo_uri = create_ecr_repository(repo_name)
    
    # Login to ECR
    docker_login()
    
    # Build and push
    image_uri = build_and_push_image(repo_uri, dockerfile_path)
    
    print(f"✅ Container deployed: {image_uri}")
    return image_uri
```

## Your Code is Packaged and Ready to Ship

You've containerized your application and pushed it to ECR. In the next post, we'll run this container using ECS Fargate, completing the serverless container workflow.

