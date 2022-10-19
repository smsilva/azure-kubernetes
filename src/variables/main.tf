variable "script" {
  default = "environment_variables"
}

data "external" "variables" {
  program = ["${path.module}/${var.script}.sh"]
}

output "values" {
  value = data.external.variables.result
}
