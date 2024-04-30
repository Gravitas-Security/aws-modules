## Get data about the AWS Organization for use in subsequent steps
resource "aws_organizations_organization" "org" {
  feature_set = "ALL"
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY"
  ]
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "account.amazonaws.com",
    "ssm.amazonaws.com",
    "sso.amazonaws.com",
    "tagpolicies.tag.amazonaws.com",
    "ipam.amazonaws.com",
    "detective.amazonaws.com",
    "auditmanager.amazonaws.com",
    "fms.amazonaws.com",
    "guardduty.amazonaws.com",
    "securitylake.amazonaws.com",
    "securityhub.amazonaws.com",
    "macie.amazonaws.com",
    "inspector2.amazonaws.com",
    "access-analyzer.amazonaws.com",
    "ram.amazonaws.com",
    "servicecatalog.amazonaws.com",
    "member.org.stacksets.cloudformation.amazonaws.com"
  ]
}

resource "aws_ram_sharing_with_organization" "org_share" {}

# Create AWS Organization OU's
resource "aws_organizations_organizational_unit" "org_ous" {
  for_each  = var.ous
  name      = each.key
  parent_id = aws_organizations_organization.org.roots[0].id
  tags = merge(
    var.defaultTags,
    var.custom_tags
  )
  depends_on = [aws_organizations_organization.org]
}

resource "aws_organizations_account" "accounts" {
  for_each                   = var.aws_accounts
  name                       = each.key
  email                      = each.value.email
  iam_user_access_to_billing = "ALLOW"
  parent_id                  = each.value.ou == "root" ? aws_organizations_organization.org.roots[0].id : aws_organizations_organizational_unit.org_ous[each.value.ou].id
  close_on_deletion          = each.value.close_on_delete != null ? each.value.close_on_delete : true
  role_name                  = each.value.role_name != null ? each.value.role_name : "OrganizationAccountAccessRole"
  tags = merge(
    var.defaultTags,
    var.custom_tags
  )
  depends_on = [
    aws_organizations_organizational_unit.org_ous
  ]
  lifecycle {
    ignore_changes = [
      role_name,
      iam_user_access_to_billing
    ]
  }
}

resource "aws_organizations_delegated_administrator" "delegated_admin" {
  for_each = { for act in local.del_services_map : "${act.name}-${act.service_principal}" => act }
  account_id = aws_organizations_account.accounts[each.value.name].id
  service_principal = "${each.value.service_principal}.amazonaws.com"
  depends_on = [aws_organizations_account.accounts]
}

data "aws_iam_policy_document" "policy_validation" {
  for_each                = var.policies
  source_policy_documents = [file("policies/${each.key}.json")]
}

# Create AWS Service Control Policy
resource "aws_organizations_policy" "org_scp" {
  for_each    = var.policies
  name        = each.key
  description = each.value.description
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.policy_validation[each.key].json
  tags = merge(
    var.defaultTags,
    var.custom_tags
  )
  depends_on = [aws_organizations_organizational_unit.org_ous]
}

# Attache AWS SCP to AWS Organization root, ou, or account
resource "aws_organizations_policy_attachment" "org_scp_attachment" {
  for_each  = { for scp in local.scp_attachment_map : "${scp.name}_${scp.target_id}" => scp }
  policy_id = aws_organizations_policy.org_scp[each.value.name].id
  target_id = each.value.target_id == "root" ? aws_organizations_organization.org.roots[0].id : each.value.target_id == can(regex("^[0-9]", each.value.target_id)) ? aws_organizations_account.accounts[each.value.target_id].id : aws_organizations_organizational_unit.org_ous[each.value.target_id].id
}

# Create AWS Tag Policy
resource "aws_organizations_policy" "org_tp" {
  for_each    = var.tag_policies
  name        = each.key
  description = each.value.description
  type        = "TAG_POLICY"
  content     = file("tag_policies/${each.key}.json")
  tags = merge(
    var.defaultTags,
    var.custom_tags
  )
}

# Attache AWS SCP to AWS Organization root, ou, or account
resource "aws_organizations_policy_attachment" "org_tp_attachment" {
  for_each  = { for tp in local.tp_attachment_map : "${tp.name}_${tp.target_id}" => tp }
  policy_id = aws_organizations_policy.org_tp[each.value.name].id
  target_id = each.value.target_id == "root" ? aws_organizations_organization.org.roots[0].id : aws_organizations_organizational_unit.org_ous[each.value.target_id].id
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

resource "aws_s3_bucket" "org_trail_bucket" {
  bucket        = "org-trail-bucket-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
  tags = merge(
    var.defaultTags,
    var.custom_tags
  )
}

resource "aws_s3_bucket_lifecycle_configuration" "org-trail-bucket-lifecycle" {
  bucket = aws_s3_bucket.org_trail_bucket.id

  rule {
    id = "expire-90-days"
    expiration {
      days = 90
    }
    status = "Enabled"
}
}

data "aws_iam_policy_document" "org_trail_bucketpolicy" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.org_trail_bucket.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/org-trail"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.org_trail_bucket.arn}/prefix/AWSLogs/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/org-trail"]
    }
  }
}

resource "aws_s3_bucket_policy" "org_trail_bucketpolicy" {
  bucket = aws_s3_bucket.org_trail_bucket.id
  policy = data.aws_iam_policy_document.org_trail_bucketpolicy.json
}

resource "aws_cloudtrail" "org_trail" {
  depends_on = [aws_s3_bucket_policy.org_trail_bucketpolicy]

  name                          = "org-trail"
  s3_bucket_name                = aws_s3_bucket.org_trail_bucket.id
  s3_key_prefix                 = "prefix"
  include_global_service_events = true
  is_organization_trail = true
  is_multi_region_trail = true
  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }
  tags = merge(
    var.defaultTags,
    var.custom_tags
  )
}