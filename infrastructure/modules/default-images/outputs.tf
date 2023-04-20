output "armonik_versions" {
  description = "Versions of all the ArmoniK components"
  value       = var.armonik_versions
}

output "image_tags" {
  description = "Tags of images used"
  value = merge({
    for image in var.armonik_images.infra :
    image => var.armonik_versions.infra
    }, {
    for image in var.armonik_images.core :
    image => var.armonik_versions.core
    }, {
    for image in var.armonik_images.api :
    image => var.armonik_versions.api
    }, {
    for image in var.armonik_images.gui :
    image => var.armonik_versions.gui
    }, {
    for image in var.armonik_images.extcsharp :
    image => var.armonik_versions.extcsharp
    }, {
    for image in var.armonik_images.samples :
    image => var.armonik_versions.samples
  }, var.image_tags)
}
