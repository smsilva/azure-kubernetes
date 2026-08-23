# local.arm_client_secret is used by this example's external-secrets module
# (pre-workload-identity, client_secret-based auth). examples/common/variables.tf
# no longer computes it, since istio doesn't need it and shouldn't pay for
# the data "external" call on every plan.

module "variables" {
  source = "../../src/variables"
  script = "azure"
}

locals {
  arm_client_secret = module.variables.arm_client_secret
}
