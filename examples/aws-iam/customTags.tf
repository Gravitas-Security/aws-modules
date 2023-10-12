variable "customTags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    repo       = "https://github.com/cyberviking949/aws-infra/aws-iam"
  }
}