variable "url" {
  type = string
  default = "https://argocd.example.com"
}

output "validation" {
  value = regexall("(^http)(s?)://", var.url)
}
