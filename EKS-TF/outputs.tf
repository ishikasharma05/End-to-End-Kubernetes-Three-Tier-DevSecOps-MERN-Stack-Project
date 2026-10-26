output "cluster_name" {
  value = module.eks.cluster_name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "lb_controller_role_arn" {
  value = module.lb_controller_irsa.iam_role_arn
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}
