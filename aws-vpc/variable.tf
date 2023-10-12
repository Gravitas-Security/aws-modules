variable "region" {
  description = "Region where the environment will be there"
  type        = string
  default     = "us-west-2"
}

# VPC variables

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "range of CIDR"
  type        = string
  default     = ""
}

variable "secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks to associate with the VPC to extend the IP Address pool"
  type        = list(string)
  default     = []
}

variable "enable_flow_log" {
  description = "Whether or not to enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "vpc_tags" {
  description = "Additional tags for the VPC"
  type        = map(string)
  default     = {}
}

# Subnet variables
variable "azs" {
  description = "AZs present in the VPC"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]

}

variable "private_subnets" {
  description = "CIDR range for private subnets"
  type        = list(string)
  default     = [""]
}

variable "public_subnets" {
  description = "CIDR range for public subnets"
  type        = list(string)
  default     = [""]
}

variable "eks_subnets" {
  description = "CIDR range for eks subnets"
  type        = list(string)
  default     = [""]
}

variable "database_subnets" {
  description = "CIDR range for database subnets"
  type        = list(string)
  default     = [""]
}

# NatGW variables
variable "nat_gateway_destination_cidr_block" {
  description = "Used to pass a custom destination route for private NAT Gateway. If not specified, the default 0.0.0.0/0 is used as a destination route."
  type        = string
  default     = "0.0.0.0/0"
}

variable "natgw_per_az" {
  description = "Should be true if you want only one NAT Gateway per availability zone. Requires `var.azs` to be set, and the number of `public_subnets` created to be greater than or equal to the number of availability zones specified in `var.azs`."
  type        = bool
  default     = false
}

# Default SG variables

variable "default_security_group_ingress" {
  description = "List of maps of ingress rules to set on the default security group"
  type        = list(map(string))
  default     = []
}

variable "default_security_group_egress" {
  description = "List of maps of egress rules to set on the default security group"
  type        = list(map(string))
  default     = []
}

# TransitGateway attachment variables
variable "tgw_attachment" {
  description = "Should be true if a TGW attachment is needed"
  type        = bool
  default     = false
}

variable "transit_gateway_id" {
  description = "the TGW to attach too"
  type        = string
  default     = ""
}

variable "transit_gateway_routes" {
  description = "The list of networks to route over the TGW"
  type        = list(string)
  default     = []
}

# VPC peering attachment variables
variable "vpc_peers" {
  description = "A map of vpc peers containing their properties and configurations"
  type        = any
  default     = {}
}

variable "peered_vpc" {
  description = "the TGW to attach too"
  type        = string
  default     = ""
}

variable "vpc_peering_routes" {
  description = "The list of networks to route over the TGW"
  type        = list(string)
  default     = []
}

# VPC endpoints variables
variable "endpoints" {
  description = "A map of interface and/or gateway endpoints containing their properties and configurations"
  type        = any
  default     = {}
}

variable "vpce_security_group_ingress" {
  description = "List of maps of ingress rules to set on the vpce security group"
  type        = list(map(string))
  default     = []
}