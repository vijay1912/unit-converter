# AWS EKS with Terraform

This standalone Terraform configuration creates an EKS cluster named `unit-converter-eks` in `us-east-1`, a VPC with public and private subnets, NAT gateways, and an EC2-backed EKS managed node group named `unit-converter-worker-nodes`. The checked-in `terraform.tfvars` requests Kubernetes `1.29` and two `t3.medium` worker nodes (minimum 1, maximum 4).

## Prerequisites

- Terraform 1.0 or later.
- AWS CLI configured with credentials for an AWS account and permissions to create/manage EKS, EC2/VPC, IAM, and CloudWatch resources.
- `kubectl` installed.
- A Kubernetes version supported by EKS in the selected region. The checked-in input is `1.29`; update `kubernetes_version` in `eks-terraform/terraform.tfvars` if that version is no longer available.

## Initialize, plan, and apply

Run these commands from the repository root:

```sh
cd eks-terraform
terraform init
terraform plan
terraform apply
```

Review the plan before confirming `apply`. The configuration automatically loads `terraform.tfvars`. Edit that file to change the region, cluster, Kubernetes version, instance types, or node scaling values before planning.

## Outputs and kubeconfig

After apply, inspect the outputs:

```sh
terraform output
```

Outputs include the cluster ID, ARN, endpoint and version; cluster and worker security group IDs; worker node group ID and status; VPC and subnet IDs; and `configure_kubectl`, which prints the matching `aws eks update-kubeconfig` command. With the checked-in values, configure the current AWS CLI kubeconfig context with:

```sh
aws eks update-kubeconfig --region us-east-1 --name unit-converter-eks
```

If you changed the region or cluster name, use the command shown by `terraform output -raw configure_kubectl` instead.

## Validate the EC2 managed node group

Check the managed node group status and its configured instance type and scaling:

```sh
aws eks describe-nodegroup \
  --region us-east-1 \
  --cluster-name unit-converter-eks \
  --nodegroup-name unit-converter-worker-nodes \
  --query 'nodegroup.{Status:status,InstanceTypes:instanceTypes,Scaling:scalingConfig}' \
  --output table
```

The status should be `ACTIVE`. Confirm Kubernetes can see the worker nodes and their EC2 instance type and EKS node group labels:

```sh
kubectl get nodes -o wide
kubectl get nodes -L node.kubernetes.io/instance-type,eks.amazonaws.com/nodegroup
```

The expected instance type is `t3.medium` unless you changed the Terraform input.

## Destroy and cost warning

EKS clusters, EC2 worker instances, NAT gateways, Elastic IPs, data transfer, and CloudWatch logs can incur charges while deployed. When you no longer need the environment, remove resources from this directory:

```sh
terraform destroy
```

Review the destroy plan and confirm it before proceeding. Keep the Terraform state until the resources have been destroyed successfully.
