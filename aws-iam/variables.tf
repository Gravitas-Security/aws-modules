variable "roles" {
    description = "A map of roles to create in AWS SSO"
    type       = map(object({
        trusted_entity   = string
        instance_profile = optional(bool)
        session_duration = optional(number)
        policies = list(string)
    }))
    default = {}
}

variable "policies" {
    description = "A map of policies to create in AWS IAM"
    type       = map(object({
        path        = optional(string)
        description = string
        statement      = list(object({
            sid       = string
            effect    = string
            actions   = list(string)
            resources = list(string)
        }))
    }))
    default = {}
}

variable "custom_tags" {
    description = "A map of custom tags to add to all resources"
    type        = map(string)
    default     = {}
}
