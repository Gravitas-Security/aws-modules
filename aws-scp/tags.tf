variable "defaultTags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    tf_Managed  = "true"
    tf_module   = "github.com/cyberviking949/aws-modules/aws-scp"
  }
}