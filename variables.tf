variable "region" {
    type = string
    default = "us-central1"
}
variable "project" {
    type = string
}

variable "user" {
    type = string
}

variable "email" {
    type = string
}
variable "privatekeypath" {
    type = string
    default = "~/.ssh/id_rsa"
}

variable "publickeypath" {
    type = string
    default = "~/.ssh/id_rsa.pub"
}

variable "domain" {
    type = string
}

variable "network_self_link" {
  description = "Self link of the network that will be allowed to query the zone."
  default     = ""
}

variable "URL" {
    type = string
}