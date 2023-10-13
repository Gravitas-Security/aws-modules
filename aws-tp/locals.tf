locals {
  tp_attachments = { for tp_name, tp_attrs in var.tag_policies : tp_name => tp_attrs if can(tp_attrs.attachments) }
  attachment_map = flatten([
    for name, attrs in local.tp_attachments : [
      for ou in attrs.attachments : {
        name      = name
        target_id = ou
      } if can(attrs.attachments)
    ]
  ])

#policy_data = { for tp_name, attr in var.policies : tp_name => attr if can(jsonencode(file("./${attr.policy}")))}
}
