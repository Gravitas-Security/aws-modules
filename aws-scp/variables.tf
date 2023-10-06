variable "policies" {
  type = map(object({
    description = string
    policy      = string
    attachments = any
  }))
  description = "A map of SCP policies to create."
  default     = {}
}