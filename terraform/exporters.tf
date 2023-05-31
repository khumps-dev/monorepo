resource "kubernetes_namespace_v1" "exporters" {
  metadata {
    name = "exporters"
  }
}
resource "kubernetes_deployment_v1" "mikrotik_exporter" {
  metadata {
    name      = "mikrotik"
    namespace = "exporters"
    labels = {
      service = "exporters"
      kind    = "mikrotik"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        service = "exporters"
        kind    = "mikrotik"
      }
    }
    template {
      metadata {
        labels = {
          service = "exporters"
          kind    = "mikrotik"
        }
      }


      spec {
        container {
          name    = "exporter"
          image   = "nshttpd/mikrotik-exporter:1.0.12-DEVEL"
          command = ["/app/mikrotik-exporter"]
          args    = ["-config-file", "/config/config.yaml"]
          port {
            container_port = 9436
          }
          volume_mount {
            mount_path = "/config"
            name       = "exporter-config"
          }
        }
        volume {
          name = "exporter-config"
          config_map {
            name = kubernetes_config_map_v1.mikrotik-exporter.metadata[0].name
          }
        }
      }
    }
  }
}

variable "mikrotik_password" {
  type        = string
  description = "api password for mikrotik router"
  sensitive   = true
}

resource "kubernetes_config_map_v1" "mikrotik-exporter" {
  metadata {
    generate_name = "mikrotik-exporter"
    namespace     = "exporters"
  }

  data = {
    "config.yaml" = yamlencode({
      devices = [
        {
          name     = "r01.khumps.dev"
          address  = "192.168.2.1"
          user     = "prometheus"
          password = var.mikrotik_password
        },
        {
          name     = "sw01.khumps.dev"
          address  = "192.168.2.2"
          user     = "prometheus"
          password = var.mikrotik_password
        }
      ]

      features = {
        dhcp   = true,
        routes = true,
        pools  = true,
        optics = true
    } })
  }
}

resource "kubernetes_service_v1" "mikrotik_exporter" {
  metadata {
    name      = "mikrotik"
    namespace = "exporters"
    labels = {
      service = "exporters"
      kind    = "mikrotik"
    }
  }

  spec {
    selector = {
      service = "exporters"
      kind    = "mikrotik"
    }

    port {
      name = "exporter"
      port = 9436
    }
  }
}

resource "kubernetes_manifest" "mikrotik_monitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "mikrotik"
      namespace = "exporters"
      labels = {
        service = "exporters"
        kind    = "mikrotik"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          service = "exporters"
          kind    = "mikrotik"
        }
      }
      endpoints = [
        {
          port = "exporter"
        }
      ]
    }
  }
}
