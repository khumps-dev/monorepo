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

resource "kubernetes_manifest" "longhorn_prometheus_rules" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "longhorn-prometheus-rule"
      namespace = "longhorn-system"
    }
    spec = {
      groups = [
        { name = "longhorn.rules"
          rules = [
            { alert = "LonghornVolumeUsageCritical"
              annotations = { description = "Longhorn volume {{$labels.volume}} on {{$labels.node}} is at {{$value}}% used for more than 5 minutes."
              summary = "Longhorn volume capacity is over 90% used." }
              expr = "100 * (longhorn_volume_actual_size_bytes / longhorn_volume_capacity_bytes) > 90"
              for  = "5m"
              labels = { issue = " Longhorn volume {{$labels.volume}} usage on {{$labels.node}} is critical."
                severity = "critical"
              }
            }
          ]
        }
      ]
    }
  }
}
