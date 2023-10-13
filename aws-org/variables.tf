variable "aws_accounts" {
  type = map(object({
    email                      = string
    ou                         = string
    iam_user_access_to_billing = optional(string)
    close_on_delete            = optional(bool)
    access_principals          = optional(list(string))
    role_name                  = optional(string)
  }))
  default = {}
}

variable "ous" {
  type = map(object({
    description = string
  }))
  default = {}
}

variable "policies" {
  type = map(object({
    description = string
    attachments = any
  }))
  description = "A map of SCP policies to create."
  default     = {}
}

variable "tag_policies" {
  type = map(object({
    description = string
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