variable "hostname" {
  type = string
}
variable "description" {
  type = string
}
variable "template" {
  type = string
}
variable "unprivileged" {
  type    = bool
  default = true
}
variable "size" {
  type    = string
  default = "small"
}
variable "onboot" {
  type    = bool
  default = true
}
variable "start" {
  type    = bool
  default = true
}
variable "ssh_public_keys" {
  type = string
}
variable "ip_address" {
  type = string
}