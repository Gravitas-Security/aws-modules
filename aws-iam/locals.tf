locals {
  attached_policies       = { for iam_name, iam_attrs in var.roles : iam_name => iam_attrs if can(iam_attrs.policies) }
  
  # create ps_name and managed policy maps list
  iam_policy_maps = flatten([
    for name, attrs in local.attached_policies : [
      for policy in attrs.policies : {
        name       = name
        policy = policy
        #arn = policy.arn
      } if can(attrs.policies)
    ]
  ])
}
