locals {
  max_subnet_length = max(
    length(var.private_subnets),
    length(var.database_subnets),
    length(var.eks_subnets)
  )

  nat_gateway_count = var.natgw_per_az ? length(var.azs) : local.max_subnet_length

  nat_gateway_ips = try(aws_eip.nat[*].id, [])

  attach_tgw = var.tgw_attachment ? 1 : 0

  tgw_routes = flatten([
    for k, v in var.transit_gateway_routes : [
      for rtb_id in try(v.aws_route_table.private_rt[*].id, []) : {
        rtb_id = rtb_id
        cidr   = v.tgw_destination_cidr
      }
    ]
  ])


  vpcx_routes = flatten([
    for k, v in var.vpc_peering_routes : [
      for rtb_id in try(v.aws_route_table.private_rt[*].id, []) : {
        rtb_id = rtb_id
        cidr   = v.vpcx_destination_cidr
      }
    ]
  ])
}