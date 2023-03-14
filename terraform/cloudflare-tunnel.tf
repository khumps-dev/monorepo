resource "kubernetes_daemon_set_v1" "cloudflare-tunnel" {
  metadata {
    name      = "cloudflare-tunnel"
    namespace = "kube-system"
    labels = {
      tunnel-name = "Singularity"
      app         = "cloudflare-tunnel"
    }
  }
  spec {
    selector {
      match_labels = {
        app = "cloudflare-tunnel"
      }
    }

    template {
      metadata {
        labels = {
          app = "cloudflare-tunnel"
        }
      }
      spec {
        container {
          name  = "tunnel"
          image = "cloudflare/cloudflared:latest"
          args  = ["tunnel", "--no-autoupdate", "run", "--token", cloudflare_tunnel.singularity.tunnel_token]

          env {
            name = "TOKEN"
            value_from {
              secret_key_ref {
                name = "cloudflare-tunnel-token"
                key  = "token"
              }
            }
          }
        }
      }
    }
  }
}

resource "random_id" "argo_secret" {
  byte_length = 35
}

resource "cloudflare_tunnel" "singularity" {
  account_id = cloudflare_access_organization.knowhere.account_id
  name       = "Singularity"
  secret     = random_id.argo_secret.b64_std
}

resource "cloudflare_tunnel_config" "singularity" {
  account_id = cloudflare_access_organization.knowhere.account_id
  tunnel_id  = cloudflare_tunnel.singularity.id
  config {
    ingress_rule {
      hostname = cloudflare_record.prometheus-khumps-dev.hostname
      service  = "http://prometheus-k8s.monitoring:9090"
    }
    ingress_rule {
      hostname = cloudflare_record.grafana-khumps-dev.hostname
      service  = "http://grafana.monitoring:3000"
    }
    ingress_rule {
      hostname = cloudflare_record.alertmanager-khumps-dev.hostname
      service  = "http://alertmanager-main.monitoring:9093"
    }
    ingress_rule {
      service = "http_status:404"
    }
  }
}


