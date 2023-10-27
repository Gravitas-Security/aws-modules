module "ipam" {
  source = "../../aws-ipam"

  ipam_sets = {
    "master" = {
      description = "The CIDRs to use for the aws org environment"
      ipam_pool   = "10.0.0.0/8"
      dev_cidrs    = "10.128.0.0/16"
      prod_cidrs   = "10.0.0.0/16"
      regions = ["us-west-2"]
    }
  }

  custom_tags = {
    repo = "github.com/stuff"
  }
}