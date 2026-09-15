variable "zone" {
  type    = string
  default = "joanroucoux.fr"
}

variable "vps_ipv4" {
  type    = string
  default = "51.255.42.146"
}

variable "vps_service_name" {
  type    = string
  default = "vps-8ce15b10.vps.ovh.net"
}

variable "firewall_enabled" {
  description = "Rules are reviewed while this is false; a missing rule locks SSH out once true."
  type        = bool
  default     = false
}
