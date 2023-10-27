output "ipam" {
  value = module.ipam.ipam
} 

output "ipam_scopes" {
  value = module.ipam.ipam_scopes
}

output "master_pool" {
  value = module.ipam.master_pool
}

output "master_cidr" {
  value = module.ipam.master_cidr
}

output "dev_pool" {
  value = module.ipam.dev_pool
}

output "prod_pool" {
  value = module.ipam.prod_pool
}