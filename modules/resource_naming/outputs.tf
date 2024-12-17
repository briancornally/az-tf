output "name" {
  value = "${var.prefix}-${var.env_name}-${local.builtin_azure_backup_geo_codes[var.location]}-${var.resource_type}-${var.instance_index}"
}
