output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.unit_converter.id
}

output "eks_cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.unit_converter.arn
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.unit_converter.endpoint
}

output "eks_cluster_version" {
  description = "EKS cluster version"
  value       = aws_eks_cluster.unit_converter.version
}

output "eks_cluster_security_group_id" {
  description = "Security group ID of the EKS cluster"
  value       = aws_security_group.eks_cluster.id
}

output "eks_worker_security_group_id" {
  description = "Security group ID of the worker nodes"
  value       = aws_security_group.eks_worker.id
}

output "worker_node_group_id" {
  description = "Worker node group ID"
  value       = aws_eks_node_group.worker_nodes.id
}

output "worker_node_group_status" {
  description = "Worker node group status"
  value       = aws_eks_node_group.worker_nodes.status
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.eks_vpc.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.unit_converter.name}"
}
