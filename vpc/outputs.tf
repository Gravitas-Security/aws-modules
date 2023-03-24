# VPC Outputs
output "vpc_name" {
  description = "The name of the VPC"
  value       = var.vpc_name
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.vpc.id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = aws_vpc.vpc.arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.vpc.cidr_block
}

output "default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value       = aws_vpc.vpc.default_security_group_id
}

output "default_route_table_id" {
  description = "The ID of the default route table"
  value       = aws_vpc.vpc.default_route_table_id
}

output "vpc_instance_tenancy" {
  description = "Tenancy of instances spin up within VPC"
  value       = aws_vpc.vpc.instance_tenancy
}

output "vpc_enable_dns_support" {
  description = "Whether or not the VPC has DNS support"
  value       = aws_vpc.vpc.enable_dns_support
}

output "vpc_enable_dns_hostnames" {
  description = "Whether or not the VPC has DNS hostname support"
  value       = aws_vpc.vpc.enable_dns_hostnames
}

output "vpc_main_route_table_id" {
  description = "The ID of the main route table associated with this VPC"
  value       = aws_vpc.vpc.main_route_table_id
}

output "vpc_secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks of the VPC"
  value       = compact(aws_vpc_ipv4_cidr_block_association.secondary_cidr[*].cidr_block)
}

output "vpc_owner_id" {
  description = "The ID of the AWS account that owns the VPC"
  value       = aws_vpc.vpc.owner_id
}

# Subnet Outputs
output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = aws_subnet.private[*].arn
}

output "private_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
  value       = compact(aws_subnet.private[*].cidr_block)
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnet_arns" {
  description = "List of ARNs of public subnets"
  value       = aws_subnet.public[*].arn
}

output "public_subnets_cidr_blocks" {
  description = "List of cidr_blocks of public subnets"
  value       = compact(aws_subnet.public[*].cidr_block)
}

output "eks_subnets" {
  description = "List of IDs of eks subnets"
  value       = aws_subnet.eks[*].id
}

output "eks_subnet_arns" {
  description = "List of ARNs of eks subnets"
  value       = aws_subnet.eks[*].arn
}

output "eks_subnets_cidr_blocks" {
  description = "List of cidr_blocks of eks subnets"
  value       = compact(aws_subnet.eks[*].cidr_block)
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = aws_subnet.database[*].id
}

output "database_subnet_arns" {
  description = "List of ARNs of database subnets"
  value       = aws_subnet.database[*].arn
}

output "database_subnets_cidr_blocks" {
  description = "List of cidr_blocks of database subnets"
  value       = compact(aws_subnet.database[*].cidr_block)
}

# Route Table outputs
output "public_route_table_ids" {
  description = "List of IDs of public route tables"
  value       = aws_route_table.public_route_tb[*].id
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = aws_route_table.private_route_tb[*].id
}

output "eks_route_table_ids" {
  description = "List of IDs of eks route tables"
  value       = aws_route_table.eks_route_tb[*].id
}

output "database_route_table_ids" {
  description = "List of IDs of database route tables"
  value       = aws_route_table.database_route_tb[*].id
}

output "public_internet_gateway_route_id" {
  description = "ID of the internet gateway route"
  value       = aws_route.public_internet_gateway[0].id
}

output "private_nat_gateway_route_ids" {
  description = "List of IDs of the private nat gateway route"
  value       = aws_route.private_nat_rt[*].id
}

output "eks_nat_gateway_route_ids" {
  description = "List of IDs of the eks nat gateway route"
  value       = aws_route.eks_nat_rt[*].id
}

output "private_route_table_association_ids" {
  description = "List of IDs of the private route table association"
  value       = aws_route_table_association.private_route_tb[*].id
}

output "public_route_table_association_ids" {
  description = "List of IDs of the public route table association"
  value       = aws_route_table_association.public_route_tb[*].id
}

output "eks_route_table_association_ids" {
  description = "List of IDs of the eks route table association"
  value       = aws_route_table_association.eks_route_tb[*].id
}

output "database_route_table_association_ids" {
  description = "List of IDs of the database route table association"
  value       = aws_route_table_association.database_route_tb[*].id
}

# NatGW Outputs
output "nat_ids" {
  description = "List of allocation ID of Elastic IPs created for AWS NAT Gateway"
  value       = aws_eip.nat[*].id
}

output "natgw_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.ngw[*].id
}

output "igw_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.igw.id
}

output "igw_arn" {
  description = "The ARN of the Internet Gateway"
  value       = aws_internet_gateway.igw.arn
}

# VPC flow log
output "vpc_s3_flow_log_id" {
  description = "The ID of the Flow Log resource"
  value       = aws_flow_log.s3-flowlog[*].id
}

output "vpc_flow_log_id" {
  description = "The ID of the Flow Log resource"
  value       = aws_flow_log.cw-flowlog[*].id
}

output "vpc_flow_log_destination_loggroup_arn" {
  description = "The ARN of the destination LogGroup for VPC Flow Logs"
  value       = aws_cloudwatch_log_group.cw-flowlog-loggroup[*].arn
}

output "vpc_flow_log_cloudwatch_iam_role_arn" {
  description = "The ARN of the IAM role used when pushing logs to Cloudwatch log group"
  value       = aws_iam_role.fl-role[*].arn
}

output "vpc_flow_log_iam_role_policy" {
  description = "The ARN of the IAM role used when pushing logs to Cloudwatch log group"
  value       = aws_iam_policy.fl-policy[*].arn
}

output "kms_key_id" {
  description = "KMS key created for Flowlog logGroup"
  value       = aws_kms_key.cw-loggroup-key[*].key_id
}

output "kms_key_alias" {
  description = "Alias for log key"
  value       = aws_kms_alias.cw-loggroup-key[*].name
}

# TGW Outputs

output "vpc_tgw" {
  description = "The ID of the TGW attached to the VPC"
  value       = var.transit_gateway_id
}

output "vpc_tgw_routes" {
  description = "The ID of the routes to the TGW"
  value       = aws_route.private_tgw_rt[*]
}

# VPCx Outputs

output "vpc_peers" {
  description = "The ID of the TGW attached to the VPC"
  value       = var.peered_vpc[*]
}

/*output "vpcx_id" {
  description = "The ID of the vpc attached to the VPC"
  value       = aws_vpc_peering_connection.vpcx[*].id
}*/

output "vpce_routes" {
  description = "The ID of the routes to the TGW"
  value       = aws_route.private_vpcx_rt[*]
}

# VPC Endpoint outputs
output "vpc_endpoints" {
  description = "Array containing the full resource object and attributes for all endpoints created"
  value       = aws_vpc_endpoint.vpce
}
output "vpce_security_group_id" {
  description = "The ID of the security group created for the vpc endpoint services"
  value       = aws_security_group.vpce_sg
}