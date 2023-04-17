resource "kubernetes_manifest" "longhorn_monitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "longhorn"
      namespace = "longhorn-system"
      labels = {
        name = "longhorn"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = "longhorn-manager"
        }
      }
      endpoints = [
        {
          port          = "manager"
          interval      = "60s"
          scrapeTimeout = "45s"
        }
      ]
    }
  }
}
