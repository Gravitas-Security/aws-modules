output "roles" {
    value = aws_iam_role.roles
}

output "policies" {
    value = aws_iam_policy.policies
}

output "instance_profiles" {
    value = aws_iam_instance_profile.instance_profiles
}