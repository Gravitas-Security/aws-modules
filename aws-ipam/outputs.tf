output "ipam" {
  value = aws_vpc_ipam.ipam
} 

output "ipam_scopes" {
  value = aws_vpc_ipam_scope.ipam_scopes
}

output "master_pool" {
  value = aws_vpc_ipam_pool.master-pool
}

output "master_cidr" {
  value = aws_vpc_ipam_pool_cidr.master_cidrs
}

output "dev_pool" {
  value = aws_vpc_ipam_pool.dev_pools
}

output "prod_pool" {
  value = aws_vpc_ipam_pool.prod_pools
}