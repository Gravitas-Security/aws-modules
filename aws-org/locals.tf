locals {
  scp_attachments = { for scp_name, scp_attrs in var.policies : scp_name => scp_attrs if can(scp_attrs.attachments) }
  scp_attachment_map = flatten([
    for name, attrs in local.scp_attachments : [
      for ou in attrs.attachments : {
        name      = name
        target_id = ou
      } if can(attrs.attachments)
    ]
  ])

  tp_attachments = { for tp_name, tp_attrs in var.tag_policies : tp_name => tp_attrs if can(tp_attrs.attachments) }
  tp_attachment_map = flatten([
    for name, attrs in local.tp_attachments : [
      for ou in attrs.attachments : {
        name      = name
        target_id = ou
      } if can(attrs.attachments)
    ]
  ])
}