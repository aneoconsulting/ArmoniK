# List of storage resources
variable "storage" {
  description = "List of needed storage for each data type"
  type        = object({
    object         = string
    table          = string
    queue          = string
    lease_provider = string
    shared         = string
    external       = string
  })
}