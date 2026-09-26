# Unit Converter - Kubernetes Deployment (Non-Helm)

This guide explains how to deploy the Unit Converter application to EKS using pure Kubernetes manifests (no Helm, no charts, no templates).

## Prerequisites

Before deploying, ensure you have:
- AWS CLI configured with credentials
- `kubectl` installed and configured
- Access to an EKS cluster (already created via Terraform)
- Docker installed (for building images)

## Project Structure

```
├── eks-terraform/          # Terraform configuration for EKS infrastructure
│   ├── main.tf            # EKS cluster and EC2 worker nodes
│   ├── variables.tf       # Variable definitions
│   ├── outputs.tf         # Output values
│   └── terraform.tfvars   # Terraform values
│
├── k8s/                   # Pure Kubernetes YAML manifests
│   ├── namespace.yaml           # Kubernetes namespace
│   ├── serviceaccount.yaml      # Service account for pods
│   ├── role.yaml                # RBAC role
│   ├── rolebinding.yaml         # Role binding
│   ├── configmap.yaml           # Application configuration
│   ├── deployment.yaml          # Application deployment
│   ├── service.yaml             # Kubernetes service
│   ├── hpa.yaml                 # Horizontal Pod Autoscaler
│   └── pdb.yaml                 # Pod Disruption Budget
│
├── Dockerfile             # Container image build
├── deploy.sh             # Bash deployment script
├── deploy.ps1            # PowerShell deployment script
├── pom.xml               # Maven configuration
└── src/                  # Application source code
```

## Quick Start

### Step 1: Create EKS Cluster (Terraform)

```bash
cd eks-terraform

# Initialize Terraform
terraform init

# Review and apply
terraform plan
terraform apply

# Get kubectl configuration command
terraform output configure_kubectl
```

### Step 2: Configure kubectl

```bash
# Use the output from Terraform
aws eks update-kubeconfig \
  --region us-east-1 \
  --name unit-converter-eks

# Verify connection
kubectl cluster-info
```

### Step 3: Deploy Application Using Pure Kubernetes Manifests

#### Option A: Using Automated Deployment Script (Recommended)

**On Linux/Mac:**
```bash
chmod +x deploy.sh
./deploy.sh
```

**On Windows (PowerShell):**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\deploy.ps1
```

#### Option B: Manual Kubectl Apply

Deploy all manifests in order:

```bash
cd k8s

# Create namespace and RBAC
kubectl apply -f namespace.yaml
kubectl apply -f serviceaccount.yaml
kubectl apply -f role.yaml
kubectl apply -f rolebinding.yaml

# Create configuration
kubectl apply -f configmap.yaml

# Deploy application
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Add autoscaling
kubectl apply -f hpa.yaml
kubectl apply -f pdb.yaml
```

## What Each Manifest Does

### namespace.yaml
- Creates the `unit-converter` namespace
- All application resources are isolated in this namespace

### serviceaccount.yaml
- Creates a service account for pod authentication
- Pods use this account to access Kubernetes resources

### role.yaml
- Defines permissions for reading ConfigMaps and Secrets
- Used by RBAC for authorization

### rolebinding.yaml
- Binds the role to the service account
- Grants the service account the defined permissions

### configmap.yaml
- Stores application configuration
- Can be mounted as files or environment variables
- Current: Spring Boot application properties

### deployment.yaml
- Defines how to deploy the application
- Configures replicas (2 initial)
- Sets up probes (liveness and readiness)
- Defines resource requests and limits
- Anti-affinity: spreads pods across nodes

### service.yaml
- Exposes the application
- Type: LoadBalancer (creates AWS NLB)
- Maps port 80 to container port 8080

### hpa.yaml
- Horizontal Pod Autoscaler
- Scales pods based on CPU (70%) and memory (80%)
- Min replicas: 2, Max replicas: 5

### pdb.yaml
- Pod Disruption Budget
- Ensures at least 1 pod is always running
- Prevents accidental disruption during node maintenance

## Common Operations

### View Deployment Status

```bash
# Check deployment
kubectl get deployment -n unit-converter
kubectl describe deployment unit-converter-app -n unit-converter

# Check pods
kubectl get pods -n unit-converter
kubectl describe pod <pod-name> -n unit-converter

# Check service
kubectl get service -n unit-converter
```

### View Logs

```bash
# Stream logs from all pods
kubectl logs -n unit-converter -l app=unit-converter -f

# View specific pod logs
kubectl logs -n unit-converter <pod-name>

# View previous pod logs (if crashed)
kubectl logs -n unit-converter <pod-name> --previous
```

### Access the Application

```bash
# Get LoadBalancer endpoint
kubectl get service unit-converter-service -n unit-converter

# Wait for external endpoint (may take 2-3 minutes)
kubectl get service unit-converter-service -n unit-converter --watch

# Once you have the external IP/hostname
curl http://<EXTERNAL-IP>
```

### Scale Manually

```bash
# Scale to specific number of replicas
kubectl scale deployment unit-converter-app \
  -n unit-converter \
  --replicas=3

# Check scaling
kubectl get pods -n unit-converter --watch
```

### Check HPA Status

```bash
# View autoscaler status
kubectl get hpa -n unit-converter
kubectl describe hpa unit-converter-hpa -n unit-converter

# View metrics
kubectl top nodes
kubectl top pods -n unit-converter
```

### Update Application Image

If you've built a new Docker image:

```bash
# Update the image (replace with your actual image)
kubectl set image deployment/unit-converter-app \
  unit-converter=<AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/unit-converter:latest \
  -n unit-converter \
  --record

# Check rollout status
kubectl rollout status deployment/unit-converter-app -n unit-converter

# View rollout history
kubectl rollout history deployment/unit-converter-app -n unit-converter
```

### Rollback to Previous Version

```bash
# View rollout history
kubectl rollout history deployment/unit-converter-app -n unit-converter

# Rollback to previous revision
kubectl rollout undo deployment/unit-converter-app -n unit-converter

# Rollback to specific revision
kubectl rollout undo deployment/unit-converter-app \
  --to-revision=2 \
  -n unit-converter
```

## Updating ConfigMap Without Redeploying

To update application configuration without rebuilding the image:

```bash
# Edit ConfigMap
kubectl edit configmap unit-converter-config -n unit-converter

# Or apply updated YAML
kubectl apply -f k8s/configmap.yaml

# Force pod restart to load new config
kubectl rollout restart deployment/unit-converter-app -n unit-converter
```

## Debugging

### Pod Logs Not Showing

```bash
# Check pod events
kubectl describe pod <pod-name> -n unit-converter

# Check pod status
kubectl get pod <pod-name> -n unit-converter -o yaml

# Check node logs (SSH to node)
aws ec2 describe-console-output --instance-id <instance-id>
```

### Service Endpoint Not Loading

```bash
# Check service endpoints
kubectl get endpoints unit-converter-service -n unit-converter

# Check if pods are running
kubectl get pods -n unit-converter

# Describe the service
kubectl describe service unit-converter-service -n unit-converter
```

### Network Connectivity Issues

```bash
# Deploy a debug pod
kubectl run -it --rm debug \
  --image=alpine:latest \
  --restart=Never \
  -n unit-converter \
  -- sh

# Inside debug pod:
# Test DNS
nslookup unit-converter-service.unit-converter.svc.cluster.local

# Test connectivity
wget -O- http://unit-converter-service:80
```

## Cleanup

### Delete All Kubernetes Resources

```bash
# Delete specific resources
kubectl delete -f k8s/ -n unit-converter

# Or delete entire namespace (deletes all resources in it)
kubectl delete namespace unit-converter
```

### Destroy EKS Infrastructure

```bash
cd eks-terraform

# Review what will be deleted
terraform plan -destroy

# Delete all infrastructure
terraform destroy
```

### Delete ECR Repository

```bash
aws ecr delete-repository \
  --repository-name unit-converter \
  --region us-east-1 \
  --force
```

## Best Practices

1. **Resource Limits**: Always define CPU and memory requests/limits
2. **Health Checks**: Use liveness and readiness probes
3. **Pod Disruption Budgets**: Ensure availability during maintenance
4. **Anti-Affinity**: Spread pods across nodes for resilience
5. **ConfigMaps**: Use ConfigMaps for non-sensitive configuration
6. **Secrets**: Use Kubernetes Secrets for sensitive data (not implemented in basic setup)
7. **Namespaces**: Isolate applications in different namespaces
8. **RBAC**: Use minimal necessary permissions
9. **Monitoring**: Add monitoring and logging (e.g., CloudWatch, Prometheus)
10. **Network Policies**: Restrict traffic between pods if needed

## Adding New Replicas or Changing Configuration

Edit the YAML files directly:

### Change Deployment Replicas

Edit `k8s/deployment.yaml`:
```yaml
spec:
  replicas: 3  # Change this number
```

Then apply:
```bash
kubectl apply -f k8s/deployment.yaml
```

### Change HPA Settings

Edit `k8s/hpa.yaml` to adjust:
- `minReplicas`: Minimum pods
- `maxReplicas`: Maximum pods
- CPU utilization threshold
- Memory utilization threshold

Then apply:
```bash
kubectl apply -f k8s/hpa.yaml
```

### Change Resource Limits

Edit `k8s/deployment.yaml` in the `resources` section:
```yaml
resources:
  requests:
    cpu: 250m
    memory: 512Mi
  limits:
    cpu: 500m
    memory: 1Gi
```

## Monitoring and Metrics

### View Resource Usage

```bash
# Node metrics
kubectl top nodes

# Pod metrics
kubectl top pods -n unit-converter

# Pod metrics with labels
kubectl top pods -n unit-converter -l app=unit-converter
```

### CloudWatch Integration

View EKS cluster logs in CloudWatch:
```bash
# List log streams
aws logs describe-log-streams \
  --log-group-name "/aws/eks/unit-converter-eks/cluster" \
  --region us-east-1

# View logs
aws logs tail "/aws/eks/unit-converter-eks/cluster" --follow
```

## Troubleshooting Checklist

- [ ] EKS cluster is running: `kubectl cluster-info`
- [ ] EC2 nodes are ready: `kubectl get nodes`
- [ ] Namespace exists: `kubectl get namespace unit-converter`
- [ ] Pods are running: `kubectl get pods -n unit-converter`
- [ ] Service has endpoints: `kubectl get endpoints -n unit-converter`
- [ ] LoadBalancer has external IP: `kubectl get service -n unit-converter`
- [ ] Pod logs show no errors: `kubectl logs -n unit-converter -l app=unit-converter`
- [ ] Resources are available: `kubectl top nodes` and `kubectl top pods -n unit-converter`

## Support

For issues:
1. Check pod logs: `kubectl logs -n unit-converter -l app=unit-converter`
2. Describe problematic pod: `kubectl describe pod <name> -n unit-converter`
3. Check node status: `kubectl describe node <node-name>`
4. Review AWS console for EC2 and EKS status
