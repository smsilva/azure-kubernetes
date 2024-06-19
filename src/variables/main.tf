locals {
  script-name = "environment-variables"
}

data "external" "variables" {
  program = [
    "${path.module}/${local.script-name}",
    "--env", "HOME",
    "--env", "USER",
    "--env", "ARM_CLIENT_ID",
  ]
}

data "external" "azure" {
  program = ["${path.module}/azure"]
}

output "values" {
  value = data.external.variables.result
}

output "env_var_home_retrieved" {
  value = data.external.variables.result.HOME
}

output "arm_client_secret" {
  value     = data.external.azure.result.arm_client_secret
  sensitive = true
}
