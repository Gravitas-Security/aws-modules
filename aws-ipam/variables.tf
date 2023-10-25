variable "ipam_scopes" {
  type = map(object({
    description = string
    region = string
  }))
}