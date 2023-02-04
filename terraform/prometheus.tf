locals {
  ns = "monitoring"
}

# resource "helm_release" "prometheus" {
#   repository       = "https://prometheus-community.github.io/helm-charts"
#   chart            = "kube-prometheus-stack"
#   name             = "prometheus"
#   namespace        = "monitoring"
#   create_namespace = true
#   force_update     = true
#   set {
#     name  = "alertmanager.ingress.enabled"
#     value = "true"
#   }
#   set {
#     name  = "alertmanager.ingress.ingressClassName"
#     value = "public"
#   }
#   set {
#     name  = "alertmanager.ingress.hosts[0]"
#     value = "alertmanager.internal.khumps.dev"
#   }
#   set {
#     name  = "alertmanager.ingress.tls[0].secretName"
#     value = "alertmanager-internal-khumps-dev-tls-acme"
#   }
#   set {
#     name  = "alertmanager.ingress.tls[0].hosts[0]"
#     value = "alertmanager.internal.khumps.dev"
#   }
#   set {
#     name  = "alertmanager.ingress.paths"
#     value = "{/}"
#   }
#   set {
#     name  = "alertmanager.ingress.pathType"
#     value = "Prefix"
#   }

#   set {
#     name  = "grafana.ingress.enabled"
#     value = "true"
#   }

#   set {
#     name  = "grafana.ingress.ingressClassName"
#     value = "public"
#   }
#   set {
#     name  = "grafana.ingress.hosts[0]"
#     value = "grafana.internal.khumps.dev"
#   }
#   set {
#     name  = "grafana.ingress.tls[0].secretName"
#     value = "grafana-internal-khumps-dev-tls-acme"
#   }
#   set {
#     name  = "grafana.ingress.tls[0].hosts[0]"
#     value = "grafana.internal.khumps.dev"
#   }
#   set {
#     name  = "grafana.ingress.paths"
#     value = "{/}"
#   }
#   set {
#     name  = "grafana.ingress.pathType"
#     value = "Prefix"
#   }
# }

# resource "kubernetes_manifest" "alertmanager-cert" {
#   manifest = {
#     apiVersion = "cert-manager.io/v1"
#     kind       = "Certificate"
#     metadata = {
#       name      = "alertmanager-internal-khumps-dev"
#       namespace = "monitoring"
#     }
#     spec = {
#       secretName = "alertmanager-internal-khumps-dev-tls-acme"
#       issuerRef = {
#         name = "letsencrypt-prod"
#         kind = "ClusterIssuer"
#       }
#       dnsNames = [
#         "alertmanager.internal.khumps.dev"
#       ]
#     }
#   }
# }

# resource "kubernetes_manifest" "grafana-cert" {
#   manifest = {
#     apiVersion = "cert-manager.io/v1"
#     kind       = "Certificate"
#     metadata = {
#       name      = "grafana-internal-khumps-dev"
#       namespace = "monitoring"
#     }
#     spec = {
#       secretName = "grafana-internal-khumps-dev-tls-acme"
#       issuerRef = {
#         name = "letsencrypt-prod"
#         kind = "ClusterIssuer"
#       }
#       dnsNames = [
#         "grafana.internal.khumps.dev"
#       ]
#     }
#   }
# }

resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_manifest" "prometheus" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "Prometheus"
    metadata = {
      name      = "prometheus"
      namespace = "monitoring"
    }
    spec = {
      serviceMonitorSelector = {
        matchLabels = {
          app = "plex"
        }
      }
      storage = {
        volumeClaimTemplate = {
          spec = {
            storageClassName = local.storage_class_name
            resources = {
              requests = {
                storage = "120Gi"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_manifest" "plex_monitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "plex"
      namespace = "monitoring"
      labels = {
        app = "plex"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = "plex"
        }
      }
      endpoints = [
        {
          port = "exporter"
        }
      ]
      namespaceSelector = {
        matchNames = [
          "plex"
        ]
      }
    }
  }
}
