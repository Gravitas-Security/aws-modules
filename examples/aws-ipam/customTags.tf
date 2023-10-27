variable "customTags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {}
}