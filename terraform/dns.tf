locals {
  # Only the names that point at the VPS. The apex, www and MX serve OVH web hosting and mail.
  hosts = toset(["cairn", "status", "metrics"])
}

resource "ovh_domain_zone_record" "host_a" {
  for_each = local.hosts

  zone      = var.zone
  subdomain = each.key
  fieldtype = "A"
  ttl       = 3600
  target    = var.vps_ipv4
}

# On each subdomain rather than the apex, where it would also bind OVH web hosting's certificates.
resource "ovh_domain_zone_record" "host_caa" {
  for_each = local.hosts

  zone      = var.zone
  subdomain = each.key
  fieldtype = "CAA"
  ttl       = 3600
  target    = "0 issue \"letsencrypt.org\""
}
