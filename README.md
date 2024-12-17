# Azure Terraform Sample

## Naming

- `${prefix}-${env_name}-${geo_codes[location]}-${resource_type}-${instance_index}`
- see: [resource_naming module](modules/resource_naming/outputs.tf)

## Select Workspace

```bash
export TF_WORKSPACE=ne-dev
```

- location and environment are parsed from workspace name by terraform
