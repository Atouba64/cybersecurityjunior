---
layout: post
title: "Goodbye Manual Deploys: GitHub Actions & OIDC"
date: 2025-11-16 14:00:00 -0400
categories: [DevOps]
tags: [GitHubActions, CI/CD, OIDC, Security, DevOps]
excerpt: "For years, the standard way to deploy from GitHub to AWS was to generate Access Keys and paste them into GitHub Secrets. This works, but it's dangerous."
---

For years, the standard way to deploy from GitHub to AWS was to generate Access Keys and paste them into GitHub Secrets. This works, but it's dangerous. Keys get leaked. There is a better way. OpenID Connect (OIDC) allows GitHub and AWS to shake hands securely without ever exchanging a long-term secret. Today, we implement this gold standard of authentication to build a pipeline that is as secure as it is fast.

## The "It Works on My Machine" Problem

Manual deployments are inconsistent and error-prone. CI/CD solves this by automating the entire deployment process. But security is critical—long-lived credentials in CI systems are a major risk.

## OIDC Configuration

OIDC creates a trust relationship between GitHub and AWS. No secrets needed:

```python
import boto3
import json

iam = boto3.client('iam')

def create_oidc_provider():
    """Create an OIDC identity provider for GitHub."""
    
    # GitHub's OIDC issuer
    url = 'https://token.actions.githubusercontent.com'
    
    # Get thumbprints (GitHub's certificate fingerprints)
    thumbprint_list = [
        '6938fd4d98bab03faadb97b34396831e3780aea1',
        '1c58a3a8518e8759bf075b76b750d4f2df264fcd'
    ]
    
    try:
        response = iam.create_open_id_connect_provider(
            Url=url,
            ClientIDList=['sts.amazonaws.com'],
            ThumbprintList=thumbprint_list
        )
        
        provider_arn = response['OpenIDConnectProviderArn']
        print(f"✅ Created OIDC provider: {provider_arn}")
        return provider_arn
    
    except iam.exceptions.EntityAlreadyExistsException:
        print("OIDC provider already exists")
        # Get existing provider
        response = iam.list_open_id_connect_providers()
        return response['OpenIDConnectProviderList'][0]['Arn']

def create_github_actions_role(provider_arn, github_repo):
    """Create IAM role for GitHub Actions."""
    
    # Extract org and repo from 'org/repo' format
    org, repo = github_repo.split('/')
    
    # Trust policy
    trust_policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Federated": provider_arn
                },
                "Action": "sts:AssumeRoleWithWebIdentity",
                "Condition": {
                    "StringEquals": {
                        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                    },
                    "StringLike": {
                        "token.actions.githubusercontent.com:sub": f"repo:{github_repo}:*"
                    }
                }
            }
        ]
    }
    
    # Create role
    response = iam.create_role(
        RoleName='GitHubActionsDeployRole',
        AssumeRolePolicyDocument=json.dumps(trust_policy),
        Description='Role for GitHub Actions to deploy to AWS'
    )
    
    role_arn = response['Role']['Arn']
    
    # Attach policies (e.g., for Lambda deployment)
    iam.attach_role_policy(
        RoleName='GitHubActionsDeployRole',
        PolicyArn='arn:aws:iam::aws:policy/AWSLambda_FullAccess'
    )
    
    print(f"✅ Created role: {role_arn}")
    return role_arn
```

## The Workflow YAML

Here's a GitHub Actions workflow that uses OIDC:

```yaml
name: Deploy to AWS

on:
  push:
    branches: [main]

permissions:
  id-token: write  # Required for OIDC
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsDeployRole
          aws-region: us-east-1
      
      - name: Deploy Lambda function
        run: |
          zip -r function.zip lambda_function.py
          aws lambda update-function-code \
            --function-name my-function \
            --zip-file fileb://function.zip
```

## Running Python Scripts from GitHub Actions

You can run the Python scripts we built in previous posts:

```yaml
- name: Set up Python
  uses: actions/setup-python@v4
  with:
    python-version: '3.11'

- name: Install dependencies
  run: |
    pip install boto3

- name: Run deployment script
  run: |
    python deploy.py
```

## Professionalizing the Pipeline

You've built a secure, automated deployment pipeline that:
- Uses OIDC (no long-lived secrets)
- Deploys automatically on push
- Runs your Python automation scripts
- Maintains security best practices

In the next post, we'll compare Boto3 with Terraform, understanding when to script vs. when to declare infrastructure.

