terraform {
  required_version = "~> 1.16"

  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "~> 2.19"
    }
  }

  cloud {
    organization = "joanroucoux"

    workspaces {
      name = "infra"
    }
  }
}

# Credentials come from OVH_APPLICATION_KEY, OVH_APPLICATION_SECRET and OVH_CONSUMER_KEY.
provider "ovh" {
  endpoint = "ovh-eu"
}
