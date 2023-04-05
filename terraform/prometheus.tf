locals {
  ns = "monitoring"
}

resource "cloudflare_access_application" "prometheus" {
  account_id = cloudflare_access_organization.knowhere.account_id
  name       = "Prometheus"
  domain     = cloudflare_record.prometheus-khumps-dev.hostname
}

resource "cloudflare_access_policy" "prometheus" {
  account_id     = cloudflare_access_organization.knowhere.account_id
  application_id = cloudflare_access_application.prometheus.id
  name           = "allow admins"
  precedence     = 1
  decision       = "allow"
  include {
    group = [cloudflare_access_group.admin.id]
  }
}

resource "cloudflare_access_application" "grafana" {
  account_id = cloudflare_access_organization.knowhere.account_id
  name       = "Grafana"
  domain     = cloudflare_record.grafana-khumps-dev.hostname
}

resource "cloudflare_access_policy" "grafana" {
  account_id     = cloudflare_access_organization.knowhere.account_id
  application_id = cloudflare_access_application.grafana.id
  name           = "allow admins"
  precedence     = 1
  decision       = "allow"
  include {
    group = [cloudflare_access_group.admin.id]
  }
}

resource "cloudflare_access_application" "alertmanager" {
  account_id = cloudflare_access_organization.knowhere.account_id
  name       = "Alert Manager"
  domain     = cloudflare_record.alertmanager-khumps-dev.hostname
}

resource "cloudflare_access_policy" "alertmanager" {
  account_id     = cloudflare_access_organization.knowhere.account_id
  application_id = cloudflare_access_application.alertmanager.id
  name           = "allow admins"
  precedence     = 1
  decision       = "allow"
  include {
    group = [cloudflare_access_group.admin.id]
  }
}
