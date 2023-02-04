locals {
  plex_name          = "plex"
  plex_port          = 32400
  plex_exporter_port = 9594
}
resource "kubernetes_namespace" "plex" {
  metadata {
    name = local.plex_name
    labels = {
      monitoring = true
    }
  }
}

resource "kubernetes_deployment" "plex" {
  metadata {
    name = local.plex_name
    labels = {
      app = local.plex_name
    }
    namespace = local.plex_name
  }
  spec {
    replicas = 1
    strategy {
      type = "Recreate"
    }
    selector {
      match_labels = {
        app : local.plex_name
      }
    }
    template {
      metadata {
        labels = {
          app = local.plex_name
        }
      }
      spec {
        affinity {
          node_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 1
              preference {
                match_expressions {
                  key      = "hasQuickSync"
                  operator = "In"
                  values   = ["true"]
                }
              }
            }
          }
        }
        container {
          name  = "plex"
          image = "plexinc/pms-docker:1.30.2.6563-3d4dc0cce"
          port {
            container_port = local.plex_port
          }
          volume_mount {
            mount_path = "/config"
            name       = "plex-config"
          }
          volume_mount {
            mount_path = "/tv"
            name       = "plex"
            sub_path   = "TV"
          }
          volume_mount {
            mount_path = "/anime"
            name       = "plex"
            sub_path   = "Anime(Waifu Porn)"
          }
          volume_mount {
            mount_path = "/movies"
            name       = "plex"
            sub_path   = "Movies"
          }
          resources {
            limits = {
              "gpu.intel.com/i915" = 1
            }
          }
          env {
            name  = "PLEX_CLAIM"
            value = "claim-mC2-yonk2ULQ_Y819NB7"
          }
          //		  env {
          //			name = "DEBUG"
          //			value = "true"
          //		  }
          env {
            name  = "ADVERTISE_IP"
            value = "http://192.168.2.254:32400"
          }
          //		  env {
          //			name = "CHANGE_CONFIG_DIR_OWNERSHIP"
          //			value = "true"
          //		  }
          readiness_probe {
            http_get {
              path   = "identity"
              port   = "32400"
              scheme = "HTTPS"
            }
            initial_delay_seconds = 60
            period_seconds        = 20
          }

          liveness_probe {
            http_get {
              path   = "identity"
              port   = "32400"
              scheme = "HTTPS"
            }
            initial_delay_seconds = 60
            period_seconds        = 20
          }
        }
        container {
          name  = "exporter"
          image = "granra/plex_exporter"
          env {
            name = "TOKEN"
            value_from {
              secret_key_ref {
                name = "auth-token"
                key  = "token"
              }
            }
          }
          args = ["--token", "$(TOKEN)", "--config-path", "/config/config.yaml"]

          liveness_probe {
            http_get {
              path   = "health"
              port   = local.plex_exporter_port
              scheme = "HTTP"
            }
            initial_delay_seconds = 45
            period_seconds        = 15
          }
          volume_mount {
            mount_path = "/config"
            name       = "exporter-config"
          }
        }

        volume {
          name = "plex-config"
          iscsi {
            iqn           = "iqn.2021-06.freenas.fishnet:plex"
            target_portal = "192.168.2.5:3260"
            lun           = 5
            fs_type       = "ext4"
          }
        }
        volume {
          name = "plex"
          nfs {
            path   = "/mnt/Main/kevin/Plex"
            server = "192.168.2.5"
          }
        }
        volume {
          name = "exporter-config"
          config_map {
            name = kubernetes_config_map_v1.plex-exporter.metadata[0].name
          }
        }

      }
    }
  }
}

resource "kubernetes_config_map_v1" "plex-exporter" {
  metadata {
    generate_name = "exporter-config"
    namespace     = local.plex_name
  }
  data = {
    "config.yaml" = yamlencode(
      {
        autoDiscover = false
        # logLevel     = "debug"
        servers = [
          {
            baseUrl  = "https://plex:32400"
            insecure = true
          }
        ]
    })
  }
}

resource "kubernetes_ingress_v1" "plex" {
  metadata {
    name      = "http-ingress"
    namespace = local.plex_name
    annotations = {
      "kubernetes.io/tls-acme"                       = "true"
      "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS"
    }
  }
  spec {
    ingress_class_name = "public"
    tls {
      hosts = [
        "plex.khumps.dev"
      ]
      secret_name = "plex-khumps-dev-tls-acme"
    }
    rule {
      host = "plex.khumps.dev"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = local.plex_name
              port {
                number = local.plex_port
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "plex" {
  metadata {
    name      = local.plex_name
    namespace = local.plex_name
    labels = {
      app = "plex"
    }
  }
  spec {
    selector = {
      app : local.plex_name
    }
    port {
      name = "http"
      port = local.plex_port
    }
    port {
      name = "exporter"
      port = local.plex_exporter_port
    }
  }
}
