## Get data about current account
data "aws_caller_identity" "current" {}

## Create Github Pipelines Role, assign default permissions
resource "aws_iam_role" "github-pipelines-role" {
  name = "github-pipelines-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = "arn:aws:iam::808696518247:role/github-pipeline-role"
        }
      },
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]
  tags = merge(
    var.defaultTags,
    var.custom_tags
  )
}

## Create EKS Node Role, assign default permissions
resource "aws_iam_role" "eks-node-role" {
  name = "eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
  tags = merge(
    var.defaultTags,
    var.custom_tags
  )
}

## Create Instance Profile for EKS nodes
resource "aws_iam_instance_profile" "eks-node-role" {
  name = "eks-node-role"
  role = aws_iam_role.eks-node-role.name
  tags = merge(
    var.defaultTags,
    var.custom_tags
  )
}

## Create default EC2 role for SSM and assign default permissions
resource "aws_iam_role" "default_instance_role" {
  name = "DefaultEC2RoleforSSM"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedEC2InstanceDefaultPolicy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
  tags = merge(
    var.defaultTags,
    var.custom_tags
  )
}

## Create Instance Profile for default EC2 role
resource "aws_iam_instance_profile" "default-ec2-role" {
  name = "DefaultEC2RoleforSSM"
  role = aws_iam_role.eks-node-role.name
  tags = merge(
    var.defaultTags,
    var.custom_tags
  )
}

## Create AWS IAM Role
resource "aws_iam_role" "roles" {
  for_each = var.roles

  name                 = each.key
  max_session_duration = each.value.session_duration != null ? each.value.session_duration : 3600

  ## If the trusted entity is an AWS service, use the Service principal, otherwise use the AWS principal
  assume_role_policy = (strcontains(each.value.trusted_entity, "amazonaws.com")) ? jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "${each.value.trusted_entity}"
        }
      },
    ]
    }) : jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = "${each.value.trusted_entity}"
        }
      },
    ]
  })

  tags = merge(
    var.defaultTags,
    var.custom_tags
  )
  depends_on = [aws_iam_policy.policies]
}

## Create instance profile for each role in the roles map if instance_profile = true
resource "aws_iam_instance_profile" "instance_profiles" {
  for_each = { for role, attr in var.roles : role => attr if can(attr.instance_profile) && attr.instance_profile == true }

  name = each.key
  role = aws_iam_role.roles[each.key].name
  tags = merge(
    var.defaultTags,
    var.custom_tags
  )
  depends_on = [aws_iam_role.roles]
}

## Create AWS IAM Policy object
data "aws_iam_policy_document" "policies" {
  for_each = var.policies
  dynamic "statement" {
    for_each = each.value.statement
    content {
      sid       = statement.value.sid
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

## Create AWS IAM Policy
resource "aws_iam_policy" "policies" {
  for_each    = var.policies
  name        = each.key
  path        = each.value.path != null ? each.value.path : "/"
  description = each.value.description != null ? each.value.description : null
  policy      = data.aws_iam_policy_document.policies[each.key].json
  tags = merge(
    var.defaultTags,
    var.custom_tags
  )
}

## Get ARNS for managed policies
data "aws_iam_policy" "managed_policies" {
  for_each = { for policy in local.iam_policy_maps : "${policy.name}_${policy.policy}" => policy }

  name       = each.value.policy
  depends_on = [aws_iam_policy.policies]
}

## Create AWS IAM Role Policy Attachments
resource "aws_iam_role_policy_attachment" "policy-attachment" {
  for_each = { for iam in local.iam_policy_maps : "${iam.name}_${iam.policy}" => iam }

  role       = each.value.name
  policy_arn = data.aws_iam_policy.managed_policies[each.key].arn
  depends_on = [
    aws_iam_policy.policies,
    aws_iam_role.roles
  ]
}
