variable "ipam_sets" {
  description = "The CIDR to use for the dev environment"
  type = map(object({
    description   = string
    ipam_pool     = string
    dev_cidrs      = string
    prod_cidrs     = string
    regions   = list(string)
  }))
  default = {}
}

variable "custom_tags" {
  description = "Additional tags for the resource"
  type        = map(string)
  default     = {}
}
