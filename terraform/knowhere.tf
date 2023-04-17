locals {
  flaresolverr-name  = "flaresolverr"
  flaresolverr-port  = 8191
  jackett-name       = "jackett"
  jackett-port       = 9117
  knowhere_namespace = "knowhere"
  plexpy-name        = "plexpy"
  plexpy-port        = 8181
  radarr-name        = "radarr"
  radarr-port        = 7878
  sonarr-name        = "sonarr"
  sonarr-port        = 8989
  transmission-name  = "transmission"
  transmission-port  = 9091
}

resource "kubernetes_namespace" "knowhere" {
  metadata {
    name = local.knowhere_namespace
  }
}

# Ingress
resource "kubernetes_ingress_v1" "knowhere" {
  metadata {
    name      = "http-ingress"
    namespace = local.knowhere_namespace
    annotations = {
      "nginx.ingress.kubernetes.io/auth-type"   = "basic"
      "nginx.ingress.kubernetes.io/auth-secret" = "default/basic-auth"
      "nginx.ingress.kubernetes.io/auth-realm"  = "Authentication Required - Singularity"
      "kubernetes.io/tls-acme"                  = "true"
    }
  }
  spec {
    ingress_class_name = "public"
    tls {
      hosts = [
        "sonarr.khumps.dev",
        "radarr.khumps.dev",
        "jackett.khumps.dev",
        "plexpy.khumps.dev",
        "transmission.khumps.dev"
      ]
      secret_name = "knowhere-khumps-dev-tls-acme"
    }
    rule {
      host = "radarr.khumps.dev"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = local.radarr-name
              port {
                number = local.radarr-port
              }
            }
          }
        }
      }
    }
    rule {
      host = "sonarr.khumps.dev"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "sonarr"
              port {
                number = 8989
              }
            }
          }
        }
      }
    }
    rule {
      host = "transmission.khumps.dev"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "transmission"
              port {
                number = 9091
              }
            }
          }
        }
      }
    }
    rule {
      host = "jackett.khumps.dev"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "jackett"
              port {
                number = 9117
              }
            }
          }
        }
      }
    }
    rule {
      host = "plexpy.khumps.dev"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "plexpy"
              port {
                number = 8181
              }
            }
          }
        }
      }
    }
  }
}

# Flaresolverr
resource "kubernetes_deployment" "knowhere_flaresolverr" {
  metadata {
    name = local.flaresolverr-name
    labels = {
      app = local.flaresolverr-name
    }
    namespace = local.knowhere_namespace
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = local.flaresolverr-name
      }
    }
    template {
      metadata {
        labels = {
          app = local.flaresolverr-name
        }
      }
      spec {
        container {
          name  = local.flaresolverr-name
          image = "ghcr.io/flaresolverr/flaresolverr:latest"
          port {
            container_port = local.flaresolverr-port
          }
          env {
            name  = "PUID"
            value = "1000"
          }
          env {
            name  = "GUID"
            value = "113"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "knowhere_flaresolverr" {
  metadata {
    name      = local.flaresolverr-name
    namespace = local.knowhere_namespace
  }
  spec {
    selector = {
      app : local.flaresolverr-name
    }
    port {
      name = "http"
      port = local.flaresolverr-port
    }
  }
}

# Jackett
resource "kubernetes_deployment" "knowhere_jackett" {
  metadata {
    name = local.jackett-name
    labels = {
      app = local.jackett-name
    }
    namespace = local.knowhere_namespace
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app : local.jackett-name
      }
    }
    template {
      metadata {
        labels = {
          app = local.jackett-name
        }
      }
      spec {
        container {
          name  = local.jackett-name
          image = "ghcr.io/linuxserver/jackett:latest"
          port {
            container_port = local.jackett-port
          }
          env {
            name  = "PUID"
            value = "1000"
          }
          env {
            name  = "GUID"
            value = "113"
          }
          volume_mount {
            mount_path = "/config"
            name       = "jackett-config"
          }
        }
        volume {
          name = "jackett-config"
          iscsi {
            iqn           = "iqn.2021-06.freenas.fishnet:jackett"
            target_portal = "192.168.2.5:3260"
            lun           = 3
            fs_type       = "ext4"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "knowhere_jackett" {
  metadata {
    name      = local.jackett-name
    namespace = local.knowhere_namespace
  }
  spec {
    selector = {
      app : local.jackett-name
    }
    port {
      name = "http"
      port = local.jackett-port
    }
  }
}

# Plexpy
resource "kubernetes_deployment" "knowhere_plexpy" {
  metadata {
    name = local.plexpy-name
    labels = {
      app = local.plexpy-name
    }
    namespace = local.knowhere_namespace
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app : local.plexpy-name
      }
    }
    template {
      metadata {
        labels = {
          app = local.plexpy-name
        }
      }
      spec {
        container {
          name  = local.plexpy-name
          image = "ghcr.io/linuxserver/tautulli"
          port {
            container_port = local.plexpy-port
          }
          env {
            name  = "PUID"
            value = "1000"
          }
          env {
            name  = "GUID"
            value = "113"
          }
          volume_mount {
            mount_path = "/config"
            name       = "plexpy-config"
            //			sub_path   = "knowhere/plexpy"
          }
        }
        volume {
          name = "plexpy-config"
          iscsi {
            iqn           = "iqn.2021-06.freenas.fishnet:plexpy"
            target_portal = "192.168.2.5:3260"
            lun           = 2
            fs_type       = "ext4"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "knowhere_plexpy" {
  metadata {
    name      = local.plexpy-name
    namespace = local.knowhere_namespace
  }
  spec {
    selector = {
      app : local.plexpy-name
    }
    port {
      name = "http"
      port = local.plexpy-port
    }
  }
}

# Radarr
resource "kubernetes_deployment" "knowhere_radarr" {
  metadata {
    name = local.radarr-name
    labels = {
      app = local.radarr-name
    }
    namespace = local.knowhere_namespace
  }
  spec {

    replicas = 1
    strategy {
      type = "Recreate"
    }
    selector {
      match_labels = {
        app : local.radarr-name
      }
    }
    template {

      metadata {
        labels = {
          app = local.radarr-name
        }
      }
      spec {
        container {
          name  = local.radarr-name
          image = "ghcr.io/linuxserver/radarr:latest"
          port {
            container_port = local.radarr-port
          }
          env {
            name  = "PUID"
            value = "1000"
          }
          env {
            name  = "GUID"
            value = "113"
          }
          volume_mount {
            mount_path = "/config"
            name       = "radarr-config"
          }
          volume_mount {
            mount_path = "/downloads"
            name       = "plex"
            sub_path   = "OpenFlixr/downloads"
          }
          volume_mount {
            mount_path = "/movies"
            name       = "plex"
            sub_path   = "Movies"
          }
          startup_probe {
            http_get {
              path   = "/"
              port   = "7878"
              scheme = "HTTP"
            }
            initial_delay_seconds = 30
            period_seconds        = 30
            failure_threshold     = 20
          }
          readiness_probe {
            http_get {
              path   = "/"
              port   = "7878"
              scheme = "HTTP"
            }
            initial_delay_seconds = 40
            period_seconds        = 30
            failure_threshold     = 10
          }
          liveness_probe {
            http_get {
              path   = "/"
              port   = "7878"
              scheme = "HTTP"
            }
            initial_delay_seconds = 60
            period_seconds        = 20
          }
        }
        volume {
          name = "radarr-config"
          iscsi {
            iqn           = "iqn.2021-06.freenas.fishnet:radarr"
            target_portal = "192.168.2.5:3260"
            lun           = 1
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
      }
    }
  }
}

resource "kubernetes_service" "knowhere_radarr" {
  metadata {
    name      = local.radarr-name
    namespace = local.knowhere_namespace
  }
  spec {
    selector = {
      app : local.radarr-name
    }
    port {
      name = "http"
      port = local.radarr-port
    }
  }
}

# Sonarr
resource "kubernetes_deployment" "knowhere_sonarr" {
  metadata {
    name = local.sonarr-name
    labels = {
      app = local.sonarr-name
    }
    namespace = local.knowhere_namespace
  }
  spec {
    replicas = 1
    strategy {
      type = "Recreate"
    }
    selector {
      match_labels = {
        app : local.sonarr-name
      }
    }
    template {
      metadata {
        labels = {
          app = local.sonarr-name
        }
      }
      spec {
        container {
          name  = local.sonarr-name
          image = "ghcr.io/linuxserver/sonarr:latest"
          port {
            container_port = local.sonarr-port
          }
          env {
            name  = "PUID"
            value = "1000"
          }
          env {
            name  = "GUID"
            value = "113"
          }
          volume_mount {
            mount_path = "/config"
            name       = "sonarr-config"
          }
          volume_mount {
            mount_path = "/tv"
            name       = "plex"
            sub_path   = "TV"
          }
          volume_mount {
            mount_path = "/anime"
            sub_path   = "Anime(Waifu Porn)"
            name       = "plex"
          }
          volume_mount {
            mount_path = "/downloads"
            name       = "plex"
            sub_path   = "OpenFlixr/downloads"
          }
          liveness_probe {
            http_get {
              path   = "/"
              port   = "8989"
              scheme = "HTTP"
            }
            initial_delay_seconds = 60
            period_seconds        = 20
          }
        }
        volume {
          name = "sonarr-config"
          iscsi {
            iqn           = "iqn.2021-06.freenas.fishnet:sonarr"
            target_portal = "192.168.2.5:3260"
            lun           = 0
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
      }
    }
  }
}

resource "kubernetes_service" "knowhere_sonarr" {
  metadata {
    name      = local.sonarr-name
    namespace = local.knowhere_namespace
  }
  spec {
    selector = {
      app : local.sonarr-name
    }
    port {
      name = "http"
      port = local.sonarr-port
    }
  }
}

# Transmission
resource "kubernetes_deployment" "knowhere_transmission" {
  metadata {
    name = local.transmission-name
    labels = {
      app = local.transmission-name
    }
    namespace = local.knowhere_namespace
  }
  spec {

    replicas = 1
    strategy {
      type = "Recreate"
    }
    selector {
      match_labels = {
        app : local.transmission-name
      }
    }
    template {
      metadata {
        labels = {
          app = local.transmission-name
        }
      }
      spec {
        container {
          name  = local.transmission-name
          image = "ghcr.io/linuxserver/transmission:3.00-r8-ls151"
          port {
            container_port = local.transmission-port
          }
          port {
            container_port = 51413
          }
          env {
            name  = "PUID"
            value = "1000"
          }
          env {
            name  = "GUID"
            value = "113"
          }
          env {
            name  = "TZ"
            value = "America/New_York"
          }
          env {
            name  = "TRANSMISSION_WEB_HOME"
            value = "/combustion-release/"
          }
          volume_mount {
            mount_path = "/config"
            name       = "transmission-config"
          }
          volume_mount {
            mount_path = "/downloads"
            name       = "plex"
            sub_path   = "OpenFlixr/downloads"
          }
        }
        container {
          name = "pia"
          security_context {
            privileged = true
            capabilities {
              add = [
              "NET_ADMIN"]
            }
          }
          image = "thrnz/docker-wireguard-pia"
          env {
            name  = "LOC"
            value = "bahamas"
          }
          env {
            name = "USER"
            value_from {
              secret_key_ref {
                name = "pia-credentials"
                key  = "username"
              }
            }
          }
          env {
            name = "PASS"
            value_from {
              secret_key_ref {
                name = "pia-credentials"
                key  = "password"
              }
            }
          }
          env {
            name  = "LOCAL_NETWORK"
            value = "192.168.2.0/24 10.1.0.0/16"
          }
          env {
            name  = "FIREWALL"
            value = "1"
          }
          env {
            name  = "PORT_FORWARDING"
            value = "1"
          }
          env {
            name  = "PORT_PERSIST"
            value = "1"
          }
        }
        volume {
          name = "transmission-config"
          iscsi {
            iqn           = "iqn.2021-06.freenas.fishnet:transmission"
            target_portal = "192.168.2.5:3260"
            lun           = 4
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
      }
    }
  }
}

resource "kubernetes_service" "knowhere_transmission" {
  metadata {
    name      = local.transmission-name
    namespace = local.knowhere_namespace
  }
  spec {
    selector = {
      app : local.transmission-name
    }
    port {
      name = "http"
      port = local.transmission-port
    }
    port {
      protocol = "TCP"
      name     = "tcp"
      port     = 51413
    }
    port {
      protocol = "UDP"
      name     = "udp"
      port     = 51413
    }
  }
}
