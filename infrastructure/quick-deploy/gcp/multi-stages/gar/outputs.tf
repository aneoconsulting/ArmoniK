# GAR images
output "gar" {
  value = {
    repositories = module.gar.docker_repositories
  }
}