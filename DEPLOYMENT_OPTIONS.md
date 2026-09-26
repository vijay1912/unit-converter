# 🚀 Deployment Options - Choose Your Preferred Method

## Available Deployment Methods

### Option 1: **Pure kubectl (Manual)**
- ✅ No scripts needed
- ✅ Full control
- ✅ Works on any OS
- ⏱️ Slower (more steps)

**How to use:**
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

---

### Option 2: **Bash Script** (`deploy.sh`)
- ✅ Automated
- ✅ Linux/Mac native
- ✅ Colored output
- ✅ Full error handling
- ⏱️ Fast

**How to use:**
```bash
chmod +x deploy.sh
./deploy.sh

# With image update:
./deploy.sh YOUR-ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/unit-converter:latest
```

---

### Option 3: **PowerShell Script** (`deploy.ps1`)
- ✅ Automated
- ✅ Windows native
- ✅ Colored output
- ✅ Full error handling
- ⏱️ Fast

**How to use:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\deploy.ps1

# With image update:
.\deploy.ps1 -ImageUri "YOUR-ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/unit-converter:latest"
```

---

### Option 4: **Python Script** (`deploy.py`) 🆕
- ✅ Automated
- ✅ Cross-platform (Linux/Mac/Windows)
- ✅ Colored output
- ✅ Most flexible
- ✅ Easy to modify
- ⏱️ Very fast

**How to use:**
```bash
# Basic deployment
python3 deploy.py

# With image update
python3 deploy.py --image-uri YOUR-ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/unit-converter:latest

# Custom namespace
python3 deploy.py --namespace custom-ns

# Custom wait time
python3 deploy.py --wait-time 600

# Don't wait for deployment
python3 deploy.py --no-wait

# All options
python3 deploy.py \
  --image-uri YOUR-IMAGE:tag \
  --namespace custom-ns \
  --deployment custom-deploy \
  --service custom-svc \
  --manifest-dir ./k8s \
  --wait-time 600
```

**Features:**
- Cross-platform (Windows, Mac, Linux)
- Colorized output
- Progress tracking
- Timeout handling
- Image update support
- Fully documented

---

### Option 5: **Ruby Script** (`deploy.rb`) 🆕
- ✅ Automated
- ✅ Cross-platform (Linux/Mac/Windows)
- ✅ Colored output
- ✅ OOP design
- ✅ Clean syntax
- ⏱️ Very fast

**How to use:**
```bash
# Basic deployment
ruby deploy.rb

# With image update
ruby deploy.rb --image-uri YOUR-ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/unit-converter:latest

# Custom options
ruby deploy.rb \
  --image-uri YOUR-IMAGE:tag \
  --namespace custom-ns \
  --wait-time 600 \
  --no-wait
```

**Features:**
- Cross-platform (Windows, Mac, Linux)
- Colorized output
- Progress tracking
- Timeout handling
- Image update support

---

### Option 6: **Windows Batch Script** (`deploy.bat`)
- ✅ Automated
- ✅ Windows native
- ✅ No PowerShell needed
- ⏱️ Calls PowerShell script

**How to use:**
```cmd
deploy.bat
```

---

### Option 7: **Docker Container** 🆕
Deploy using Docker (no local tools needed except Docker)

**How to use:**
```bash
# Create Dockerfile for deployment
docker build -f Dockerfile.deploy -t deployer .
docker run --rm \
  -v ~/.kube:/root/.kube \
  -v $(pwd)/k8s:/app/k8s \
  deployer
```

---

### Option 8: **GitHub Actions / CI/CD** 🆕
Automated deployment via GitHub Actions

**How to use:**
```bash
# Push to GitHub and Actions runs automatically
git push origin vijay1912-eks-ec2-worker-nodes
```

---

### Option 9: **ArgoCD / GitOps** 🆕
Deploy via ArgoCD for continuous deployment

**How to use:**
```bash
# ArgoCD watches the repository and deploys automatically
argocd app create unit-converter \
  --repo https://github.com/vijay1912/unit-converter \
  --path k8s \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace unit-converter
```

---

### Option 10: **Kustomize** 🆕
Use Kustomize for dynamic manifest management

**How to use:**
```bash
# Deploy with Kustomize
kustomize build k8s | kubectl apply -f -

# Or directly
kubectl apply -k k8s
```

---

### Option 11: **Skaffold** 🆕
Development workflow with automatic redeployment

**How to use:**
```bash
# Install Skaffold
curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64
chmod +x skaffold

# Deploy with Skaffold
skaffold run
```

---

### Option 12: **Tilt** 🆕
Local development environment with live reload

**How to use:**
```bash
# Install Tilt
curl -fsSL https://raw.githubusercontent.com/tilt-dev/tilt/master/scripts/install.sh | bash

# Create Tiltfile (in repo root)
tilt up
```

---

## 📊 Comparison Table

| Method | OS Support | Ease | Speed | Features | Setup |
|--------|-----------|------|-------|----------|-------|
| **kubectl** | All | Easy | Slow | Basic | None |
| **Bash** | Mac/Linux | Medium | Fast | Full | Chmod |
| **PowerShell** | Windows | Medium | Fast | Full | Policy |
| **Python** | All | Medium | Fast | Full | Python 3 |
| **Ruby** | All | Medium | Fast | Full | Ruby |
| **Batch** | Windows | Easy | Fast | Full | None |
| **Docker** | All | Hard | Fast | Isolated | Docker |
| **GitHub Actions** | All | Hard | Fast | CI/CD | GitHub |
| **ArgoCD** | All | Hard | Continuous | GitOps | ArgoCD |
| **Kustomize** | All | Medium | Fast | Advanced | Kustomize |
| **Skaffold** | All | Medium | Fast | Dev | Skaffold |
| **Tilt** | All | Medium | Fast | Dev | Tilt |

---

## 🎯 Recommendations

### For Quick Deployment:
→ **Python** (`deploy.py`) or **Bash** (`deploy.sh`)

### For Windows Users:
→ **PowerShell** (`deploy.ps1`) or **Python** (`deploy.py`)

### For Production CI/CD:
→ **GitHub Actions** or **ArgoCD**

### For Development:
→ **Tilt** or **Skaffold**

### For Maximum Control:
→ **Kustomize** or **Pure kubectl**

### For Isolation:
→ **Docker Container**

---

## 🔧 Currently Available

✅ **Already Created:**
1. Pure kubectl (manual)
2. Bash script (`deploy.sh`)
3. PowerShell script (`deploy.ps1`)
4. Python script (`deploy.py`) ⭐ NEW
5. Ruby script (`deploy.rb`) ⭐ NEW
6. Windows Batch (`deploy.bat`)

---

## 🚀 Want More Options?

Let me know which of these you'd like me to create:

- [ ] Docker deployment container
- [ ] GitHub Actions workflow
- [ ] ArgoCD configuration
- [ ] Kustomize configuration
- [ ] Skaffold configuration
- [ ] Tilt configuration
- [ ] Ansible playbook
- [ ] Go CLI tool
- [ ] Node.js/TypeScript deployment tool
- [ ] Make targets (Makefile)

---

## ⚡ Quick Start Guide

### Step 1: Choose Your Method
Pick from the options above based on your preferences

### Step 2: Deploy Infrastructure
```bash
cd eks-terraform
terraform init
terraform apply
```

### Step 3: Configure kubectl
```bash
aws eks update-kubeconfig --region us-east-1 --name unit-converter-eks
```

### Step 4: Run Your Chosen Deployment Method
Pick one and execute it

### Step 5: Access Application
```bash
kubectl get service unit-converter-service -n unit-converter
```

---

## 📝 File Locations

All deployment scripts are in the root directory:

```
├── deploy.sh        (Bash - Linux/Mac)
├── deploy.ps1       (PowerShell - Windows)
├── deploy.bat       (Batch - Windows)
├── deploy.py        (Python - All platforms)
├── deploy.rb        (Ruby - All platforms)
└── k8s/             (Kubernetes manifests)
    ├── namespace.yaml
    ├── serviceaccount.yaml
    ├── role.yaml
    ├── rolebinding.yaml
    ├── configmap.yaml
    ├── deployment.yaml
    ├── service.yaml
    ├── hpa.yaml
    └── pdb.yaml
```

---

**Questions? Check INDEX.md for complete navigation!**
