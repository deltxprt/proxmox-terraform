terraform {
  required_providers {
    dns = {
      source  = "hashicorp/dns"
      version = "3.2.4"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "3.14.0"
    }
  }
}

provider "vault" {}

data "vault_generic_secret" "dns-key"{
  path = "bind-dns/ns1"
}

variable "dns_data" {
    type = map(object({
        hostname = string
        ip   = string
    }))
}

provider "dns" {
  update {
    server        = "10.0.0.111"
    key_name      = "terraform-key."
    key_algorithm = "hmac-sha256"
    key_secret    = dns-key.data["tsig"]
  }
}

resource "dns_a_record_set" "lab" {
  zone      = "lab.markaplay.net."
  name      = local.dns_data.hostname
  addresses = local.dns_data.ip
  ttl       = 3600
}

resource "dns_ptr_record" "reverse_lab" {
  zone      = "0.0.10.in-addr.arpa."
  name = local.dns_data.ip
  ptr  = local.dns_data.hostname
  ttl  = 3600
}