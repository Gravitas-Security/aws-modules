data "aws_region" "current" {}

resource "aws_vpc_ipam" "ipam_scope" {
  for_each = var.ipam_scopes
  description = "multi region ipam"
  dynamic operating_regions {
    for_each = each.value.regions == "global" ? local.all_ipam_regions : each.value.regions
    content {
      region_name = each.key
    }
  }
}

resource "aws_vpc_ipam_scope" "example" {
  ipam_id     = aws_vpc_ipam.example.id
  description = "Another Scope"
}