# EKS Deployment Guide for Unit Converter

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- kubectl >= 1.24
- Docker for building images
- An AWS ECR repository for storing the container image

## Step 1: Build and Push Docker Image

```bash
# Set your AWS account ID and region
export AWS_ACCOUNT_ID=your-account-id
export AWS_REGION=us-east-1
export ECR_REPO_NAME=unit-converter

# Create ECR repository (if not exists)
aws ecr create-repository \
  --repository-name $ECR_REPO_NAME \
  --region $AWS_REGION

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build Docker image
docker build -t $ECR_REPO_NAME:latest .

# Tag image for ECR
docker tag $ECR_REPO_NAME:latest \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:latest

# Push to ECR
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:latest
```

## Step 2: Deploy EKS Cluster with EC2 Worker Nodes

Navigate to the `eks-terraform` directory and deploy the infrastructure:

```bash
cd eks-terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply

# Get the Terraform outputs
terraform output
```

The Terraform configuration will:
- Create a VPC with public and private subnets across 2 AZs
- Set up NAT Gateways for private subnet internet access
- Create an EKS cluster
- Create EC2 worker nodes (t3.medium by default, 2-4 nodes)
- Configure security groups and IAM roles

## Step 3: Configure kubectl

After the cluster is created, configure kubectl to access your EKS cluster:

```bash
# Get the cluster configuration command from Terraform output
CONFIGURE_CMD=$(terraform output -raw configure_kubectl)
eval $CONFIGURE_CMD

# Or manually:
aws eks update-kubeconfig \
  --region us-east-1 \
  --name unit-converter-eks
```

## Step 4: Verify Cluster Connection

```bash
# Check cluster connectivity
kubectl cluster-info

# View nodes
kubectl get nodes

# Wait for nodes to be in Ready state
kubectl get nodes --watch
```

## Step 5: Deploy Application to Kubernetes

```bash
# Navigate to Kubernetes manifests directory
cd ../k8s

# Create namespace
kubectl apply -f namespace.yaml

# Create ConfigMap
kubectl apply -f configmap.yaml

# Update the deployment.yaml with your ECR image URL
# Replace: your-account-id.dkr.ecr.us-east-1.amazonaws.com/unit-converter:latest
sed -i "s|your-account-id|$AWS_ACCOUNT_ID|g" deployment.yaml

# Deploy the application
kubectl apply -f deployment.yaml

# Create the service
kubectl apply -f service.yaml

# Apply HPA (Horizontal Pod Autoscaler)
kubectl apply -f hpa.yaml

# Apply PDB (Pod Disruption Budget)
kubectl apply -f pdb.yaml
```

## Step 6: Verify Deployment

```bash
# Check deployment status
kubectl get deployment -n unit-converter

# Check pods
kubectl get pods -n unit-converter

# Check service
kubectl get service -n unit-converter

# Get the LoadBalancer endpoint
kubectl get service unit-converter-service -n unit-converter

# Watch pod creation
kubectl get pods -n unit-converter --watch

# Check logs
kubectl logs -n unit-converter -l app=unit-converter --tail=50 -f
```

## Step 7: Access the Application

```bash
# Get the LoadBalancer external IP
EXTERNAL_IP=$(kubectl get service unit-converter-service \
  -n unit-converter \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "Application URL: http://$EXTERNAL_IP"

# Test the endpoint
curl http://$EXTERNAL_IP
```

## Scaling and Monitoring

### Manual Scaling

```bash
# Scale the deployment
kubectl scale deployment unit-converter-app \
  -n unit-converter \
  --replicas=3

# Check HPA status
kubectl get hpa -n unit-converter
```

### View Metrics

```bash
# Check CPU and memory usage
kubectl top nodes
kubectl top pods -n unit-converter
```

### View Logs

```bash
# Stream logs from all pods
kubectl logs -n unit-converter -l app=unit-converter -f

# View logs from specific pod
kubectl logs -n unit-converter unit-converter-app-<pod-id>
```

## Troubleshooting

### Check Node Status

```bash
# Describe nodes
kubectl describe node <node-name>

# Check node system logs
aws ec2 describe-console-output \
  --instance-id <instance-id> \
  --region us-east-1
```

### Check Pod Events

```bash
# Describe pods for events
kubectl describe pod -n unit-converter <pod-name>

# Check resource requests/limits
kubectl describe pod -n unit-converter -l app=unit-converter
```

### Network Troubleshooting

```bash
# Test connectivity between pods
kubectl run -it --rm debug \
  --image=alpine:latest \
  --restart=Never \
  -n unit-converter \
  -- sh

# Inside the pod:
wget -O- http://unit-converter-service:80
```

## Cleanup

To destroy all resources:

```bash
# Delete Kubernetes resources
cd k8s
kubectl delete -f .

# Destroy EKS cluster and infrastructure
cd ../eks-terraform
terraform destroy

# Delete ECR repository
aws ecr delete-repository \
  --repository-name $ECR_REPO_NAME \
  --region $AWS_REGION \
  --force
```

## Customization

### Change Instance Type

Edit `eks-terraform/terraform.tfvars`:

```hcl
instance_types = ["t3.small"]  # or t3.large, m5.large, etc.
```

### Change Cluster Size

Edit `eks-terraform/terraform.tfvars`:

```hcl
desired_capacity = 3  # Number of desired nodes
min_capacity     = 2  # Minimum nodes for autoscaling
max_capacity     = 6  # Maximum nodes for autoscaling
```

### Change Region

Edit `eks-terraform/terraform.tfvars`:

```hcl
aws_region = "eu-west-1"  # or any other AWS region
```

## Additional Resources

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [Spring Boot on Kubernetes](https://spring.io/guides/gs/spring-boot-docker/)
