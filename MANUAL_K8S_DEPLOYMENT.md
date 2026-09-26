# Manual Kubernetes Deployment

This guide deploys the Unit Converter to an **already-created** EKS cluster using the plain YAML manifests in `k8s/`. It assumes the EKS cluster and EC2 worker infrastructure already exist; it does not run Terraform or create that infrastructure. Manual `kubectl` commands are the primary path; the optional `deploy.py` helper is the only automation option documented here. There is no Helm.

## Prerequisites

- An existing EKS cluster and EC2 worker node group from `eks-terraform/`.
- AWS CLI credentials authorized to describe the cluster, update kubeconfig, and push images to ECR.
- `kubectl`, Docker, Python 3, and `curl` installed.
- Kubernetes access to the cluster; the EC2 workers need permission to pull images from the ECR repository in the same AWS account.
- Run the shell commands below from the repository root. They use Bash syntax.

The checked-in Terraform values use region `us-east-1`, cluster `unit-converter-eks`, and node group `unit-converter-worker-nodes`. If the existing cluster was created with different Terraform overrides, substitute those actual values in the commands.

## 1. Verify AWS and cluster access

```bash
aws sts get-caller-identity
aws eks describe-cluster \
  --name unit-converter-eks \
  --region us-east-1 \
  --query 'cluster.status' \
  --output text

aws eks update-kubeconfig \
  --region us-east-1 \
  --name unit-converter-eks

kubectl config current-context
kubectl cluster-info
kubectl get nodes -o wide
aws eks describe-nodegroup \
  --cluster-name unit-converter-eks \
  --nodegroup-name unit-converter-worker-nodes \
  --region us-east-1 \
  --query 'nodegroup.status' \
  --output text
```

Continue when the cluster and node group report `ACTIVE` and `kubectl get nodes` shows the EC2 worker nodes as `Ready`.

## 2. Build and push the application image

The Dockerfile builds the Spring Boot application and serves it on port `8080`. The Deployment's container is named `unit-converter`, but its checked-in image is `nginx:latest`—that is a placeholder, **not** the Unit Converter image. Build and push a real application image before applying the Deployment.

Create the ECR repository once if it does not already exist:

```bash
aws ecr describe-repositories \
  --repository-names unit-converter \
  --region us-east-1
```

If that command reports that the repository does not exist, create it:

```bash
aws ecr create-repository \
  --repository-name unit-converter \
  --region us-east-1
```

Build a Linux/AMD64 image (the configured EC2 workers use `t3.medium` instances), authenticate Docker to ECR, and push a uniquely tagged image:

```bash
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
IMAGE_TAG=$(git rev-parse --short HEAD)
IMAGE_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/unit-converter:${IMAGE_TAG}"

docker build --platform linux/amd64 -t "$IMAGE_URI" .
aws ecr get-login-password --region "$AWS_REGION" |
  docker login --username AWS --password-stdin \
    "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
docker push "$IMAGE_URI"
printf 'Use this image in k8s/deployment.yaml: %s\n' "$IMAGE_URI"
```

Use a different unique tag if rebuilding the same Git revision. Ensure the AWS identity used for the push has ECR write access; the worker node role in this Terraform configuration has ECR read access.

## 3. Set the image and apply the manifests

Edit `k8s/deployment.yaml` and replace the `image: nginx:latest` value with the exact ECR URI printed above. Do not apply the Deployment while it still uses `nginx:latest`.

From the repository root, create the namespace first, then apply the plain YAML manifests:

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/
```

Applying the directory creates the service account, RBAC resources, ConfigMap, Deployment, LoadBalancer Service, HPA, and PodDisruptionBudget in the `unit-converter` namespace. The Service exposes port `80` and forwards to container port `8080`.

## 4. Wait for and verify the rollout

```bash
kubectl rollout status deployment/unit-converter-app \
  --namespace unit-converter \
  --timeout=180s
kubectl get deployment,pods,service,hpa,pdb -n unit-converter -o wide
kubectl get endpoints unit-converter-service -n unit-converter
```

Wait for AWS to provision the Service's external load balancer; its address appears under `EXTERNAL-IP` (usually a hostname):

```bash
kubectl get service unit-converter-service \
  --namespace unit-converter \
  --watch
```

Stop watching after an external address appears, then test the application (replace the hostname with the value shown by `kubectl get service`):

```bash
curl --fail "http://<EXTERNAL-HOSTNAME>/"
```

The HPA also needs the Kubernetes resource metrics API (commonly provided by Metrics Server). If its metrics show `<unknown>`, verify that the metrics API is available; the application rollout and LoadBalancer Service do not depend on HPA metrics.

## Optional Python deployment helper

Manual `kubectl` deployment above is the recommended path. If you prefer the repository's Python helper, first build and push the image as described in step 2, then run this from the repository root:

```bash
python3 deploy.py --image-uri "$IMAGE_URI"
```

The helper applies the manifests from `./k8s`, sets the `unit-converter` container to the supplied image before checking readiness, and waits for the `unit-converter-app` Deployment and `unit-converter-service` LoadBalancer. It does not build or push the image; pass a real image URI and do not run it without `--image-uri`.

## Diagnostics

```bash
kubectl get pods -n unit-converter
kubectl describe pod <pod-name> -n unit-converter
kubectl logs deployment/unit-converter-app -n unit-converter
kubectl get events -n unit-converter --sort-by=.lastTimestamp
kubectl describe service unit-converter-service -n unit-converter
```

For `ImagePullBackOff`, check that the Deployment contains the pushed ECR URI, the tag exists, and the worker nodes can pull from that repository. For pending pods, inspect pod events and confirm worker nodes are `Ready` and have capacity. For an empty Service endpoint list, confirm the pods are Ready and match the Service selector (`app: unit-converter`).

## Cleanup

Delete the application namespace when it is no longer needed. This removes its Kubernetes resources and requests deletion of the LoadBalancer; AWS cleanup may take a few minutes.

```bash
kubectl delete namespace unit-converter
```

This guide leaves the EKS cluster, EC2 node group, and ECR repository intact. Delete those separately only when they are no longer needed.
