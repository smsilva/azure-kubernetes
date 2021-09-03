module "kubernetes" {
  source = "../../src"

  platform_instance_name = "wasp-test-1234"
  cluster_version        = "1.20.7"
  admin_group_object_ids = ["d5075d0a-3704-4ed9-ad62-dc8068c7d0e1"]
}

output "kubernetes" {
  value     = module.kubernetes
  sensitive = true
}
