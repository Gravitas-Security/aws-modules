# AWS VPC Terraform module

Terraform module which creates VPC resources on AWS.

## Usage

```hcl
module "vpc" {
  source = "../../aws"

  name                 = "my-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = ["us-west-2a", "us-west-2b", "us-west-2c"]  # Optional, Defaults to `us-west-2a` & `us-west-2b`
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets       = ["10.0.101.0/24", "10.0.102.0/24"]
  eks_clustername      = "my-awesome-cluster"                        # Variable to define the clusternames. these are applied to the tags on the public subnets
  enable_flow_log      = true                                        # Optional to create cloudwatch flowlog default = false
  tgw_attachment = false                                             # Optional to create Transit Gateway attachment and its associated resources, default = false
  //transit_gateway_id = "tgw-abcdefg1234567"                        # Required if tgw_attachment = true, the ID of the TGW to attach too
  //transit_gateway_routes = ["10.x.x.x/16", "10.y.y.y/16"]          # Required if tgw_attachment = true, the CIDR's to route to the TGW
  vpc_peers = {                                                      # Variables for defining VPC peerings
    vpc-123456789 = {                                                # Required, Terraform resource block name for VPC peers (Supports multiple)
        peered_vpc = "vpc-abcdefg1234567"                            # Required, vpcID of the peer
        vpc_peering_routes = ["172.31.0.0/16"]                       # Required, CIDR's of the subnets in the peered VPC
    }
  }
  endpoints = {                                                      # Variables for defining VPC peerings
    /*s3 = {                                                         # Required, type of VPC Endpoint to create
      service         = "s3"
      private_dns_enabled = true
      service_type    = "Gateway"
      }*/
    }
  vpce_security_group_egress = []                                    # Required if VPCe requires a Security-Group, array of egress rules for the VPCe (can typically be empty)
  vpce_security_group_ingress = []                                   # Required if VPCe requires a Security-Group, array of ingress rules for the VPCe (typically the local CIDR) 


  tags = {
    env = "true"
    Environment = "dev"
  }
}
```

## VPC Flow Log

VPC Flow Log allows to capture IP traffic for a specific network interface (ENI), subnet, or entire VPC. This module supports enabling or disabling VPC Flow Logs for entire VPC. If you need to have VPC Flow Logs for subnet or ENI, you have to manage it outside of this module with [aws_flow_log resource](https://www.terraform.io/docs/providers/aws/r/flow_log.html).

### VPC Flow Log configs

- File format is plain-text
- Destination is a CloudWatch LogGroup
  - LogGroup is encrypted with KMS key (created in this module)
- Role & Policy created for the FlowLog service

## Transit Gateway (TGW) integration

This module supports TransitGateway connection with the `tgw_attachment = true` bool. If specified, then additional variables are required. NOTE: Only attaching `private_subnets` is supported

```
tgw_attachment = true
transit_gateway_id = "tgw-abcdefg12345678
transit_gateway_routes = ["10.x.x.x/24", "10.y.y.y/24"]
```

Where `transit_gateway_id` is the ID of the TGW shared with the account && `Transit_gateway_routes` is the CIDR's you want routed to the TGW in each `private_subnet`

## VPC peering (VPCx) integration

This module supports VPC peering connection with the `vpc_peers = {}` block. If specified, then additional variables are required. NOTE: Only attaching `private_subnets` is supported

```
vpc_peers = {
    vpc-abcdef1234567 = {
        peered_vpc = "vpc-abcdef1234567"
        vpc_peering_routes = ["x.x.x.x/x"]
    }
  }
```

Where `peered_vpc` is the ID of the VPC to be peered with (acceptor) && `vpc_peering_routes` is the CIDR's you want routed to the VPCx in each `private_subnet`

## VPC Endpoints (VPCe) integration

This module supports VPC endpoints connection with the `endpoints = {}` block. If specified, then additional variables are required. NOTE: Only attaching `private_subnets` is supported

```
endpoints = {
    s3 = {
      service         = "s3"
      private_dns_enabled = true
      service_type    = "Gateway"
      }*/
    }
  vpce_security_group_egress = []
  vpce_security_group_ingress = []
```

Where `vpce_security_group_egress` && `vpce_security_group_ingress` are groups of Security Group rules to apply to the VPC endpoint SG


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.8 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.16 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.16 |

## Modules

No modules.