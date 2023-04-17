data "cloudflare_zones" "khumps-dev" {
  filter {
    name = local.domain
  }
}

locals {
  domain             = "khumps.dev"
  khumps-dev-zone-id = data.cloudflare_zones.khumps-dev.zones[0]["id"]
}

// Root CNAME
resource "cloudflare_record" "khumps-dev" {
  zone_id = local.khumps-dev-zone-id
  name    = "@"
  type    = "CNAME"
  value   = "d4450d98716b.sn.mynetname.net"
}

// Plex
resource "cloudflare_record" "plex-khumps-dev" {
  zone_id = local.khumps-dev-zone-id
  name    = "plex"
  type    = "CNAME"
  value   = local.domain
}

// Status Page
resource "cloudflare_record" "status-khumps-dev" {
  zone_id = local.khumps-dev-zone-id
  name    = "status"
  type    = "CNAME"
  value   = "stats.uptimerobot.com"
}

// Knowhere
resource "cloudflare_record" "sonarr-khumps-dev" {
  zone_id = local.khumps-dev-zone-id
  name    = "sonarr"
  type    = "CNAME"
  value   = local.domain
}

resource "cloudflare_record" "radarr-khumps-dev" {
  zone_id = local.khumps-dev-zone-id
  name    = "radarr"
  type    = "CNAME"
  value   = local.domain
}

resource "cloudflare_record" "jackett-khumps-dev" {
  zone_id = local.khumps-dev-zone-id
  name    = "jackett"
  type    = "CNAME"
  value   = local.domain
}

resource "cloudflare_record" "plexpy-khumps-dev" {
  zone_id = local.khumps-dev-zone-id
  name    = "plexpy"
  type    = "CNAME"
  value   = local.domain
}

resource "cloudflare_record" "transmission-khumps-dev" {
  zone_id = local.khumps-dev-zone-id
  name    = "transmission"
  type    = "CNAME"
  value   = local.domain
}

// Planetside TK Tracker
resource "cloudflare_record" "tk-khumps-dev" {
  zone_id = local.khumps-dev-zone-id
  name    = "tk"
  type    = "CNAME"
  value   = local.domain
}

resource "cloudflare_record" "infra" {
  zone_id = local.khumps-dev-zone-id
  name    = "*.infra"
  type    = "CNAME"
  value   = local.domain
}

resource "cloudflare_record" "fish-khumps-dev" {
  zone_id = local.khumps-dev-zone-id
  name    = "fish"
  type    = "CNAME"
  value   = local.domain
}

resource "cloudflare_record" "vpn-khumps-dev" {
  zone_id = local.khumps-dev-zone-id
  name    = "vpn"
  type    = "CNAME"
  value   = local.domain
}

resource "cloudflare_record" "prometheus-khumps-dev" {
  zone_id = local.khumps-dev-zone-id
  name    = "prometheus"
  type    = "CNAME"
  value   = cloudflare_tunnel.singularity.cname
  proxied = true
}

resource "cloudflare_record" "grafana-khumps-dev" {
  zone_id = local.khumps-dev-zone-id
  name    = "grafana"
  type    = "CNAME"
  value   = cloudflare_tunnel.singularity.cname
  proxied = true
}

resource "cloudflare_record" "alertmanager-khumps-dev" {
  zone_id = local.khumps-dev-zone-id
  name    = "alertmanager"
  type    = "CNAME"
  value   = cloudflare_tunnel.singularity.cname
  proxied = true
}

resource "cloudflare_record" "longhorn-khumps-dev" {
  zone_id = local.khumps-dev-zone-id
  name    = "longhorn"
  type    = "CNAME"
  value   = cloudflare_tunnel.singularity.cname
  proxied = true
}
