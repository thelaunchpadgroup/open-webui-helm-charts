output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = aws_eks_cluster.open_webui.id
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = aws_eks_cluster.open_webui.arn
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS API server"
  value       = aws_eks_cluster.open_webui.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID for the EKS cluster"
  value       = aws_security_group.eks_cluster.id
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.open_webui.name
}

output "cluster_certificate_authority_data" {
  description = "The certificate authority data for the EKS cluster"
  value       = aws_eks_cluster.open_webui.certificate_authority[0].data
}

output "node_group_id" {
  description = "ID of the node group"
  value       = aws_eks_node_group.open_webui.id
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider"
  value       = aws_eks_cluster.open_webui.identity[0].oidc[0].issuer
}

output "aws_lb_controller_namespace" {
  description = "The namespace where the AWS Load Balancer Controller is installed"
  value       = "kube-system"
}

