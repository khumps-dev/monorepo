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
          args    = ["-address", "$(ADDRESS)", "-device", "$(DEVICE)", "-password", "$(PASSWORD)", "-user", "$(USERNAME)"]
          port {
            container_port = 9436
          }
          env {
            name = "ADDRESS"
            value_from {
              secret_key_ref {
                name = "mikrotik"
                key  = "address"
              }
            }
          }
          env {
            name = "DEVICE"
            value_from {
              secret_key_ref {
                name = "mikrotik"
                key  = "device"
              }
            }
          }
          env {
            name = "PASSWORD"
            value_from {
              secret_key_ref {
                name = "mikrotik"
                key  = "password"
              }
            }
          }
          env {
            name = "USERNAME"
            value_from {
              secret_key_ref {
                name = "mikrotik"
                key  = "username"
              }
            }
          }
        }
      }
    }
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
