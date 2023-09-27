# variable "permission_sets" {
#   description = "Map of maps containing Permission Set names as keys. See permission_sets description in README for information about map values."
#   type        = any
#   default = {
#     AdministratorAccess = {
#       description      = "Provides full access to AWS services and resources.",
#       session_duration = "PT2H",
#       managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
#     }
#   }
# }

# variable "account_assignments" {
#   description = "List of maps containing mapping between user/group, permission set and assigned accounts list. See account_assignments description in README for more information about map values."
#   type = list(object({
#     principal_name = string,
#     principal_type = string,
#     permission_set = string,
#     account_ids    = list(string)
#   }))

#   default = []
# }


variable "roles" {
  description = "Roles to be deployed into organizational accounts"
  type = any
}

variable "identitystore_group_depends_on" {
  description = "A list of parameters to use for data resources to depend on. This is a workaround to avoid module depends_on as that will recreate the module resources in many unexpected situations"
  type        = list(string)
  default     = []
}