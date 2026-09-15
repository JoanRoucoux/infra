# Read-only: provider 2.19 rejects this VPS's model version (2027v1) in ovh_vps, and the resource
# would manage the subscription itself.
data "ovh_vps" "cairn" {
  service_name = var.vps_service_name
}
