locals {
  # ensure current provider region is an operating_regions entry
  all_ipam_regions = distinct(concat([data.aws_region.current.name], var.ipam_scopes["regions"]))
}