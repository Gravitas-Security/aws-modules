variable "policies" {
  type = map(object({
    description = string
    policy      = string
    attachments = any
  }))
  description = "A map of SCP policies to create."
  default     = {}
}

variable "custom_tags" {
    description = "A map of custom tags to add to all resources"
    type        = map(string)
    default     = {}
}
