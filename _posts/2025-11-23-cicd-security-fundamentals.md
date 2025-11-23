---
layout: post
title: "CI/CD Security: Building Secure Deployment Pipelines"
date: 2025-11-22 10:00:00 -0400
categories: [CI/CD, DevSecOps, Security]
tags: [cicd, devsecops, security, github-actions, gitlab-ci, jenkins, automation]
image: https://placehold.co/1000x400/2088FF/FFFFFF?text=CI%2FCD+Security
excerpt: "CI/CD (Continuous Integration/Continuous Deployment) pipelines automate your software delivery. But automation without security is dangerous. Let's learn how to build secure pipelines that scan code, test security, and deploy safely."
---

> **The challenge:** You've built an amazing application. Now you need to deploy it. Manually deploying is slow and error-prone. CI/CD automates this. But here's the problem: if your pipeline isn't secure, attackers can inject malicious code, steal secrets, or deploy vulnerable software. Let's learn how to build secure CI/CD pipelines.

## What is CI/CD, Really?

**CI/CD** stands for:
- **CI (Continuous Integration)** - Automatically build and test code when changes are pushed
- **CD (Continuous Deployment)** - Automatically deploy code that passes tests

**Think of it like this:**
- **Without CI/CD:** Write code → Manually test → Manually deploy → Hope it works
- **With CI/CD:** Write code → Push to Git → Pipeline automatically tests → Automatically deploys if tests pass

**The security problem:** If your pipeline isn't secure, it becomes an attack vector. Attackers can:
- Inject malicious code
- Steal secrets (API keys, passwords)
- Deploy backdoors
- Access production systems

## CI/CD Security Principles

### 1. Shift Left Security

**"Shift left"** means adding security early in the development process, not at the end.

**Bad approach:**
```
Code → Deploy → Security Review → Oops, found vulnerabilities!
```

**Good approach:**
```
Code → Security Scan → Fix Issues → Deploy
```

### 2. Least Privilege

Give your pipeline only the permissions it needs, nothing more.

### 3. Secrets Management

Never hardcode secrets. Use secret management systems.

### 4. Code Scanning

Automatically scan code for vulnerabilities before deployment.

## GitHub Actions: Secure Pipeline Example

Here's a secure CI/CD pipeline for the compliance tool:

### .github/workflows/ci-cd.yml

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  PYTHON_VERSION: '3.11'
  DOCKER_IMAGE: compliance-tool

jobs:
  # Job 1: Code Quality Checks
  code-quality:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ env.PYTHON_VERSION }}
      
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install pylint flake8
      
      - name: Run Pylint
        run: pylint **/*.py --fail-under=7.0
      
      - name: Run Flake8
        run: flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics

  # Job 2: Security Scanning
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Run Bandit (SAST)
        uses: securecodewarrior/github-action-bandit@v1
        with:
          path: .
          exit_zero: false
      
      - name: Run Safety (Dependency Check)
        run: |
          pip install safety
          safety check --json
      
      - name: Run Trivy (Container Scan)
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'
      
      - name: Upload Trivy results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'

  # Job 3: Run Tests
  test:
    runs-on: ubuntu-latest
    needs: [code-quality, security-scan]
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ env.PYTHON_VERSION }}
      
      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install pytest pytest-cov
      
      - name: Run tests
        run: pytest tests/ --cov=. --cov-report=xml
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage.xml

  # Job 4: Build Docker Image
  build:
    runs-on: ubuntu-latest
    needs: [test]
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: ${{ secrets.DOCKER_USERNAME }}/${{ env.DOCKER_IMAGE }}:latest
          cache-from: type=registry,ref=${{ secrets.DOCKER_USERNAME }}/${{ env.DOCKER_IMAGE }}:buildcache
          cache-to: type=registry,ref=${{ secrets.DOCKER_USERNAME }}/${{ env.DOCKER_IMAGE }}:buildcache,mode=max

  # Job 5: Deploy to Kubernetes
  deploy:
    runs-on: ubuntu-latest
    needs: [build]
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      
      - name: Set up kubectl
        uses: azure/setup-kubectl@v3
      
      - name: Deploy to EKS
        run: |
          aws eks update-kubeconfig --name compliance-cluster
          kubectl set image deployment/compliance-scanner \
            scanner=${{ secrets.DOCKER_USERNAME }}/${{ env.DOCKER_IMAGE }}:latest \
            -n compliance-system
```

## Security Best Practices in CI/CD

### 1. Use Secrets, Never Hardcode

**Bad:**
```yaml
- name: Deploy
  run: |
    aws configure set aws_access_key_id "AKIA..."
    aws configure set aws_secret_access_key "secret..."
```

**Good:**
```yaml
- name: Configure AWS
  uses: aws-actions/configure-aws-credentials@v2
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

### 2. Scan Dependencies

Always scan dependencies for vulnerabilities:

```yaml
- name: Safety check
  run: |
    pip install safety
    safety check --json
```

### 3. Scan Container Images

Scan Docker images before deployment:

```yaml
- name: Trivy scan
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: 'my-image:latest'
    format: 'sarif'
    output: 'trivy-results.sarif'
```

### 4. Use IAM Roles (Better than Access Keys)

For AWS, use OIDC instead of access keys:

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v2
  with:
    role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsRole
    aws-region: us-east-1
```

### 5. Require Approvals for Production

```yaml
deploy-production:
  runs-on: ubuntu-latest
  environment: production  # Requires approval
  steps:
    - name: Deploy
      run: ./deploy.sh
```

## GitLab CI Example

Here's the same pipeline in GitLab CI:

### .gitlab-ci.yml

```yaml
stages:
  - quality
  - security
  - test
  - build
  - deploy

variables:
  DOCKER_IMAGE: compliance-tool
  PYTHON_VERSION: "3.11"

code-quality:
  stage: quality
  image: python:${PYTHON_VERSION}
  script:
    - pip install -r requirements.txt
    - pip install pylint flake8
    - pylint **/*.py --fail-under=7.0
    - flake8 . --count --select=E9,F63,F7,F82
  only:
    - merge_requests
    - main

security-scan:
  stage: security
  image: python:${PYTHON_VERSION}
  script:
    - pip install safety bandit
    - safety check
    - bandit -r . -f json -o bandit-report.json
  artifacts:
    reports:
      sast: bandit-report.json
  only:
    - merge_requests
    - main

test:
  stage: test
  image: python:${PYTHON_VERSION}
  script:
    - pip install -r requirements.txt
    - pip install pytest pytest-cov
    - pytest tests/ --cov=. --cov-report=xml
  coverage: '/TOTAL.*\s+(\d+%)$/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
  only:
    - merge_requests
    - main

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $CI_REGISTRY_IMAGE:latest .
    - docker push $CI_REGISTRY_IMAGE:latest
  only:
    - main

deploy:
  stage: deploy
  image: bitnami/kubectl:latest
  script:
    - kubectl set image deployment/compliance-scanner \
        scanner=$CI_REGISTRY_IMAGE:latest \
        -n compliance-system
  environment:
    name: production
  only:
    - main
  when: manual  # Requires manual approval
```

## Security Scanning Tools

### 1. Bandit (Python SAST)

Scans Python code for security issues:

```bash
pip install bandit
bandit -r . -f json -o bandit-report.json
```

**Finds:**
- Hardcoded passwords
- SQL injection risks
- Insecure random number generation
- And more

### 2. Safety (Dependency Check)

Checks Python dependencies for known vulnerabilities:

```bash
pip install safety
safety check
```

### 3. Trivy (Container Scanning)

Scans Docker images for vulnerabilities:

```bash
trivy image my-image:latest
```

### 4. Snyk (Multi-language)

Scans code, dependencies, and containers:

```bash
snyk test
snyk monitor
```

## Secure Deployment Practices

### 1. Blue-Green Deployment

Deploy to a new environment, test it, then switch traffic:

```yaml
deploy-blue:
  script:
    - kubectl apply -f k8s/blue/
    - ./test-deployment.sh blue
    - kubectl switch blue
```

### 2. Canary Deployment

Deploy to a small percentage, monitor, then roll out:

```yaml
deploy-canary:
  script:
    - kubectl set image deployment/app app=my-image:new -n production
    - kubectl scale deployment/app --replicas=1 -n production
    - sleep 300  # Monitor for 5 minutes
    - kubectl scale deployment/app --replicas=10 -n production
```

### 3. Rollback Strategy

Always have a rollback plan:

```yaml
rollback:
  script:
    - kubectl rollout undo deployment/app -n production
```

## Key Takeaways

1. **CI/CD = Automation** - But must be secure
2. **Shift Left Security** - Scan early, not late
3. **Use Secrets Management** - Never hardcode
4. **Scan Everything** - Code, dependencies, containers
5. **Least Privilege** - Minimal permissions
6. **Require Approvals** - For production deployments
7. **Have Rollback Plans** - Things will break

## Practice Exercise

Try this yourself:

1. Create a GitHub Actions workflow
2. Add code quality checks
3. Add security scanning (Bandit, Safety)
4. Add container scanning (Trivy)
5. Configure secrets properly
6. Add deployment step

## Resources to Learn More

- [GitHub Actions Security](https://docs.github.com/en/actions/security-guides)
- [GitLab CI/CD Security](https://docs.gitlab.com/ee/ci/security/)
- [OWASP CI/CD Security](https://owasp.org/www-project-top-10-ci-cd-security-risks/)

## What's Next?

Now that you understand CI/CD security, you're ready to:
- Build production-ready pipelines
- Integrate security scanning
- Deploy securely to cloud platforms

Remember: Secure CI/CD is about automation AND security. Don't sacrifice one for the other!

> **💡 Pro Tip:** Start with a simple pipeline, then gradually add security checks. Don't try to implement everything at once. Get the basics working first, then enhance security!

---

*Ready to manage infrastructure as code? Check out our next post on Infrastructure as Code, where we'll learn Terraform and Pulumi!*

