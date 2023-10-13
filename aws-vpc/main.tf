### Comment to trigger workflow. delete after

### VPC Resources
## Create VPC and its required resources
# Create VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(
    { Name = var.vpc_name },
    var.defaultTags,
    var.vpc_tags
  )
}

# Optional CIDR Expansions
resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  count      = length(var.secondary_cidr_blocks) > 0 ? length(var.secondary_cidr_blocks) : 0
  vpc_id     = aws_vpc.vpc.id
  cidr_block = try(var.secondary_cidr_blocks, null)
}

# Assume control of the Default VPC Security Group and delete all rules
resource "aws_default_security_group" "default_sg" {
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    { Name = "${var.vpc_name}-default-sg-DO-NOT-USE" },
    var.defaultTags,
    var.vpc_tags
  )
  depends_on = [
    aws_vpc.vpc
  ]
}

# Assume control of the default VPC Route Table
resource "aws_default_route_table" "default_rt" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id
  tags = merge(
    { Name = "${var.vpc_name}-default-rt" },
    var.defaultTags,
    var.vpc_tags
  )
  depends_on = [
    aws_vpc.vpc
  ]
}

# Assume control of the default VPC DHCP option set
resource "aws_vpc_dhcp_options" "vpc_dhcp_options" {
  domain_name         = "us-west-2.compute.internal"
  domain_name_servers = ["AmazonProvidedDNS"]
  tags = merge(
    { Name = "${var.vpc_name}-vpc-dhcp" },
    var.defaultTags,
    var.vpc_tags
  )
  depends_on = [
    aws_vpc.vpc
  ]
}

resource "aws_vpc_dhcp_options_association" "dhcp_options_association" {
  vpc_id          = aws_vpc.vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.vpc_dhcp_options.id
  depends_on = [
    aws_vpc_dhcp_options.vpc_dhcp_options
  ]
}

## Create Connective Tissues
# Create internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    { Name = "${var.vpc_name}-igw" },
    var.defaultTags,
    var.vpc_tags
  )
  depends_on = [
    aws_vpc.vpc
  ]
}

# Create N # of Elastip Ip's for the NatGW's below
resource "aws_eip" "nat" {
  count = local.nat_gateway_count
  domain   = "vpc"
  tags = merge(
    {
      "Name" = format(
        "${var.vpc_name}-eip-%s",
        element(var.azs, count.index),
      )
    },
    var.defaultTags,
    var.vpc_tags
  )
}

# Create NatGW's based on the variables `natgw_per_az`
resource "aws_nat_gateway" "ngw" {
  count = local.nat_gateway_count
  allocation_id = element(
    local.nat_gateway_ips,
    count.index,
  )
  subnet_id = element(
    aws_subnet.public[*].id,
    count.index,
  )
  tags = merge(
    {
      Name = format(
        "${var.vpc_name}-natgw-%s",
        element(var.azs, count.index),
      )
    },
    var.defaultTags,
    var.vpc_tags
  )
  depends_on = [aws_internet_gateway.igw]
}

### Create Public, Private, EKS, && Database Subnets
## Public Subnet Resources
# Create N # of public subnets based on the `public_subnets` values defined
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets) > 0 && (length(var.public_subnets) >= length(var.azs)) ? length(var.public_subnets) : 0
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = element(concat(var.public_subnets, [""]), count.index)
  availability_zone       = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  map_public_ip_on_launch = false
  tags = merge(
    { Name = format(
      "${var.vpc_name}-public-%s",
      element(var.azs, count.index),
      )
    },
    {
      "kubernetes.io/role/elb" = 1
    },
    var.defaultTags,
    var.vpc_tags
  )
  depends_on = [
    aws_vpc.vpc
  ]
}

# Create route table to for public subnets
resource "aws_route_table" "public_route_tb" {
  count  = length(var.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(
    { Name = "${var.vpc_name}-public_rt" },
    var.defaultTags,
    var.vpc_tags
  )
  depends_on = [
    aws_internet_gateway.igw
  ]
}

# Add route to igw table to the public route table
resource "aws_route" "public_internet_gateway" {
  count                  = length(var.public_subnets) > 0 ? 1 : 0
  route_table_id         = aws_route_table.public_route_tb[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  depends_on = [
    aws_route_table.public_route_tb,
    aws_internet_gateway.igw
  ]
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public_route_tb" {
  count          = length(var.public_subnets) > 0 ? length(var.public_subnets) : 0
  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public_route_tb[0].id
  depends_on = [
    aws_route_table.public_route_tb
  ]
}

# Create the public_subnet VPC NACL
resource "aws_network_acl" "public_nacl" {
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = aws_subnet.public[*].id
  ingress {
    protocol   = 6
    rule_no    = 1
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  ingress {
    protocol   = 17
    rule_no    = 2
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  ingress {
    protocol   = 6
    rule_no    = 3
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  ingress {
    protocol   = 17
    rule_no    = 4
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = merge(
    { Name = "${var.vpc_name}-public-nacl" },
    var.defaultTags,
    var.vpc_tags
  )
  depends_on = [
    aws_subnet.public
  ]
  lifecycle {
    ignore_changes = [subnet_ids]
  }
}


## Private Subnet Resources
# Create N # of private subnets based on trhe `private_subnets` values defined
resource "aws_subnet" "private" {
  count                   = length(var.private_subnets) > 0 && (length(var.private_subnets) >= length(var.azs)) ? length(var.private_subnets) : 0
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = element(concat(var.private_subnets, [""]), count.index)
  availability_zone       = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  map_public_ip_on_launch = false
  tags = merge(
    { Name = format(
      "${var.vpc_name}-private-%s",
      element(var.azs, count.index),
      )
    },
    {
      "kubernetes.io/role/internal-elb" = 1
    },
    var.defaultTags,
    var.vpc_tags
  )
  depends_on = [
    aws_vpc.vpc
  ]
}

#resource "aws_ec2_tag" "private_cluster_tag" {
#  for_each = var.eks_clustername
#  resource_id  = aws_subnet.private[count.index]
#  key         = format("kubernetes.io/cluster/%s", each.item)
#  value       = "shared"
#}

#  Create private subnet route table
resource "aws_route_table" "private_route_tb" {
  count  = local.max_subnet_length > 0 ? local.nat_gateway_count : 0
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    {
      Name = format(
        "${var.vpc_name}-private-rt-%s",
        element(var.azs, count.index),
      )
    },
    var.defaultTags,
    var.vpc_tags
  )
  depends_on = [
    aws_nat_gateway.ngw
  ]
}
# Add route to NatGW's to the private subnets route table (Routes dependant on NatGW variables selected)
resource "aws_route" "private_nat_rt" {
  count                  = local.nat_gateway_count
  route_table_id         = element(aws_route_table.private_route_tb[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.ngw[*].id, count.index)
  depends_on = [
    aws_route_table.private_route_tb,
    aws_nat_gateway.ngw
  ]
}

# Associate public subnets with public route table
resource "aws_route_table_association" "private_route_tb" {
  count          = length(var.private_subnets) > 0 ? length(var.private_subnets) : 0
  subnet_id      = element(aws_subnet.private[*].id, count.index)
  route_table_id = aws_route_table.private_route_tb[0].id
  depends_on = [
    aws_route_table.private_route_tb
  ]
}

# Create the private VPC NACL
resource "aws_network_acl" "private_nacl" {
  #checkov:skip=CKV_AWS_232
  #checkov:skip=CKV_AWS_229
  #checkov:skip=CKV_AWS_231
  #checkov:skip=CKV_AWS_230
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = aws_subnet.private[*].id
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = merge(
    { Name = "${var.vpc_name}-private-nacl" },
    var.defaultTags,
    var.vpc_tags
  )
  depends_on = [
    aws_subnet.private
  ]
  lifecycle {
    ignore_changes = [subnet_ids]
  }
}

## EKS Subnet resources
# Create N # of eks subnets based on the `eks_subnets` values defined
resource "aws_subnet" "eks" {
  count                   = length(var.eks_subnets) > 0 && (length(var.eks_subnets) >= length(var.azs)) ? length(var.eks_subnets) : 0
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = element(concat(var.eks_subnets, [""]), count.index)
  availability_zone       = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  map_public_ip_on_launch = false
  tags = merge(
    { Name = format(
      "${var.vpc_name}-eks-%s",
      element(var.azs, count.index),
      )
    },
    var.defaultTags,
    var.vpc_tags
  )
  depends_on = [
    aws_vpc.vpc
  ]
}

#  Create eks subnet route table
resource "aws_route_table" "eks_route_tb" {
  count  = local.max_subnet_length > 0 ? local.nat_gateway_count : 0
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    {
      Name = format(
        "${var.vpc_name}-eks-rt-%s",
        element(var.azs, count.index),
      )
    },
    var.defaultTags,
    var.vpc_tags
  )
  depends_on = [
    aws_nat_gateway.ngw
  ]
}

# Add route to NatGW's to the eks subnets route table (Routes dependant on NatGW variables selected)
resource "aws_route" "eks_nat_rt" {
  count                  = local.nat_gateway_count
  route_table_id         = element(aws_route_table.eks_route_tb[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.ngw[*].id, count.index)
  depends_on = [
    aws_route_table.eks_route_tb,
    aws_nat_gateway.ngw
  ]
}

# Associate eks subnets with route table
resource "aws_route_table_association" "eks_route_tb" {
  count          = length(var.eks_subnets) > 0 ? length(var.eks_subnets) : 0
  subnet_id      = element(aws_subnet.eks[*].id, count.index)
  route_table_id = aws_route_table.eks_route_tb[0].id
  depends_on = [
    aws_route_table.eks_route_tb
  ]
}

# Create the default VPC NACL
resource "aws_network_acl" "eks_nacl" {
  #checkov:skip=CKV_AWS_232
  #checkov:skip=CKV_AWS_229
  #checkov:skip=CKV_AWS_231
  #checkov:skip=CKV_AWS_230
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = aws_subnet.eks[*].id
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = merge(
    { Name = "${var.vpc_name}-eks-nacl" },
    var.defaultTags,
    var.vpc_tags
  )
  depends_on = [
    aws_subnet.eks
  ]
  lifecycle {
    ignore_changes = [subnet_ids]
  }
}

## Database Subnet Resources
# Create N # of database subnets based on the `database_subnets` values defined
resource "aws_subnet" "database" {
  count                   = length(var.database_subnets) > 0 && (length(var.database_subnets) >= length(var.azs)) ? length(var.database_subnets) : 0
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = element(concat(var.database_subnets, [""]), count.index)
  availability_zone       = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  map_public_ip_on_launch = false
  tags = merge(
    { Name = format(
      "${var.vpc_name}-database-%s",
      element(var.azs, count.index),
      )
    },
    var.defaultTags,
    var.vpc_tags
  )
  depends_on = [
    aws_vpc.vpc
  ]
}

#  Create database subnets route table
resource "aws_route_table" "database_route_tb" {
  count  = length(var.database_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    { Name = "${var.vpc_name}-database_rt" },
    var.defaultTags,
    var.vpc_tags
  )
  depends_on = [
    aws_nat_gateway.ngw
  ]
}

# Associate database subnets with route table
resource "aws_route_table_association" "database_route_tb" {
  count          = length(var.database_subnets) > 0 ? length(var.database_subnets) : 0
  subnet_id      = element(aws_subnet.database[*].id, count.index)
  route_table_id = aws_route_table.database_route_tb[0].id
  depends_on = [
    aws_route_table.database_route_tb
  ]
}

# Create the db subnet VPC NACL
resource "aws_network_acl" "db_nacl" {
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = aws_subnet.database[*].id
  ingress {
    protocol   = 6
    rule_no    = 1
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 3306
    to_port    = 3306
  }
  ingress {
    protocol   = 6
    rule_no    = 2
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1433
    to_port    = 1433
  }
  ingress {
    protocol   = 6
    rule_no    = 3
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 5432
    to_port    = 5432
  }
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = merge(
    { Name = "${var.vpc_name}-database-nacl" },
    var.defaultTags,
    var.vpc_tags
  )
  depends_on = [
    aws_subnet.database
  ]
  lifecycle {
    ignore_changes = [subnet_ids]
  }
}

## Flowlog Resources
# Create flowlog resources
resource "aws_flow_log" "cw-flowlog" {
  count                    = var.enable_flow_log ? 1 : 0
  iam_role_arn             = aws_iam_role.fl-role[0].arn
  log_destination          = aws_cloudwatch_log_group.cw-flowlog-loggroup[0].arn
  max_aggregation_interval = 60
  traffic_type             = "ALL"
  vpc_id                   = aws_vpc.vpc.id
  tags = merge(
    { Name = "${var.vpc_name}-cw-flowlog" },
    var.defaultTags,
    var.vpc_tags
  )
  depends_on = [
    aws_iam_role.fl-role
  ]
}

# Create KMS key for cloudwatch log encryption
resource "aws_kms_key" "cw-loggroup-key" {
  count                   = var.enable_flow_log ? 1 : 0
  description             = "Key for encrypting flowlogs logGroup"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.cloudwatch_key_policy.json
  tags = merge(
    var.defaultTags,
    var.vpc_tags
  )
}

# Make some calls to get needed values for the policy
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Define KMS Key Policy
data "aws_iam_policy_document" "cloudwatch_key_policy" {
  #checkov:skip=CKV_AWS_109
  #checkov:skip=CKV_AWS_111
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
  statement {
    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values = [
        "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"
      ]
    }
  }
}

# Create KMS Key alias
resource "aws_kms_alias" "cw-loggroup-key" {
  count         = var.enable_flow_log ? 1 : 0
  name          = "alias/${var.vpc_name}-flowlog-key"
  target_key_id = aws_kms_key.cw-loggroup-key[0].key_id
  depends_on = [
    aws_kms_key.cw-loggroup-key
  ]
}

# Create CloudWatch LogGroup
resource "aws_cloudwatch_log_group" "cw-flowlog-loggroup" {
  count             = var.enable_flow_log ? 1 : 0
  name              = "${var.vpc_name}-cw-logGroup"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cw-loggroup-key[0].arn
  tags = merge(
    var.defaultTags,
    var.vpc_tags
  )
  depends_on = [
    aws_vpc.vpc
  ]
}

# Create Flow Log role for pushing logs to CloudWatch
resource "aws_iam_role" "fl-role" {
  count              = var.enable_flow_log ? 1 : 0
  name               = "${var.vpc_name}-flowlog-role"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_role_trust_policy.json
  tags = merge(
    var.defaultTags,
    var.vpc_tags
  )
}

# Define FlowLog Role Trust Policy
data "aws_iam_policy_document" "cloudwatch_role_trust_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}

# Create FlowLog Role Policy
resource "aws_iam_policy" "fl-policy" {
  count       = var.enable_flow_log ? 1 : 0
  name        = "${var.vpc_name}-flowlog-policy"
  path        = "/"
  description = "cloudwatch policy for vpc flowlogs"
  policy      = data.aws_iam_policy_document.cloudwatch_role_policy[0].json
  tags = merge(
    var.defaultTags,
    var.vpc_tags
  )
  depends_on = [
    aws_cloudwatch_log_group.cw-flowlog-loggroup
  ]
}

# Define FlowLog Role Policy
data "aws_iam_policy_document" "cloudwatch_role_policy" {
  count = var.enable_flow_log ? 1 : 0
  statement {
    resources = ["${aws_cloudwatch_log_group.cw-flowlog-loggroup[0].arn}"]
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    effect = "Allow"
  }
}
# Attach FlowLog Role Policy to Role
resource "aws_iam_role_policy_attachment" "fl-policy-attach" {
  count      = var.enable_flow_log ? 1 : 0
  role       = aws_iam_role.fl-role[0].name
  policy_arn = aws_iam_policy.fl-policy[0].arn
  depends_on = [
    aws_iam_policy.fl-policy
  ]
}

# Create FlowLog to S3 in the Security Audit Account (For immutability)
resource "aws_flow_log" "s3-flowlog" {
  count                = var.enable_flow_log ? 1 : 0
  log_destination      = "arn:aws:s3:::<orgname>-${data.aws_region.current.name}-flowlogs"
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.vpc.id
  tags = merge(
    var.defaultTags,
    var.vpc_tags
  )
  depends_on = [
    aws_vpc.vpc
  ]
}

## Transit Gateway attachments Resources
# If tgw_attachment = true, create the attachment to the specified TGW in transit_gateway_id
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attachment" {
  count              = local.attach_tgw
  subnet_ids         = aws_subnet.private[*].id
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = aws_vpc.vpc.id
  tags = merge(
    var.defaultTags,
    var.vpc_tags
  )
  depends_on = [
    aws_subnet.private
  ]
}

# Add route to both the private route tables
resource "aws_route" "private_tgw_rt" {
  for_each               = { for x in local.tgw_routes : x.rtb_id => x.cidr }
  route_table_id         = each.value.rtb_id
  destination_cidr_block = each.value.cidr
  transit_gateway_id     = var.transit_gateway_id
  depends_on = [
    aws_route_table.private_route_tb,
    aws_ec2_transit_gateway_vpc_attachment.tgw_attachment
  ]
}

## VPC Peering Resources
# Create VPC Peering requests if specified in the vpc_peer var
resource "aws_vpc_peering_connection" "vpcx" {
  for_each    = var.vpc_peers
  vpc_id      = aws_vpc.vpc.id
  peer_vpc_id = each.value.peered_vpc
  auto_accept = true
  accepter {
    allow_remote_vpc_dns_resolution = true
  }
  requester {
    allow_remote_vpc_dns_resolution = true
  }
  tags = merge(
    { Name = "${var.vpc_name}-vpcx-peering" },
    var.defaultTags,
    var.vpc_tags
  )
}

# Add route to both the private route tables
resource "aws_route" "private_vpcx_rt" {
  for_each                  = { for x in local.vpcx_routes : x.rtb_id => x.cidr }
  route_table_id            = each.value.rtb_id
  destination_cidr_block    = each.value.cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpcx[0].id
  depends_on = [
    aws_route_table.private_route_tb,
    aws_vpc_peering_connection.vpcx
  ]
}

# Create VPC endpoint services if specified in the endpoints var
data "aws_vpc_endpoint_service" "vpce" {
  for_each     = var.endpoints
  service      = lookup(each.value, "service", null)
  service_name = lookup(each.value, "service_name", null)
  filter {
    name   = "service-type"
    values = [lookup(each.value, "service_type", "Interface")]
  }
}

# Create VPC endpoints if specified in the endpoints var
resource "aws_vpc_endpoint" "vpce" {
  for_each            = var.endpoints
  vpc_id              = aws_vpc.vpc.id
  service_name        = data.aws_vpc_endpoint_service.vpce[each.key].service_name
  vpc_endpoint_type   = lookup(each.value, "service_type", "Interface")
  auto_accept         = lookup(each.value, "auto_accept", null)
  security_group_ids  = lookup(each.value, "service_type", "Interface") == "Interface" ? distinct(concat(aws_security_group.vpce_sg.id, lookup(each.value, "security_group_ids", []))) : null
  subnet_ids          = lookup(each.value, "service_type", "Interface") == "Interface" ? distinct(concat(aws_subnet.private[*].id, lookup(each.value, "private_subnets", []))) : null
  route_table_ids     = concat(aws_route_table.private_route_tb[*].id, aws_route_table.eks_route_tb[*].id)
  private_dns_enabled = lookup(each.value, "service_type", "Interface") == "Interface" ? lookup(each.value, "private_dns_enabled", null) : null
  tags = merge(
    { Name = "${var.vpc_name}-${data.aws_vpc_endpoint_service.vpce[each.key].service_name}-vpce" },
    var.defaultTags,
    var.vpc_tags
  )
}

# Create Security Group for the VPC Endpoints
resource "aws_security_group" "vpce_sg" {
  vpc_id      = aws_vpc.vpc.id
  name        = "${var.vpc_name}-vpce-sg"
  description = "vpc endpoint sg for ${var.vpc_name}"
  dynamic "ingress" {
    for_each = var.vpce_security_group_ingress
    content {
      self             = lookup(ingress.value, "self", null)
      cidr_blocks      = compact(split(",", lookup(ingress.value, "cidr_blocks", "")))
      ipv6_cidr_blocks = compact(split(",", lookup(ingress.value, "ipv6_cidr_blocks", "")))
      prefix_list_ids  = compact(split(",", lookup(ingress.value, "prefix_list_ids", "")))
      security_groups  = compact(split(",", lookup(ingress.value, "security_groups", "")))
      description      = lookup(ingress.value, "description", null)
      from_port        = lookup(ingress.value, "from_port", 0)
      to_port          = lookup(ingress.value, "to_port", 0)
      protocol         = lookup(ingress.value, "protocol", "-1")
    }
  }
  tags = merge(
    { Name = "${var.vpc_name}-vpce-sg" },
    var.defaultTags,
    var.vpc_tags
  )
  depends_on = [
    aws_route_table.private_route_tb
  ]
}

# Create Rule allowing local access
resource "aws_security_group_rule" "vpce_sg_rule" {
  description       = "Allow local VPC to ingress"
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.vpc.cidr_block]
  security_group_id = aws_security_group.vpce_sg.id
  depends_on = [
    aws_security_group.vpce_sg
  ]
}
