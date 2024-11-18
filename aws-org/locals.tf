locals {

  delegated_services = { for act_name, act_attrs in var.delegated_admins : act_name => act_attrs if can(act_attrs.services) }
  del_services_map = flatten([
    for name, attrs in local.delegated_services : [
      for service in attrs.services : {
        name              = name
        service_principal = service
      } if can(attrs.services)
    ]
  ])

  scp_attachments = { for scp_name, scp_attrs in var.policies : scp_name => scp_attrs if can(scp_attrs.attachments) }
  scp_attachment_map = flatten([
    for name, attrs in local.scp_attachments : [
      for ou in attrs.attachments : {
        name      = name
        target_id = ou
      } if can(attrs.attachments)
    ]
  ])

  rcp_attachments = { for rcp_name, rcp_attrs in var.resource_policies : rcp_name => rcp_attrs if can(rcp_attrs.attachments) }
  rcp_attachment_map = flatten([
    for name, attrs in local.rcp_attachments : [
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