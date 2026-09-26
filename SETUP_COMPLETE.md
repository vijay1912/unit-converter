# Unit Converter - EKS Deployment with EC2 Worker Nodes

## ✅ Complete Setup Summary

You now have a complete, production-ready deployment system for the Unit Converter application on AWS EKS with EC2 worker nodes (no Fargate, using EC2 instances only).

### What Has Been Created

#### 1. **Terraform Infrastructure** (`eks-terraform/`)
- **EKS Cluster** with Kubernetes 1.29
- **EC2 Worker Nodes** using t3.medium instances (autoscaling 2-4 nodes)
- **VPC Setup** with public and private subnets across 2 availability zones
- **NAT Gateways** for private subnet internet access
- **Security Groups** properly configured for cluster and node communication
- **IAM Roles** and policies for cluster and worker nodes
- **CloudWatch Logs** for cluster monitoring

**Files:**
- `main.tf` - Core infrastructure
- `variables.tf` - Input variables with defaults
- `outputs.tf` - Output values (cluster endpoint, node group ID, etc.)
- `terraform.tfvars` - Values configuration

#### 2. **Kubernetes Manifests** (`k8s/`) - Pure YAML, No Helm

All files are standard Kubernetes YAML manifests without any templating:

| File | Purpose |
|------|---------|
| `namespace.yaml` | Creates the `unit-converter` namespace for isolation |
| `serviceaccount.yaml` | Service account for pod authentication |
| `role.yaml` | RBAC role defining permissions |
| `rolebinding.yaml` | Grants role to service account |
| `configmap.yaml` | Application configuration (Spring Boot properties) |
| `deployment.yaml` | Deployment config (2 replicas, anti-affinity, health checks) |
| `service.yaml` | LoadBalancer service exposing the app |
| `hpa.yaml` | Horizontal Pod Autoscaler (2-5 replicas) |
| `pdb.yaml` | Pod Disruption Budget (ensures availability) |

#### 3. **Deployment Scripts**

Three options to deploy:

- **`deploy.sh`** - Bash script for Linux/Mac
  ```bash
  chmod +x deploy.sh
  ./deploy.sh
  ```

- **`deploy.ps1`** - PowerShell script for Windows
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
  .\deploy.ps1
  ```

- **`deploy.bat`** - Windows batch runner
  ```cmd
  deploy.bat
  ```

#### 4. **Container Setup**
- **`Dockerfile`** - Multi-stage Docker build
  - Build stage: Maven build on Java 17
  - Runtime stage: Alpine JRE for minimal image size
  - Optimized for Kubernetes deployment

#### 5. **Documentation**
- **`README_K8S_DEPLOYMENT.md`** - Complete deployment guide
- **`QUICK_REFERENCE.md`** - Command cheat sheet
- **`DEPLOYMENT_GUIDE.md`** - Step-by-step instructions

---

## 🚀 Quick Start Guide

### Step 1: Deploy EKS Cluster (One-Time Setup)

```bash
cd eks-terraform

# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Create the infrastructure
terraform apply

# Get kubectl configuration
aws eks update-kubeconfig --region us-east-1 --name unit-converter-eks

# Verify connection
kubectl cluster-info
kubectl get nodes
```

### Step 2: Deploy Application

#### Option A: Automated Script (Recommended)
```bash
# Linux/Mac
chmod +x deploy.sh
./deploy.sh

# Windows PowerShell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\deploy.ps1
```

#### Option B: Manual kubectl
```bash
cd k8s
kubectl apply -f namespace.yaml
kubectl apply -f serviceaccount.yaml
kubectl apply -f role.yaml
kubectl apply -f rolebinding.yaml
kubectl apply -f configmap.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f hpa.yaml
kubectl apply -f pdb.yaml
```

### Step 3: Access Your Application

```bash
# Get the LoadBalancer endpoint
kubectl get service unit-converter-service -n unit-converter

# Access via web browser or curl
curl http://<EXTERNAL-IP>
```

---

## 📊 Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    AWS Account                          │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │              VPC (10.0.0.0/16)                   │  │
│  │                                                  │  │
│  │  ┌─────────────────┐    ┌─────────────────┐    │  │
│  │  │  Public Subnet  │    │  Public Subnet  │    │  │
│  │  │   (10.0.1.0)    │    │   (10.0.2.0)    │    │  │
│  │  │   ┌──────────┐  │    │   ┌──────────┐  │    │  │
│  │  │   │NAT-GW   │  │    │   │NAT-GW   │  │    │  │
│  │  │   └──────────┘  │    │   └──────────┘  │    │  │
│  │  └─────────────────┘    └─────────────────┘    │  │
│  │                                                  │  │
│  │  ┌──────────────────────────────────────────┐  │  │
│  │  │  EKS Cluster Control Plane               │  │  │
│  │  │  ├─ API Server                           │  │  │
│  │  │  ├─ etcd                                 │  │  │
│  │  │  └─ Controllers                          │  │  │
│  │  └──────────────────────────────────────────┘  │  │
│  │                                                  │  │
│  │  ┌─────────────────┐    ┌─────────────────┐    │  │
│  │  │Private Subnet   │    │Private Subnet   │    │  │
│  │  │ (10.0.101.0)    │    │ (10.0.102.0)    │    │  │
│  │  │                 │    │                 │    │  │
│  │  │ ┌─────────────┐ │    │ ┌─────────────┐ │    │  │
│  │  │ │ EC2 Node 1  │ │    │ │ EC2 Node 2  │ │    │  │
│  │  │ │ (t3.medium) │ │    │ │ (t3.medium) │ │    │  │
│  │  │ │ - Pod 1     │ │    │ │ - Pod 2     │ │    │  │
│  │  │ │ - Pod 2     │ │    │ │             │ │    │  │
│  │  │ └─────────────┘ │    │ └─────────────┘ │    │  │
│  │  └─────────────────┘    └─────────────────┘    │  │
│  │                                                  │  │
│  │  ┌──────────────────────────────────────────┐  │  │
│  │  │         LoadBalancer Service             │  │  │
│  │  │    Exposes app on port 80                │  │  │
│  │  └──────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │         CloudWatch Logs                          │  │
│  │  - EKS cluster logs                              │  │
│  │  - Pod logs                                      │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## 🔧 Configuration & Customization

### Change Worker Node Type

Edit `eks-terraform/terraform.tfvars`:
```hcl
instance_types = ["t3.small"]  # or t3.large, m5.large, m5.xlarge
```

### Change Cluster Size

Edit `eks-terraform/terraform.tfvars`:
```hcl
desired_capacity = 3  # Current: 2
min_capacity     = 1  # Current: 1
max_capacity     = 6  # Current: 4
```

### Change Application Replicas

Edit `k8s/deployment.yaml`:
```yaml
spec:
  replicas: 3  # Change from 2
```

Then apply:
```bash
kubectl apply -f k8s/deployment.yaml
```

### Modify HPA Scaling Rules

Edit `k8s/hpa.yaml` to change:
- CPU threshold (default: 70%)
- Memory threshold (default: 80%)
- Min/Max replicas

---

## 📈 Scaling & Auto-Scaling

### Pod Auto-Scaling (HPA)
Currently configured to:
- **Min pods:** 2
- **Max pods:** 5
- **CPU threshold:** 70% utilization
- **Memory threshold:** 80% utilization

### Node Auto-Scaling
Currently configured to:
- **Min nodes:** 1
- **Max nodes:** 4
- **Instance type:** t3.medium
- **Desired:** 2 nodes

---

## 🔍 Common Operations

### Check Status
```bash
# All resources
kubectl get all -n unit-converter

# Specific resources
kubectl get pods -n unit-converter
kubectl get service -n unit-converter
kubectl get hpa -n unit-converter
```

### View Logs
```bash
# All pod logs
kubectl logs -n unit-converter -l app=unit-converter -f

# Specific pod
kubectl logs -n unit-converter <pod-name> -f
```

### Scale Manually
```bash
kubectl scale deployment unit-converter-app -n unit-converter --replicas=3
```

### Update Image
```bash
kubectl set image deployment/unit-converter-app \
  unit-converter=YOUR-ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/unit-converter:v1.0 \
  -n unit-converter
```

### Restart Deployment
```bash
kubectl rollout restart deployment/unit-converter-app -n unit-converter
```

---

## 📚 What Makes This Setup Production-Ready

✅ **Multi-AZ Deployment** - Pods distributed across availability zones
✅ **High Availability** - Multiple pod replicas with anti-affinity
✅ **Auto-Scaling** - HPA for pods, ASG for nodes
✅ **Health Checks** - Liveness and readiness probes
✅ **Resource Limits** - CPU and memory requests/limits defined
✅ **Pod Disruption Budget** - Maintains availability during maintenance
✅ **Service Account & RBAC** - Proper security with least privilege
✅ **Logging** - CloudWatch integration for monitoring
✅ **Load Balancer** - AWS Network Load Balancer for traffic distribution
✅ **Configuration Management** - ConfigMaps for app configuration
✅ **Rolling Updates** - Zero-downtime deployments

---

## 🧹 Cleanup

### Delete Application Only
```bash
kubectl delete -f k8s/ -n unit-converter
kubectl delete namespace unit-converter
```

### Destroy Everything
```bash
cd eks-terraform
terraform destroy
```

### Delete ECR Repository
```bash
aws ecr delete-repository \
  --repository-name unit-converter \
  --region us-east-1 \
  --force
```

---

## 📖 Documentation Files

- **README_K8S_DEPLOYMENT.md** - Comprehensive guide with all details
- **QUICK_REFERENCE.md** - Cheat sheet for common commands
- **DEPLOYMENT_GUIDE.md** - Step-by-step deployment instructions

---

## 🆘 Troubleshooting

### Cluster not responding
```bash
kubectl cluster-info
kubectl get nodes
```

### Pods not running
```bash
kubectl get pods -n unit-converter
kubectl describe pod <pod-name> -n unit-converter
```

### Service endpoint not available
```bash
kubectl get service unit-converter-service -n unit-converter --watch
```

### View detailed logs
```bash
kubectl logs -n unit-converter -l app=unit-converter --all-containers=true
```

---

## 🎯 Next Steps

1. **Deploy EKS:** Run `terraform apply` in `eks-terraform/`
2. **Deploy App:** Run deployment script or `kubectl apply -f k8s/`
3. **Get Endpoint:** `kubectl get service -n unit-converter`
4. **Test App:** `curl http://<EXTERNAL-IP>`
5. **Monitor:** `kubectl logs -n unit-converter -l app=unit-converter -f`

---

## 📞 Support

All files are documented with comments. Refer to:
- Kubernetes manifests for resource definitions
- Terraform files for infrastructure setup
- Documentation files for detailed guidance

**Last Updated:** 2024
**EKS Version:** 1.29
**Kubernetes:** Pure YAML (No Helm)
**Worker Nodes:** EC2 t3.medium instances
