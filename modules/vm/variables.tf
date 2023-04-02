variable "hostname" {
  type = string
}
variable "description" {
  type = string
}
variable "os" {
  type = string
}
variable "size" {
  type    = string
  default = "small"
}
variable "ip_address" {
  type = string
}
variable "tags" {
  type = list(string)
}