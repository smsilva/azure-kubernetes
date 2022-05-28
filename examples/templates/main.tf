locals {
  user_data = templatefile("template.yaml",
    {
      nameservers = [
        "server1",
        "server2"
      ]
    }
  )
}

output "user_data" {
  value = local.user_data
}
