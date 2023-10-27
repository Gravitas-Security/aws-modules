data "aws_region" "current" {}

resource "aws_ram_resource_share" "ipam_shares" {
  name                      = "org_ipam_share"
  allow_external_principals = false

  tags = {
    Environment = "Mgmt"
  }
}

## Get data about the AWS Organization for use in subsequent steps
data "aws_organizations_organization" "org" {}

resource "aws_ram_principal_association" "ipam_share" {
  principal          = data.aws_organizations_organization.org.arn
  resource_share_arn = aws_ram_resource_share.ipam_shares.arn
}



resource "aws_vpc_ipam" "ipam" {
  for_each = var.ipam_sets
  description = each.value.description
  dynamic "operating_regions" {
    for_each = toset(local.operating_regions)
    content {
      region_name = operating_regions.key
    }
  }

  tags = merge(
    {Name = "${each.key}-ipam"},
    var.defaultTags,
    var.custom_tags
  )
}

resource "aws_vpc_ipam_scope" "ipam_scopes" {
  for_each = var.ipam_sets
  ipam_id     = aws_vpc_ipam.ipam[each.key].id
  description = each.value.description
  tags = merge(
    {Name = "${each.key}-scope"},
    var.defaultTags,
    var.custom_tags
  )
}

resource "aws_vpc_ipam_resource_discovery" "discoveries" {
  for_each = var.ipam_sets
  description = each.value.description
  dynamic "operating_regions" {
    for_each = toset(local.operating_regions)
    content {
      region_name = operating_regions.key
    }
  }
  tags = merge(
    {Name = "${each.key}-discovery"},
    var.defaultTags,
    var.custom_tags
  )
}


resource "aws_vpc_ipam_resource_discovery_association" "associations" {
  for_each = var.ipam_sets
  ipam_id                    = aws_vpc_ipam.ipam[each.key].id
  ipam_resource_discovery_id = aws_vpc_ipam_resource_discovery.discoveries[each.key].id

  tags = merge(
    {Name = "${each.key}-discovery_association"},
    var.defaultTags,
    var.custom_tags
  )
}

resource "aws_vpc_ipam_pool" "master-pool" {
  for_each = var.ipam_sets
  address_family = "ipv4"
  ipam_scope_id  = aws_vpc_ipam.ipam[each.key].private_default_scope_id
  tags = merge(
    {Name = "${each.key}-toplevel-pool"},
    var.defaultTags,
    var.custom_tags
  )
}

resource "aws_vpc_ipam_pool_cidr" "master_cidrs" {
  for_each = var.ipam_sets
  ipam_pool_id = aws_vpc_ipam_pool.master-pool[each.key].id
  cidr         = each.value.ipam_pool
}

resource "aws_vpc_ipam_pool" "dev_pools" {
  for_each = var.ipam_sets
  address_family = "ipv4"
  ipam_scope_id  = aws_vpc_ipam.ipam[each.key].private_default_scope_id
  source_ipam_pool_id = aws_vpc_ipam_pool.master-pool[each.key].id
  tags = merge(
    {Name = "${each.key}-dev-pool"},
    var.defaultTags,
    var.custom_tags
  )
}

resource "aws_vpc_ipam_pool_cidr" "dev_cidrs" {
  for_each = var.ipam_sets
  ipam_pool_id = aws_vpc_ipam_pool.dev_pools[each.key].id
  cidr         = each.value.dev_cidrs
}

resource "aws_ram_resource_association" "ipam_pool_dev_shares" {
  for_each = var.ipam_sets
  resource_arn       = aws_vpc_ipam_pool.dev_pools[each.key].arn
  resource_share_arn = aws_ram_resource_share.ipam_shares.arn
}

resource "aws_vpc_ipam_pool" "prod_pools" {
  for_each = var.ipam_sets
  address_family = "ipv4"
  ipam_scope_id  = aws_vpc_ipam.ipam[each.key].private_default_scope_id
  source_ipam_pool_id = aws_vpc_ipam_pool.master-pool[each.key].id
  tags = merge(
    {Name = "${each.key}-prod-pool"},
    var.defaultTags,
    var.custom_tags
  )
}

resource "aws_vpc_ipam_pool_cidr" "prod_cidrs" {
  for_each = var.ipam_sets
  ipam_pool_id = aws_vpc_ipam_pool.prod_pools[each.key].id
  cidr         = each.value.prod_cidrs
}

resource "aws_ram_resource_association" "ipam_pool_prod_shares" {
  for_each = var.ipam_sets
  resource_arn       = aws_vpc_ipam_pool.prod_pools[each.key].arn
  resource_share_arn = aws_ram_resource_share.ipam_shares.arn
}