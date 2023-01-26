variable "armonik_versions" {
  description = "Versions of all the ArmoniK components"
  type = object({
    infra     = string
    core      = string
    api       = string
    gui       = string
    extcsharp = string
    samples   = string
  })
}

variable "armonik_images" {
  description = "Image names of all the ArmoniK components"
  type = object({
    infra     = set(string)
    core      = set(string)
    api       = set(string)
    gui       = set(string)
    extcsharp = set(string)
    samples   = set(string)
  })
}

variable "image_tags" {
  description = "Tags of images used"
  type        = map(string)
}
