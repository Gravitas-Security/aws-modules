module "vpc" {
  source = "../../aws"

  name            = "my-vpc"
  cidr            = "10.0.0.0/16"
  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"] # Optional, Defaults to `us-west-2a` & `us-west-2b`
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  eks_clustername = "my-awesome-cluster" # Variable to define the clusternames. these are applied to the tags on the public subnets
  enable_flow_log = true                 # Optional to create cloudwatch flowlog default = false
  tgw_attachment  = false                # Optional to create Transit Gateway attachment and its associated resources, default = false
  //transit_gateway_id = "tgw-abcdefg1234567"                        # Required if tgw_attachment = true, the ID of the TGW to attach too
  //transit_gateway_routes = ["10.x.x.x/16", "10.y.y.y/16"]          # Required if tgw_attachment = true, the CIDR's to route to the TGW
  vpc_peers = {                                 # Variables for defining VPC peerings
    vpc-123456789 = {                           # Required, Terraform resource block name for VPC peers (Supports multiple)
      peered_vpc         = "vpc-abcdefg1234567" # Required, vpcID of the peer
      vpc_peering_routes = ["172.31.0.0/16"]    # Required, CIDR's of the subnets in the peered VPC
    }
  }
  endpoints = { # Variables for defining VPC peerings
    /*s3 = {                                                         # Required, type of VPC Endpoint to create
      service         = "s3"
      private_dns_enabled = true
      service_type    = "Gateway"
      }*/
  }
  vpce_security_group_egress  = [] # Required if VPCe requires a Security-Group, array of egress rules for the VPCe (can typically be empty)
  vpce_security_group_ingress = [] # Required if VPCe requires a Security-Group, array of ingress rules for the VPCe (typically the local CIDR) 


  tags = {
    env         = "true"
    Environment = "dev"
  }
}
