locals {
  scp_attachments            = { for scp_name, scp_attrs in var.policies : scp_name => scp_attrs if can(scp_attrs.attachments) }
  attachment_map = flatten([
     for name, attrs in local.scp_attachments : [
       for ou in attrs.attachments : {
         name   = name
         target_id = ou
       } if can(attrs.attachments)
     ]
   ])
}