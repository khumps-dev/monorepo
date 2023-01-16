resource "kubernetes_config_map" "nginx-ingress-tcp" {
  metadata {
    name      = "nginx-ingress-tcp-microk8s-conf"
    namespace = "ingress"
  }
  data = {
    8080 : "unifi/unifi:8080"
    32400 : "plex/plex:32400"
  }
}

resource "kubernetes_config_map" "nginx-ingress-udp" {
  metadata {
    name      = "nginx-ingress-udp-microk8s-conf"
    namespace = "ingress"
  }
  data = {
    10001 : "unifi/unifi:10001"
  }
}
