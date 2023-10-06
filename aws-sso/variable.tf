variable "roles" {
  description = "Roles to be deployed into organizational accounts"
  type = any
  default = {
    session_duration = "PT2H"
    relay_state      = null
  }
}

variable "identitystore_group_depends_on" {
  description = "A list of parameters to use for data resources to depend on. This is a workaround to avoid module depends_on as that will recreate the module resources in many unexpected situations"
  type        = list(string)
  default     = []
}

variable "custom_tags" {
  description = "Additional tags for the resource"
  type        = map(string)
  default     = {}
}