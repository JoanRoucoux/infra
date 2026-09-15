locals {
  # The OVH network firewall is stateless: UDP replies to the server's own DNS and NTP queries
  # must be permitted explicitly, or apt, Docker pulls and Let's Encrypt stop resolving.
  # It filters IPv4 only; IPv6 is left to ufw.
  firewall_rules = {
    "0"  = { action = "permit", protocol = "tcp", destination_port = null, source_port = null, tcp_option = "established" }
    "1"  = { action = "permit", protocol = "tcp", destination_port = 22, source_port = null, tcp_option = null }
    "2"  = { action = "permit", protocol = "tcp", destination_port = 80, source_port = null, tcp_option = null }
    "3"  = { action = "permit", protocol = "tcp", destination_port = 443, source_port = null, tcp_option = null }
    "4"  = { action = "permit", protocol = "udp", destination_port = null, source_port = 53, tcp_option = null }
    "5"  = { action = "permit", protocol = "udp", destination_port = null, source_port = 123, tcp_option = null }
    "6"  = { action = "permit", protocol = "icmp", destination_port = null, source_port = null, tcp_option = null }
    "19" = { action = "deny", protocol = "ipv4", destination_port = null, source_port = null, tcp_option = null }
  }
}

resource "ovh_ip_firewall" "vps" {
  ip             = "${var.vps_ipv4}/32"
  ip_on_firewall = var.vps_ipv4
  enabled        = var.firewall_enabled
}

resource "ovh_ip_firewall_rule" "vps" {
  for_each = local.firewall_rules

  ip               = ovh_ip_firewall.vps.ip
  ip_on_firewall   = ovh_ip_firewall.vps.ip_on_firewall
  sequence         = tonumber(each.key)
  action           = each.value.action
  protocol         = each.value.protocol
  destination_port = each.value.destination_port
  source_port      = each.value.source_port
  tcp_option       = each.value.tcp_option
}
