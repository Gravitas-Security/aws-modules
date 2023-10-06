variable "defaultTags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    owner       = "something"
    cost-centre = "something"
    contact     = "something"
    tf_managed  = "true"
  }
}