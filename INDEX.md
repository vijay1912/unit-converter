# 🚀 Unit Converter - EKS Deployment Index

## Quick Navigation

### 📖 Start Here
- **[SETUP_COMPLETE.md](./SETUP_COMPLETE.md)** ← **START HERE** for complete overview and architecture

### 🔧 Step-by-Step Guides
1. **[DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)** - Complete step-by-step deployment instructions
2. **[README_K8S_DEPLOYMENT.md](./README_K8S_DEPLOYMENT.md)** - Detailed Kubernetes deployment guide
3. **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)** - Command cheat sheet for daily operations

### 📊 Visualizations & Understanding
- **[DEPLOYMENT_WORKFLOW.md](./DEPLOYMENT_WORKFLOW.md)** - Visual diagrams and workflows

---

## 🎯 Quick Start (TL;DR)

### 1. Deploy EKS Infrastructure
```bash
cd eks-terraform
terraform init
terraform apply
```

### 2. Configure kubectl
```bash
aws eks update-kubeconfig --region us-east-1 --name unit-converter-eks
```

### 3. Deploy Application (Choose One)
```bash
# Linux/Mac
./deploy.sh

# Windows PowerShell
.\deploy.ps1

# Or manual kubectl
kubectl apply -f k8s/
```

### 4. Access Application
```bash
kubectl get service unit-converter-service -n unit-converter
# Wait for EXTERNAL-IP, then: http://<EXTERNAL-IP>
```

---

## 📁 Directory Structure

### Infrastructure
- **eks-terraform/** - Terraform configuration for EKS cluster with EC2 worker nodes
  - `main.tf` - EKS cluster, VPC, subnets, security groups, EC2 nodes
  - `variables.tf` - Input variables
  - `outputs.tf` - Output values
  - `terraform.tfvars` - Configuration values

### Kubernetes Manifests (Pure YAML - No Helm)
- **k8s/** - Kubernetes manifests for deploying the application
  - `namespace.yaml` - Application namespace
  - `serviceaccount.yaml` - Pod service account
  - `role.yaml` - RBAC role
  - `rolebinding.yaml` - RBAC role binding
  - `configmap.yaml` - Application configuration
  - `deployment.yaml` - Application deployment
  - `service.yaml` - LoadBalancer service
  - `hpa.yaml` - Horizontal Pod Autoscaler
  - `pdb.yaml` - Pod Disruption Budget

### Deployment Scripts
- **deploy.sh** - Automated deployment script for Linux/Mac
- **deploy.ps1** - Automated deployment script for Windows PowerShell
- **deploy.bat** - Windows batch runner

### Application
- **Dockerfile** - Multi-stage Docker build for container image
- **pom.xml** - Maven configuration
- **src/** - Application source code

---

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| **SETUP_COMPLETE.md** | Overview, architecture, configuration options |
| **DEPLOYMENT_GUIDE.md** | Complete step-by-step deployment instructions |
| **README_K8S_DEPLOYMENT.md** | Detailed Kubernetes deployment guide |
| **QUICK_REFERENCE.md** | Command cheat sheet |
| **DEPLOYMENT_WORKFLOW.md** | Visual diagrams and workflows |
| **INDEX.md** | This file |

---

## 🔑 Key Features

✅ **Terraform Infrastructure**
- EKS Cluster (Kubernetes 1.29)
- EC2 Worker Nodes (t3.medium, 2-4 autoscaling)
- VPC with public and private subnets
- NAT Gateways for private subnet internet access
- Security groups and IAM roles
- CloudWatch logs

✅ **Pure Kubernetes YAML** (No Helm, No Templates, No Values)
- All standard Kubernetes YAML manifests
- Namespace isolation
- RBAC (ServiceAccount, Role, RoleBinding)
- Deployment with 2 replicas
- Pod anti-affinity spreading
- Health checks (liveness & readiness)
- LoadBalancer service
- Horizontal Pod Autoscaler (2-5 replicas)
- Pod Disruption Budget

✅ **High Availability**
- Multi-AZ deployment
- Pod anti-affinity spreading
- Node autoscaling
- Pod disruption budget
- Health checks and probes

✅ **Auto-Scaling**
- Horizontal Pod Autoscaler (HPA)
- Node group autoscaling
- Adjustable thresholds

✅ **Production-Ready**
- Resource limits
- Health monitoring
- Proper security configuration
- CloudWatch integration
- Logging and monitoring ready

---

## 🚀 Three Ways to Deploy

### 1. Automated Script (Recommended)

**Linux/Mac:**
```bash
chmod +x deploy.sh
./deploy.sh
```

**Windows PowerShell:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\deploy.ps1
```

### 2. Manual kubectl Apply

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

### 3. Step-by-Step Following Documentation

Follow [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) for detailed instructions.

---

## 💡 Common Commands

```bash
# View status
kubectl get all -n unit-converter

# View logs
kubectl logs -n unit-converter -l app=unit-converter -f

# Get service endpoint
kubectl get service unit-converter-service -n unit-converter

# Scale pods
kubectl scale deployment unit-converter-app -n unit-converter --replicas=3

# Update image
kubectl set image deployment/unit-converter-app \
  unit-converter=YOUR-ECR-IMAGE:tag \
  -n unit-converter

# View HPA status
kubectl get hpa -n unit-converter
```

See [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) for complete command list.

---

## 🔄 Workflow Overview

```
Code (pom.xml + src/)
    ↓
Dockerfile (Build container)
    ↓
Amazon ECR (Container registry)
    ↓
Terraform (eks-terraform/)
    ↓ Applies
EKS Cluster + EC2 Nodes
    ↓
Kubernetes Manifests (k8s/)
    ↓ Apply
Deployment in EKS
    ↓
LoadBalancer Service
    ↓
http://<EXTERNAL-IP>
```

---

## 📊 Architecture

```
AWS Account
└── VPC (10.0.0.0/16)
    ├── Public Subnets (with NAT Gateways)
    └── Private Subnets
        └── EKS Cluster
            ├── Control Plane (AWS Managed)
            └── EC2 Worker Nodes (2-4 instances)
                ├── Pod 1 (8080)
                ├── Pod 2 (8080)
                ├── Pod 3 (8080)
                └── Pod 4 (8080)
                    └── LoadBalancer Service
                        └── Internet (Port 80)
```

---

## 🎯 Configuration

### Change Instance Type
Edit `eks-terraform/terraform.tfvars`:
```hcl
instance_types = ["t3.small"]  # or t3.large, m5.large, etc.
```

### Change Cluster Size
Edit `eks-terraform/terraform.tfvars`:
```hcl
desired_capacity = 3
min_capacity = 2
max_capacity = 6
```

### Change Pod Replicas
Edit `k8s/deployment.yaml`:
```yaml
spec:
  replicas: 3
```

### Change HPA Settings
Edit `k8s/hpa.yaml` for different thresholds and replica counts.

---

## 🔍 Troubleshooting

### Cluster Issues
```bash
kubectl cluster-info
kubectl get nodes
```

### Pod Issues
```bash
kubectl describe pod <pod-name> -n unit-converter
kubectl logs <pod-name> -n unit-converter
```

### Service Issues
```bash
kubectl describe service unit-converter-service -n unit-converter
kubectl get endpoints -n unit-converter
```

See [README_K8S_DEPLOYMENT.md](./README_K8S_DEPLOYMENT.md#troubleshooting) for detailed troubleshooting.

---

## 🧹 Cleanup

### Delete Application
```bash
kubectl delete -f k8s/ -n unit-converter
```

### Destroy Infrastructure
```bash
cd eks-terraform
terraform destroy
```

---

## 📝 Files at a Glance

### Must Read
1. **SETUP_COMPLETE.md** - Start here for complete overview
2. **DEPLOYMENT_GUIDE.md** - Step-by-step guide

### Reference
- **QUICK_REFERENCE.md** - Commands cheat sheet
- **README_K8S_DEPLOYMENT.md** - Detailed guide
- **DEPLOYMENT_WORKFLOW.md** - Visual diagrams

### Code
- **eks-terraform/** - Infrastructure as code (Terraform)
- **k8s/** - Kubernetes manifests
- **Dockerfile** - Container build
- **pom.xml** - Maven configuration

---

## 🎓 Learning Resources

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [Spring Boot Deployment Guide](https://spring.io/guides/gs/spring-boot-docker/)

---

## ✅ Pre-Deployment Checklist

- [ ] AWS CLI configured
- [ ] kubectl installed
- [ ] Terraform installed
- [ ] Docker installed (for building images)
- [ ] AWS credentials with appropriate permissions
- [ ] Read SETUP_COMPLETE.md
- [ ] Reviewed terraform.tfvars values
- [ ] Reviewed k8s manifest files

---

## 🆘 Need Help?

1. Check the relevant documentation file above
2. Review the logs: `kubectl logs -n unit-converter -l app=unit-converter`
3. Check pod status: `kubectl describe pod <pod-name> -n unit-converter`
4. Check node status: `kubectl describe node <node-name>`
5. Check AWS console for EC2 and EKS status

---

**Last Updated:** 2024  
**Version:** 1.0  
**Status:** ✅ Ready for Deployment
