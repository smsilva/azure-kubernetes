resource "random_string" "id" {
  length      = 3
  min_lower   = 1
  min_numeric = 2
  lower       = true
  special     = false
}
