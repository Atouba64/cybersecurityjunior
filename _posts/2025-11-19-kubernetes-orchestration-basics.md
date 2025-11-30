---
layout: post
title: "Kubernetes for Security: Orchestrating Containers at Scale"
date: 2025-11-19 10:00:00 -0400
categories: [Kubernetes, DevOps, Cloud Security]
tags: [kubernetes, k8s, containers, orchestration, devops, cloud-security]
image: https://placehold.co/1000x400/326CE5/FFFFFF?text=Kubernetes+Orchestration
excerpt: "You've containerized your security tools with Docker. Great! But what happens when you need to run 100 containers? Or when one crashes? Or when traffic spikes? Kubernetes is the answer - it's like having an intelligent manager for your containerized applications."
---

> **The problem:** You have a compliance scanning tool running in a Docker container. It works great. But what if you need to scan 50 AWS accounts? Or run scans every hour? Or handle failures automatically? Managing containers manually doesn't scale. Kubernetes (K8s) is your solution. It's like having a smart system that manages your containers for you - automatically.

## What is Kubernetes, Really?

Think of Kubernetes like this:

**Without Kubernetes:**
- You manually start containers
- You manually restart them when they crash
- You manually scale up/down
- You manually handle networking
- Lots of manual work

**With Kubernetes:**
- You declare what you want ("I want 3 instances of my scanner")
- Kubernetes makes it happen
- It restarts crashed containers automatically
- It scales based on demand
- It handles networking automatically
- It's self-healing and self-managing

**Real-world analogy:** Kubernetes is like a smart warehouse manager. You say "I need 10 scanners running," and the manager:
- Finds available workers (nodes)
- Assigns them tasks (pods)
- Monitors their health
- Replaces them if they fail
- Balances the workload

## Core Kubernetes Concepts

### Cluster: The Big Picture

A **cluster** is your entire Kubernetes setup. It consists of:
- **Control Plane** (master) - The brain that makes decisions
- **Nodes** (workers) - The machines that run your containers

Think of it as a company:
- Control Plane = Management
- Nodes = Employees doing the work

### Pods: The Smallest Unit

A **pod** is the smallest deployable unit in Kubernetes. It's usually one container, but can contain multiple related containers.

**Key point:** Pods are ephemeral (temporary). They can be created, destroyed, and recreated. Don't store important data in pods!

### Deployments: Managing Pods

A **Deployment** manages a set of pods. It ensures a specified number of pods are running.

**Real-world example:** You want 3 instances of your compliance scanner running. You create a Deployment that says "keep 3 pods running." If one crashes, Kubernetes automatically creates a new one.

### Services: Exposing Pods

A **Service** provides a stable network endpoint for pods. Even if pods are recreated with new IPs, the service provides a consistent address.

**Real-world example:** Your scanner needs to be accessible. You create a Service that gives it a stable IP address and DNS name, even when pods restart.

## Your First Kubernetes Deployment

Let's deploy the compliance scanner to Kubernetes:

### Step 1: Create a Deployment

`deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: compliance-scanner
  labels:
    app: compliance-scanner
spec:
  replicas: 2  # Run 2 instances
  selector:
    matchLabels:
      app: compliance-scanner
  template:
    metadata:
      labels:
        app: compliance-scanner
    spec:
      containers:
      - name: scanner
        image: compliance-tool:latest
        imagePullPolicy: IfNotPresent
        env:
        - name: AWS_ACCESS_KEY_ID
          valueFrom:
            secretKeyRef:
              name: aws-credentials
              key: access-key-id
        - name: AWS_SECRET_ACCESS_KEY
          valueFrom:
            secretKeyRef:
              name: aws-credentials
              key: secret-access-key
        volumeMounts:
        - name: reports
          mountPath: /app/reports
      volumes:
      - name: reports
        persistentVolumeClaim:
          claimName: reports-pvc
```

**Breaking it down:**
- `replicas: 2` - Run 2 instances
- `image: compliance-tool:latest` - The container image
- `env` - Environment variables (from secrets)
- `volumes` - Persistent storage for reports

### Step 2: Create a Service

`service.yaml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: compliance-scanner-service
spec:
  selector:
    app: compliance-scanner
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: ClusterIP  # Internal access only
```

### Step 3: Create a PersistentVolumeClaim (for reports)

`pvc.yaml`:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: reports-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

### Step 4: Create Secrets (for AWS credentials)

```bash
# Create secret from literal values
kubectl create secret generic aws-credentials \
  --from-literal=access-key-id='YOUR_ACCESS_KEY' \
  --from-literal=secret-access-key='YOUR_SECRET_KEY'
```

**⚠️ Security Note:** Never commit secrets to Git! Use Kubernetes secrets or external secret management.

### Step 5: Deploy Everything

```bash
# Apply all configurations
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f pvc.yaml

# Check status
kubectl get pods
kubectl get services
kubectl get pvc
```

**Expected output:**
```
NAME                                READY   STATUS    RESTARTS   AGE
compliance-scanner-7d8f9b4c5-abc12   1/1     Running   0          10s
compliance-scanner-7d8f9b4c5-xyz34   1/1     Running   0          10s
```

## Common Kubernetes Commands

```bash
# Get pods
kubectl get pods

# Get all resources
kubectl get all

# Describe a pod (detailed info)
kubectl describe pod compliance-scanner-abc12

# View logs
kubectl logs compliance-scanner-abc12

# Follow logs (like tail -f)
kubectl logs -f compliance-scanner-abc12

# Execute command in pod
kubectl exec -it compliance-scanner-abc12 -- /bin/bash

# Delete a pod (will be recreated by Deployment)
kubectl delete pod compliance-scanner-abc12

# Scale deployment
kubectl scale deployment compliance-scanner --replicas=5

# Update image
kubectl set image deployment/compliance-scanner scanner=compliance-tool:v2.0

# Rollback update
kubectl rollout undo deployment/compliance-scanner
```

## Scheduled Jobs: CronJobs

Want to run your scanner on a schedule? Use a CronJob:

`cronjob.yaml`:
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: compliance-scanner-cron
spec:
  schedule: "0 2 * * *"  # Run daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: scanner
            image: compliance-tool:latest
            env:
            - name: AWS_ACCESS_KEY_ID
              valueFrom:
                secretKeyRef:
                  name: aws-credentials
                  key: access-key-id
            - name: AWS_SECRET_ACCESS_KEY
              valueFrom:
                secretKeyRef:
                  name: aws-credentials
                  key: secret-access-key
          restartPolicy: OnFailure
```

**Schedule syntax:** `"minute hour day month weekday"`
- `"0 2 * * *"` - Daily at 2 AM
- `"0 */6 * * *"` - Every 6 hours
- `"0 9 * * 1"` - Every Monday at 9 AM

## ConfigMaps: Configuration Management

Store configuration separately from code:

`configmap.yaml`:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: scanner-config
data:
  baseline_checks.json: |
    {
      "iam_policy": {
        "disallow_wildcard_action": true
      },
      "s3_bucket": {
        "require_server_side_encryption": true
      }
    }
  scan_interval: "3600"
```

Use in deployment:
```yaml
containers:
- name: scanner
  image: compliance-tool:latest
  envFrom:
  - configMapRef:
      name: scanner-config
  volumeMounts:
  - name: config
    mountPath: /app/config
volumes:
- name: config
  configMap:
    name: scanner-config
```

## Security Best Practices

### 1. Use Non-Root Users

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
```

### 2. Limit Resources

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

This prevents one pod from consuming all resources.

### 3. Use Network Policies

Control network traffic between pods:

`network-policy.yaml`:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: scanner-policy
spec:
  podSelector:
    matchLabels:
      app: compliance-scanner
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: nginx
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: elasticsearch
    ports:
    - protocol: TCP
      port: 9200
```

### 4. Use Secrets, Not Environment Variables

**Bad:**
```yaml
env:
- name: AWS_SECRET_ACCESS_KEY
  value: "AKIA..."  # DON'T DO THIS!
```

**Good:**
```yaml
env:
- name: AWS_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: aws-credentials
      key: secret-access-key
```

## Complete Production Setup

Here's a production-ready configuration:

### Namespace

`namespace.yaml`:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: compliance-system
```

### Deployment (with all best practices)

`deployment-production.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: compliance-scanner
  namespace: compliance-system
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: compliance-scanner
  template:
    metadata:
      labels:
        app: compliance-scanner
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
      - name: scanner
        image: compliance-tool:1.0.0
        imagePullPolicy: Always
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        env:
        - name: AWS_ACCESS_KEY_ID
          valueFrom:
            secretKeyRef:
              name: aws-credentials
              key: access-key-id
        - name: AWS_SECRET_ACCESS_KEY
          valueFrom:
            secretKeyRef:
              name: aws-credentials
              key: secret-access-key
        volumeMounts:
        - name: reports
          mountPath: /app/reports
        - name: tmp
          mountPath: /tmp
        livenessProbe:
          exec:
            command:
            - python
            - -c
            - "import sys; sys.exit(0)"
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command:
            - python
            - -c
            - "import sys; sys.exit(0)"
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: reports
        persistentVolumeClaim:
          claimName: reports-pvc
      - name: tmp
        emptyDir: {}
```

## Monitoring and Observability

### View Pod Logs

```bash
# All pods
kubectl logs -l app=compliance-scanner

# Specific pod
kubectl logs compliance-scanner-abc12

# Previous container (if crashed)
kubectl logs compliance-scanner-abc12 --previous
```

### Check Resource Usage

```bash
# Top pods by CPU/memory
kubectl top pods

# Top nodes
kubectl top nodes
```

### Describe Resources

```bash
# Get detailed info
kubectl describe pod compliance-scanner-abc12
kubectl describe deployment compliance-scanner
kubectl describe service compliance-scanner-service
```

## Key Takeaways

1. **Kubernetes = Container Orchestration** - Manages containers at scale
2. **Pods = Running Containers** - The actual workloads
3. **Deployments = Pod Managers** - Ensure pods stay running
4. **Services = Network Endpoints** - Expose pods to network
5. **Secrets = Secure Credentials** - Never hardcode secrets
6. **ConfigMaps = Configuration** - Separate config from code
7. **CronJobs = Scheduled Tasks** - Run jobs on schedule
8. **Always use non-root** - Security best practice
9. **Limit resources** - Prevent resource exhaustion
10. **Use namespaces** - Organize resources

## Practice Exercise

Try this yourself:

1. Create a simple deployment with 2 replicas
2. Create a service to expose it
3. Scale it to 5 replicas
4. Create a CronJob that runs hourly
5. Check logs and status

## Resources to Learn More

- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Kubernetes Tutorial](https://kubernetes.io/docs/tutorials/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/security/pod-security-standards/)

## What's Next?

Now that you understand Kubernetes, you're ready to:
- Deploy to cloud Kubernetes (EKS, GKE, AKS)
- Set up CI/CD pipelines
- Monitor and scale applications
- Build production-ready systems

Remember: Kubernetes is powerful but complex. Start simple, learn the basics, then gradually add complexity!

> **💡 Pro Tip:** Use `kubectl explain` to understand any Kubernetes resource. For example: `kubectl explain deployment.spec` shows you all available options for deployments!

---

*Ready to secure your deployments? Check out our next post on CI/CD Security, where we'll learn how to build secure deployment pipelines!*

