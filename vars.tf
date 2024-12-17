locals {
  env_name      = split("-", terraform.workspace)[0]
  location_code = split("-", terraform.workspace)[1]
  global_obj    = yamldecode(file("cfg.global.yml"))
  location_obj  = yamldecode(file("cfg.location-${local.location_code}.yml"))
  env_obj       = yamldecode(file("cfg.env-${local.env_name}-${local.location_code}.yml"))
  cfg           = provider::deepmerge::mergo(local.global_obj, local.location_obj, local.env_obj)
  tags = {
    environment = local.env_name
    location    = local.location_code
    project     = local.cfg.project
  }
}

variable "mssql_server_admin_password" {
  sensitive   = true
  description = "from shell TF_VAR_mssql_server_admin_password"
}
