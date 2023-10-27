locals {
   all_locales = distinct(compact(flatten(concat([for k, v in var.ipam_sets : try(v.region, null)]))))
  operating_regions = distinct(concat(local.all_locales, [data.aws_region.current.name]))
}
