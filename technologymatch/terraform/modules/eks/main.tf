resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.prefix}-eks-cluster-role-new"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role" "eks_node_role" {
  name = "${var.prefix}-eks-node-role-new"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_readonly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "s3_access_policy" {
  policy_arn = var.s3_access_policy_arn
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_eks_cluster" "open_webui" {
  name     = "${var.prefix}-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = var.endpoint_public_access
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.eks.arn
    }
  }

  # Enable EKS add-ons
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = var.tags
}

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = var.tags
}

resource "aws_security_group" "eks_cluster" {
  name        = "${var.prefix}-eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-eks-cluster-sg"
    }
  )
}

# Allow RDS access from the EKS cluster security group
resource "aws_security_group_rule" "eks_to_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = var.database_security_group_id
  source_security_group_id = aws_security_group.eks_cluster.id
  description              = "Allow PostgreSQL traffic from EKS cluster"
}

# Allow access from private subnets (for node groups)
resource "aws_security_group_rule" "eks_nodes_to_rds_subnet1" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = var.database_security_group_id
  cidr_blocks       = [cidrsubnet(data.aws_vpc.eks_vpc.cidr_block, 8, 2)]  # First private subnet
  description       = "Allow PostgreSQL traffic from EKS nodes in private subnet 1"
}

resource "aws_security_group_rule" "eks_nodes_to_rds_subnet2" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = var.database_security_group_id
  cidr_blocks       = [cidrsubnet(data.aws_vpc.eks_vpc.cidr_block, 8, 3)]  # Second private subnet
  description       = "Allow PostgreSQL traffic from EKS nodes in private subnet 2"
}

# Get VPC information
data "aws_vpc" "eks_vpc" {
  id = var.vpc_id
}

resource "aws_eks_node_group" "open_webui" {
  cluster_name    = aws_eks_cluster.open_webui.name
  node_group_name = "${var.prefix}-nodes-v2"  # Modified name to avoid conflict
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.private_subnet_ids

  instance_types = var.node_instance_types
  disk_size      = var.node_disk_size
  capacity_type  = var.capacity_type

  scaling_config {
    desired_size = var.desired_nodes
    max_size     = var.max_nodes
    min_size     = var.min_nodes
  }

  update_config {
    max_unavailable = 1
  }

  # Optional: Kubernetes labels
  labels = {
    role = "open-webui"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_readonly,
    aws_iam_role_policy_attachment.s3_access_policy
  ]

  tags = var.tags
}

# Install AWS Load Balancer Controller for ingress
resource "aws_iam_policy" "load_balancer_controller" {
  name        = "${var.prefix}-alb-controller-policy-new"
  description = "Policy for AWS Load Balancer Controller"

  policy = file("${path.module}/policies/load-balancer-controller-policy.json")
}

resource "aws_iam_role" "load_balancer_controller" {
  name = "${var.prefix}-alb-controller-role-new"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.open_webui.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "load_balancer_controller" {
  policy_arn = aws_iam_policy.load_balancer_controller.arn
  role       = aws_iam_role.load_balancer_controller.name
}

data "aws_caller_identity" "current" {}

# Create OIDC provider for the EKS cluster
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.open_webui.identity[0].oidc[0].issuer

  tags = var.tags
}

# Get the TLS certificate for the EKS OIDC provider
data "tls_certificate" "eks" {
  url = aws_eks_cluster.open_webui.identity[0].oidc[0].issuer
}

# Define Helm release for AWS Load Balancer Controller
resource "helm_release" "aws_load_balancer_controller" {
  name             = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  namespace        = "kube-system"
  version          = var.alb_controller_version
  timeout          = 1800  # Increased to 30 minutes from default
  atomic           = true
  cleanup_on_fail  = true
  wait             = true

  # Set controller to use only 1 replica to save resources in dev environment
  set {
    name  = "replicaCount"
    value = "1"
  }

  set {
    name  = "clusterName"
    value = aws_eks_cluster.open_webui.name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.load_balancer_controller.arn
  }

  depends_on = [
    aws_eks_node_group.open_webui
  ]
}

# Install the EBS CSI driver for dynamic volume provisioning
resource "aws_iam_role" "ebs_csi_controller" {
  name = "${var.prefix}-ebs-csi-controller-role-new"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.open_webui.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi_controller" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_controller.name
}

resource "helm_release" "aws_ebs_csi_driver" {
  name             = "aws-ebs-csi-driver"
  namespace        = "kube-system"
  repository       = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart            = "aws-ebs-csi-driver"
  version          = var.ebs_csi_driver_version
  timeout          = 1800  # Increased to 30 minutes
  atomic           = true
  cleanup_on_fail  = true
  wait             = true

  set {
    name  = "controller.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "controller.serviceAccount.name"
    value = "ebs-csi-controller-sa"
  }

  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.ebs_csi_controller.arn
  }

  set {
    name  = "enableVolumeScheduling"
    value = "true"
  }

  set {
    name  = "enableVolumeResizing"
    value = "true"
  }

  set {
    name  = "enableVolumeSnapshot"
    value = "true"
  }

  depends_on = [
    aws_eks_node_group.open_webui
  ]
}