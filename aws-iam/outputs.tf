output "roles" {
    value = aws_iam_role.roles
}

output "policies" {
    value = aws_iam_policy.policies
}

output "instance_profiles" {
    value = aws_iam_instance_profile.instance_profiles
}

output "pipeline_roles" {
    value = aws_iam_role.github-pipelines-role
}

output "eks_node_role" {
    value = aws_iam_role.eks-node-role
}

output "eks_instance_profiles" {
    value = aws_iam_instance_profile.eks-node-role
}

output "default_ec2_role" {
    value = aws_iam_role.default_instance_role
}

output "default_instance_profiles" {
    value = aws_iam_instance_profile.default-ec2-role
}