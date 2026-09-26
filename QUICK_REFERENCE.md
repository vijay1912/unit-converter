# Deployment Quick Reference

## One-Time Setup

```bash
# 1. Create EKS cluster with Terraform
cd eks-terraform
terraform init
terraform apply

# 2. Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name unit-converter-eks

# 3. Deploy application
cd ../k8s
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

## Or Use Automated Script

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

## Daily Operations

### Check Status
```bash
kubectl get all -n unit-converter
kubectl get pods -n unit-converter
kubectl get service -n unit-converter
```

### View Logs
```bash
# All pods
kubectl logs -n unit-converter -l app=unit-converter -f

# Specific pod
kubectl logs -n unit-converter <pod-name> -f
```

### Access Application
```bash
# Get endpoint
kubectl get service unit-converter-service -n unit-converter

# Example response:
# http://a1b2c3d4-1234567890.us-east-1.elb.amazonaws.com
```

### Scale Pods
```bash
# Manual scaling
kubectl scale deployment unit-converter-app -n unit-converter --replicas=3

# Check HPA
kubectl get hpa -n unit-converter
```

### Update Image
```bash
kubectl set image deployment/unit-converter-app \
  unit-converter=YOUR-ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/unit-converter:latest \
  -n unit-converter

# Watch rollout
kubectl rollout status deployment/unit-converter-app -n unit-converter
```

### Restart Pods
```bash
kubectl rollout restart deployment/unit-converter-app -n unit-converter
```

### Rollback
```bash
kubectl rollout history deployment/unit-converter-app -n unit-converter
kubectl rollout undo deployment/unit-converter-app -n unit-converter
```

## Manifests Explained

| File | Purpose |
|------|---------|
| `namespace.yaml` | Creates isolated namespace |
| `serviceaccount.yaml` | Pod identity for auth |
| `role.yaml` | Define permissions |
| `rolebinding.yaml` | Grant role to account |
| `configmap.yaml` | Application config |
| `deployment.yaml` | App deployment config (replicas, resources, probes) |
| `service.yaml` | Expose app (LoadBalancer) |
| `hpa.yaml` | Auto-scale based on CPU/memory |
| `pdb.yaml` | Maintain availability during maintenance |

## Useful Kubectl Commands

```bash
# General
kubectl version
kubectl cluster-info
kubectl get nodes
kubectl get namespaces

# Deployments
kubectl get deployment -n unit-converter
kubectl describe deployment unit-converter-app -n unit-converter
kubectl logs deployment/unit-converter-app -n unit-converter

# Pods
kubectl get pods -n unit-converter
kubectl describe pod <pod-name> -n unit-converter
kubectl logs <pod-name> -n unit-converter
kubectl exec -it <pod-name> -n unit-converter -- bash

# Services
kubectl get service -n unit-converter
kubectl describe service unit-converter-service -n unit-converter
kubectl get endpoints -n unit-converter

# Scaling & Autoscaling
kubectl scale deployment unit-converter-app --replicas=3 -n unit-converter
kubectl get hpa -n unit-converter

# Updates
kubectl set image deployment/unit-converter-app <container>=<image> -n unit-converter
kubectl rollout status deployment/unit-converter-app -n unit-converter
kubectl rollout history deployment/unit-converter-app -n unit-converter

# Resource monitoring
kubectl top nodes
kubectl top pods -n unit-converter
```

## Troubleshooting

```bash
# Check pod events
kubectl describe pod <pod-name> -n unit-converter

# View pod YAML
kubectl get pod <pod-name> -n unit-converter -o yaml

# Stream all logs
kubectl logs -n unit-converter -l app=unit-converter --all-containers=true -f

# Check resource availability
kubectl top nodes
kubectl top pods -n unit-converter

# Verify service endpoints
kubectl get endpoints unit-converter-service -n unit-converter
```

## Cleanup

```bash
# Delete application resources
kubectl delete -f k8s/ -n unit-converter

# Delete entire namespace
kubectl delete namespace unit-converter

# Destroy EKS infrastructure
cd eks-terraform
terraform destroy
```
