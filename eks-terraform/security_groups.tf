# Security Group for EKS Cluster
resource "aws_security_group" "eks_cluster" {
  name        = "unit-converter-eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.eks_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "unit-converter-eks-cluster-sg"
  }
}

# Security Group for EKS Worker Nodes
resource "aws_security_group" "eks_worker" {
  name        = "unit-converter-eks-worker-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.eks_vpc.id

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "udp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  ingress {
    from_port = 1025
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "unit-converter-eks-worker-sg"
  }
}

# Allow cluster to receive communication from worker nodes
resource "aws_security_group_rule" "eks_cluster_ingress_worker" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_worker.id
  security_group_id        = aws_security_group.eks_cluster.id
}
