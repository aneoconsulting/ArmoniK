variable "environment_name" {
  description = "Name of the triplet associated to this deployed environment"
  type = string
}

variable "prometheus_data_directory" {
  description = "Local directory to mount Prometheus's data from"
  type = string
  default = ""
}

variable "database_data_directory" {
  description = "Local directory to mount the database json files from"
  type = string
}

variable "notebook_volume" {
  description = "Local directory to use as the working directory for the jupyter environment"
  type = string
}