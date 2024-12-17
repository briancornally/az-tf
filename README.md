# Azure Terraform Sample

## Naming Convention

`${prefix}-${env_name}-${location_code}-${resource_type}-${instance_index}`

see: [resource_naming module](modules/resource_naming/README.md)

## Select Workspace

```bash
export TF_WORKSPACE=ne-dev
```

- location and environment are parsed from workspace name by terraform
