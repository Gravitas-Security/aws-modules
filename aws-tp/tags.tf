variable "defaultTags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    owner       = "something"
    cost-centre = "something"
    contact     = "something"
    tf_Managed  = "true"
    tf_module   = "github.com/cyberviking949/aws-modules/aws-scp"
  }
}