locals {
  hosts     = toset(["", "www", "cairn", "status", "metrics"])
  caa_hosts = setsubtract(local.hosts, ["www"])
}

resource "ovh_domain_zone_record" "host_a" {
  for_each = local.hosts

  zone      = var.zone
  subdomain = each.key
  fieldtype = "A"
  ttl       = 3600
  target    = var.vps_ipv4
}

resource "ovh_domain_zone_record" "host_caa" {
  for_each = local.caa_hosts

  zone      = var.zone
  subdomain = each.key
  fieldtype = "CAA"
  ttl       = 3600
  target    = "0 issue \"letsencrypt.org\""
}
