# Deployment Workflow - Visual Guide

## Complete Deployment Process

```
┌─────────────────────────────────────────────────────────────┐
│  STEP 1: Build Docker Image                                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  docker build -t unit-converter:latest .                   │
│         ↓                                                   │
│  Push to ECR:                                               │
│  aws ecr get-login-password | docker login ...             │
│  docker push YOUR-ACCOUNT.dkr.ecr.us-east-1...             │
│         ↓                                                   │
│  Image Ready in Amazon ECR                                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 2: Deploy EKS Cluster with Terraform                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  cd eks-terraform                                           │
│  terraform init                                             │
│  terraform plan                                             │
│  terraform apply                                            │
│         ↓                                                   │
│  ✓ VPC Created                                              │
│  ✓ Subnets Created (Public & Private)                      │
│  ✓ EKS Cluster Created                                     │
│  ✓ EC2 Worker Nodes Created (t3.medium x2)                │
│  ✓ IAM Roles & Security Groups Configured                 │
│  ✓ CloudWatch Logs Configured                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 3: Configure kubectl Access                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  aws eks update-kubeconfig \                                │
│    --region us-east-1 \                                     │
│    --name unit-converter-eks                                │
│         ↓                                                   │
│  kubectl cluster-info                                      │
│  kubectl get nodes                                         │
│         ↓                                                   │
│  Cluster Connection Verified ✓                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 4: Deploy Application (Pure K8s YAML)                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Option A: Automated Script                                │
│  ──────────────────────────                                 │
│  chmod +x deploy.sh                                         │
│  ./deploy.sh                                                │
│         ↓                                                   │
│                                                             │
│  Option B: Manual kubectl Apply                            │
│  ──────────────────────────────                             │
│  kubectl apply -f k8s/namespace.yaml                       │
│  kubectl apply -f k8s/serviceaccount.yaml                  │
│  kubectl apply -f k8s/role.yaml                            │
│  kubectl apply -f k8s/rolebinding.yaml                     │
│  kubectl apply -f k8s/configmap.yaml                       │
│  kubectl apply -f k8s/deployment.yaml                      │
│  kubectl apply -f k8s/service.yaml                         │
│  kubectl apply -f k8s/hpa.yaml                             │
│  kubectl apply -f k8s/pdb.yaml                             │
│         ↓                                                   │
│  ✓ Namespace Created                                        │
│  ✓ RBAC Configured                                          │
│  ✓ ConfigMap Created                                        │
│  ✓ Deployment Created (2 pods)                             │
│  ✓ LoadBalancer Service Created                            │
│  ✓ HPA Configured (2-5 replicas)                           │
│  ✓ PDB Configured                                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 5: Verify & Access Application                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  kubectl get pods -n unit-converter                        │
│  kubectl get service -n unit-converter                     │
│  kubectl get hpa -n unit-converter                         │
│         ↓                                                   │
│  Wait for LoadBalancer endpoint (2-3 minutes)              │
│  kubectl get service unit-converter-service \              │
│    -n unit-converter --watch                                │
│         ↓                                                   │
│  curl http://<EXTERNAL-IP>                                 │
│         ↓                                                   │
│  Application is Running! ✓                                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## File Dependencies

```
Main Application Code
        ↓
    pom.xml (Maven config)
        ↓
    Dockerfile (Build container)
        ↓
    Amazon ECR (Container registry)
        ↓
    ┌─────────────────────────────┐
    │  Terraform Infrastructure   │
    │    (eks-terraform/)         │
    │                             │
    │  ├─ main.tf                 │
    │  ├─ variables.tf            │
    │  ├─ outputs.tf              │
    │  └─ terraform.tfvars        │
    │            ↓                │
    │  EKS Cluster + EC2 Nodes    │
    └─────────────────────────────┘
            ↓
    ┌─────────────────────────────┐
    │ Kubernetes Manifests (k8s/) │
    │ (Pure YAML - No Helm)       │
    │                             │
    │  ├─ namespace.yaml          │
    │  ├─ serviceaccount.yaml     │
    │  ├─ role.yaml               │
    │  ├─ rolebinding.yaml        │
    │  ├─ configmap.yaml          │
    │  ├─ deployment.yaml ◄───────┼─── Container image
    │  ├─ service.yaml            │
    │  ├─ hpa.yaml                │
    │  └─ pdb.yaml                │
    │            ↓                │
    │  Application Running        │
    └─────────────────────────────┘
            ↓
    AWS LoadBalancer
        ↓
    http://<EXTERNAL-IP>
```

## Manifest Application Order

```
1. namespace.yaml
   └─ Creates the namespace

2. serviceaccount.yaml
   └─ Creates pod identity

3. role.yaml
   └─ Defines permissions

4. rolebinding.yaml
   └─ Grants permissions (depends on role + serviceaccount)

5. configmap.yaml
   └─ Creates configuration

6. deployment.yaml
   └─ Deploys pods (depends on serviceaccount, configmap)

7. service.yaml
   └─ Exposes pods (depends on deployment)

8. hpa.yaml
   └─ Adds autoscaling (depends on deployment)

9. pdb.yaml
   └─ Ensures availability (depends on deployment)
```

## Infrastructure Layers

```
┌─────────────────────────────────────────────────────────────────┐
│                     AWS Account                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                 VPC (10.0.0.0/16)                         │ │
│  │  ┌────────────────────────────────────────────────────┐  │ │
│  │  │           EKS Cluster Control Plane               │  │ │
│  │  │  (Managed by AWS - No worker nodes needed here)  │  │ │
│  │  └────────────────────────────────────────────────────┘  │ │
│  │                                                           │ │
│  │  ┌──────────────────┐    ┌──────────────────┐           │ │
│  │  │  Public Subnet   │    │  Public Subnet   │           │ │
│  │  │  (10.0.1.0/24)   │    │  (10.0.2.0/24)   │           │ │
│  │  │  - NAT Gateway   │    │  - NAT Gateway   │           │ │
│  │  └──────────────────┘    └──────────────────┘           │ │
│  │                                                           │ │
│  │  ┌──────────────────┐    ┌──────────────────┐           │ │
│  │  │ Private Subnet   │    │ Private Subnet   │           │ │
│  │  │(10.0.101.0/24)   │    │(10.0.102.0/24)   │           │ │
│  │  │                  │    │                  │           │ │
│  │  │ ┌──────────────┐ │    │ ┌──────────────┐ │           │ │
│  │  │ │   EC2 Node   │ │    │ │   EC2 Node   │ │           │ │
│  │  │ │ (t3.medium)  │ │    │ │ (t3.medium)  │ │           │ │
│  │  │ │              │ │    │ │              │ │           │ │
│  │  │ │ Kubelets +   │ │    │ │ Kubelets +   │ │           │ │
│  │  │ │ CRI Runtime  │ │    │ │ CRI Runtime  │ │           │ │
│  │  │ │              │ │    │ │              │ │           │ │
│  │  │ │ ┌──────────┐ │ │    │ │ ┌──────────┐ │ │           │ │
│  │  │ │ │  Pod 1   │ │ │    │ │ │  Pod 3   │ │ │           │ │
│  │  │ │ │(8080)    │ │ │    │ │ │(8080)    │ │ │           │ │
│  │  │ │ └──────────┘ │ │    │ │ └──────────┘ │ │           │ │
│  │  │ │              │ │    │ │              │ │           │ │
│  │  │ │ ┌──────────┐ │ │    │ │ ┌──────────┐ │ │           │ │
│  │  │ │ │  Pod 2   │ │ │    │ │ │  Pod 4   │ │ │           │ │
│  │  │ │ │(8080)    │ │ │    │ │ │(8080)    │ │ │           │ │
│  │  │ │ └──────────┘ │ │    │ │ └──────────┘ │ │           │ │
│  │  │ └──────────────┘ │    │ └──────────────┘ │           │ │
│  │  └──────────────────┘    └──────────────────┘           │ │
│  │           ↓                      ↓                       │ │
│  │  ┌────────────────────────────────────────┐             │ │
│  │  │   LoadBalancer Service (Port 80)       │             │ │
│  │  │   Routes to pods on port 8080          │             │ │
│  │  └────────────────────────────────────────┘             │ │
│  │                    ↓                                     │ │
│  │  ┌────────────────────────────────────────┐             │ │
│  │  │   Internet Gateway                      │             │ │
│  │  │   Public internet access                │             │ │
│  │  └────────────────────────────────────────┘             │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                           ↓
                    Internet Users
                    curl http://app.example.com
```

## Pod Anti-Affinity Strategy

```
Without Anti-Affinity:
┌─────────────────────────────────────────┐
│         Node 1 (Single Failure Point)    │
│  ┌──────────────┐  ┌──────────────┐    │
│  │    Pod 1     │  │    Pod 2     │    │
│  │  (app copy)  │  │  (app copy)  │    │
│  └──────────────┘  └──────────────┘    │
└─────────────────────────────────────────┘
         ↓
    Node 1 Fails
         ↓
    Both Pods Lost ✗


With Anti-Affinity (This Setup):
┌──────────────────┐    ┌──────────────────┐
│     Node 1       │    │     Node 2       │
│  ┌────────────┐  │    │  ┌────────────┐  │
│  │   Pod 1    │  │    │  │   Pod 2    │  │
│  │(app copy)  │  │    │  │(app copy)  │  │
│  └────────────┘  │    │  └────────────┘  │
└──────────────────┘    └──────────────────┘
         ↓                      ↓
    Node 1 Fails          Node 2 Still Running
         ↓                      ↓
    Pod 1 Lost          Pod 2 Handles Traffic ✓
```

## Auto-Scaling Behavior

```
Normal Load (60% CPU):
┌─────────────────────────────────────────┐
│ HPA Status: Normal                      │
│ Current replicas: 2 (min)               │
│ CPU usage: 60% (below 70% threshold)    │
└─────────────────────────────────────────┘


High Load (85% CPU):
┌─────────────────────────────────────────┐
│ HPA Status: Scaling UP                  │
│ CPU usage: 85% (above 70% threshold)    │
│ Scale to: 3 pods (within 1-3 minutes)   │
│ New pods start receiving traffic        │
└─────────────────────────────────────────┘


Very High Load (95% CPU):
┌─────────────────────────────────────────┐
│ HPA Status: Scaling UP                  │
│ CPU usage: 95% (above 70% threshold)    │
│ Scale to: 5 pods (max capacity)         │
│ If still high: Add EC2 nodes (ASG)      │
└─────────────────────────────────────────┘


Low Load (30% CPU):
┌─────────────────────────────────────────┐
│ HPA Status: Scaling DOWN                │
│ CPU usage: 30% (below 70% threshold)    │
│ Wait 5 minutes stabilization period     │
│ Then scale down to 2 pods (min)         │
│ Saves costs ✓                           │
└─────────────────────────────────────────┘
```

## Health Check Flow

```
Pod Start:
  ├─ Container starts
  │   └─ Initializes Spring Boot application
  │       └─ Loads configuration
  │           └─ Connects to databases/caches (if needed)
  │
  └─ Readiness Probe (10s delay, 5s interval)
      ├─ HTTP GET /
      ├─ If OK: Pod marked "Ready"
      │   └─ LoadBalancer routes traffic to pod ✓
      └─ If fails 3x: Pod not ready yet
          └─ LoadBalancer doesn't send traffic ✗

Pod Running:
  └─ Liveness Probe (30s delay, 10s interval)
      ├─ HTTP GET /
      ├─ If OK: Pod is healthy ✓
      └─ If fails 3x: Pod restarted
          └─ Kubelet restarts container
```

## Deployment Process Timeline

```
Time        Event
────────────────────────────────────────────────────────
00:00       terraform apply starts
00:00-00:45 AWS creates VPC, subnets, security groups
00:45-02:00 EKS control plane initializes
02:00-04:00 EC2 nodes launch and join cluster
04:00       Node initialization complete
            ✓ Cluster ready

04:30       kubectl apply -f k8s/ starts
04:31       Namespace created
04:32       ServiceAccount, Role, RoleBinding created
04:33       ConfigMap created
04:35       Deployment created, pods start launching
04:45       Pods pass readiness probes
04:50       LoadBalancer created
05:00-05:15 LoadBalancer provisioned with external IP
05:15       ✓ Application accessible at http://<IP>
```

---

This visual guide helps understand the complete deployment flow from code to running application!
