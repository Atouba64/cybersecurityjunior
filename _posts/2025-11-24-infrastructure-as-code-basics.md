---
layout: post
title: "Infrastructure as Code: Managing Cloud Resources with Code"
date: 2025-11-24 10:00:00 -0400
categories: [Infrastructure, DevOps, Cloud Security]
tags: [terraform, pulumi, infrastructure-as-code, iac, devops, cloud]
image: https://placehold.co/1000x400/7B42BC/FFFFFF?text=Infrastructure+as+Code
excerpt: "Instead of clicking through AWS console to create resources, you write code that defines your infrastructure. This code can be versioned, reviewed, tested, and reused. Let's learn Terraform and Pulumi to manage infrastructure like software."
---

> **The old way:** You need a VPC, some EC2 instances, and an S3 bucket. You log into AWS console, click around for an hour, create everything manually, and hope you remember what you did. **The new way:** You write code that defines your infrastructure. Run a command, and everything is created. Need to change something? Update the code. Need to recreate it? Run the code again. That's Infrastructure as Code (IaC).

## What is Infrastructure as Code?

**Infrastructure as Code (IaC)** means managing infrastructure (servers, networks, databases) using code and automation, rather than manual processes.

**Think of it like this:**
- **Manual:** Like building a house by telling workers what to do each day
- **IaC:** Like having a blueprint (code) that workers follow exactly

**Benefits:**
1. **Version Control** - Track changes to infrastructure
2. **Reproducibility** - Create identical environments
3. **Consistency** - Same infrastructure every time
4. **Speed** - Deploy in minutes, not hours
5. **Documentation** - Code IS documentation

## Terraform vs Pulumi

### Terraform

- Uses HCL (HashiCorp Configuration Language)
- Declarative (you describe what you want)
- Very popular, huge ecosystem
- State management built-in

### Pulumi

- Uses real programming languages (Python, TypeScript, Go)
- More flexible, can use loops, functions, etc.
- Modern, cloud-native
- Great for complex logic

**For beginners:** Start with Terraform (simpler syntax). Then learn Pulumi if you need more flexibility.

## Getting Started with Terraform

### Installation

```bash
# macOS
brew install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

### Your First Terraform File

Create `main.tf`:

```hcl
# Configure AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Create an S3 bucket
resource "aws_s3_bucket" "compliance_reports" {
  bucket = "compliance-reports-2025"

  tags = {
    Name        = "Compliance Reports"
    Environment = "Production"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "compliance_reports" {
  bucket = aws_s3_bucket.compliance_reports.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "compliance_reports" {
  bucket = aws_s3_bucket.compliance_reports.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### Initialize and Apply

```bash
# Initialize Terraform (downloads providers)
terraform init

# See what will be created (dry run)
terraform plan

# Create the resources
terraform apply

# Destroy everything (cleanup)
terraform destroy
```

## Building a Complete VPC with Terraform

Here's a complete VPC setup:

```hcl
# variables.tf
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

# main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.environment}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-subnet"
  }
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "${var.environment}-private-subnet"
  }
}

# NAT Gateway (needs Elastic IP)
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.environment}-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "${var.environment}-nat"
  }
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.environment}-public-rt"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.environment}-private-rt"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
```

## Getting Started with Pulumi

### Installation

```bash
# Install Pulumi CLI
curl -fsSL https://get.pulumi.com | sh

# Or with Homebrew
brew install pulumi
```

### Your First Pulumi Program (Python)

Create `__main__.py`:

```python
import pulumi
import pulumi_aws as aws

# Create S3 bucket
bucket = aws.s3.Bucket(
    "compliance-reports",
    bucket="compliance-reports-2025",
    tags={
        "Name": "Compliance Reports",
        "Environment": "Production"
    }
)

# Enable encryption
encryption = aws.s3.BucketServerSideEncryptionConfigurationV2(
    "compliance-reports-encryption",
    bucket=bucket.id,
    rules=[aws.s3.BucketServerSideEncryptionConfigurationV2RuleArgs(
        apply_server_side_encryption_by_default=aws.s3.BucketServerSideEncryptionConfigurationV2RuleApplyServerSideEncryptionByDefaultArgs(
            sse_algorithm="AES256"
        )
    )]
)

# Block public access
public_access_block = aws.s3.BucketPublicAccessBlock(
    "compliance-reports-pab",
    bucket=bucket.id,
    block_public_acls=True,
    block_public_policy=True,
    ignore_public_acls=True,
    restrict_public_buckets=True
)

# Export bucket name
pulumi.export("bucket_name", bucket.id)
```

### Run Pulumi

```bash
# Initialize (creates project)
pulumi new aws-python

# Preview changes
pulumi preview

# Deploy
pulumi up

# Destroy
pulumi destroy
```

## Building VPC with Pulumi

```python
import pulumi
import pulumi_aws as aws

config = pulumi.Config()
vpc_cidr = config.get("vpc_cidr") or "10.0.0.0/16"
environment = config.get("environment") or "production"

# VPC
vpc = aws.ec2.Vpc(
    "main-vpc",
    cidr_block=vpc_cidr,
    enable_dns_hostnames=True,
    enable_dns_support=True,
    tags={
        "Name": f"{environment}-vpc"
    }
)

# Internet Gateway
igw = aws.ec2.InternetGateway(
    "main-igw",
    vpc_id=vpc.id,
    tags={
        "Name": f"{environment}-igw"
    }
)

# Public Subnet
public_subnet = aws.ec2.Subnet(
    "public-subnet",
    vpc_id=vpc.id,
    cidr_block="10.0.1.0/24",
    availability_zone="us-east-1a",
    map_public_ip_on_launch=True,
    tags={
        "Name": f"{environment}-public-subnet"
    }
)

# Private Subnet
private_subnet = aws.ec2.Subnet(
    "private-subnet",
    vpc_id=vpc.id,
    cidr_block="10.0.2.0/24",
    availability_zone="us-east-1a",
    tags={
        "Name": f"{environment}-private-subnet"
    }
)

# Elastic IP for NAT
eip = aws.ec2.Eip(
    "nat-eip",
    domain="vpc",
    tags={
        "Name": f"{environment}-nat-eip"
    }
)

# NAT Gateway
nat_gw = aws.ec2.NatGateway(
    "main-nat",
    allocation_id=eip.id,
    subnet_id=public_subnet.id,
    tags={
        "Name": f"{environment}-nat"
    }
)

# Public Route Table
public_rt = aws.ec2.RouteTable(
    "public-rt",
    vpc_id=vpc.id,
    routes=[
        aws.ec2.RouteTableRouteArgs(
            cidr_block="0.0.0.0/0",
            gateway_id=igw.id
        )
    ],
    tags={
        "Name": f"{environment}-public-rt"
    }
)

# Private Route Table
private_rt = aws.ec2.RouteTable(
    "private-rt",
    vpc_id=vpc.id,
    routes=[
        aws.ec2.RouteTableRouteArgs(
            cidr_block="0.0.0.0/0",
            nat_gateway_id=nat_gw.id
        )
    ],
    tags={
        "Name": f"{environment}-private-rt"
    }
)

# Route Table Associations
public_rta = aws.ec2.RouteTableAssociation(
    "public-rta",
    subnet_id=public_subnet.id,
    route_table_id=public_rt.id
)

private_rta = aws.ec2.RouteTableAssociation(
    "private-rta",
    subnet_id=private_subnet.id,
    route_table_id=private_rt.id
)

# Export outputs
pulumi.export("vpc_id", vpc.id)
pulumi.export("public_subnet_id", public_subnet.id)
pulumi.export("private_subnet_id", private_subnet.id)
```

## Security Best Practices

### 1. Use Remote State

Store Terraform state remotely (S3, not local):

```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "compliance-tool/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}
```

### 2. Enable State Locking

Prevent concurrent modifications:

```hcl
terraform {
  backend "s3" {
    # ... other config ...
    dynamodb_table = "terraform-state-lock"
  }
}
```

### 3. Use Variables, Not Hardcoded Values

**Bad:**
```hcl
resource "aws_s3_bucket" "bucket" {
  bucket = "my-hardcoded-bucket-name"
}
```

**Good:**
```hcl
variable "bucket_name" {
  type = string
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
}
```

### 4. Scan Infrastructure Code

Use tools like `tfsec` or `checkov`:

```bash
# Install tfsec
brew install tfsec

# Scan Terraform code
tfsec .
```

### 5. Use Modules

Reusable components:

```hcl
module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr = "10.0.0.0/16"
  environment = "production"
}
```

## Key Takeaways

1. **IaC = Infrastructure as Code** - Manage infrastructure with code
2. **Terraform = HCL** - Declarative, popular
3. **Pulumi = Real Languages** - More flexible
4. **Version Control** - Track all changes
5. **Reproducible** - Same infrastructure every time
6. **Secure State** - Store state remotely, encrypted
7. **Scan Code** - Use security scanning tools

## Practice Exercise

Try this yourself:

1. Install Terraform
2. Create a simple S3 bucket with Terraform
3. Add encryption and public access block
4. Deploy it
5. Modify it
6. Destroy it

## Resources to Learn More

- [Terraform Documentation](https://www.terraform.io/docs)
- [Pulumi Documentation](https://www.pulumi.com/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## What's Next?

Now that you understand IaC, you're ready to:
- Build complete infrastructure stacks
- Version control your infrastructure
- Automate deployments

Remember: Infrastructure as Code is about treating infrastructure like software. Version it, test it, review it!

> **💡 Pro Tip:** Start small with Terraform. Create one resource (like an S3 bucket), understand how it works, then gradually build more complex infrastructure. Don't try to recreate your entire AWS account on day one!

---

*Ready to understand compliance? Check out our final post on Compliance Frameworks, where we'll learn about SOC 2, ISO 27001, and NIST!*

