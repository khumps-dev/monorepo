resource "kubernetes_service" "metallb-ingress-tcp" {
  metadata {
    name      = "ingress-tcp"
    namespace = "ingress"
    annotations = {
      "metallb.universe.tf/allow-shared-ip" = "true"
    }
  }
  spec {
    selector = {
      name : "nginx-ingress-microk8s"
    }
    type                    = "LoadBalancer"
    load_balancer_ip        = "192.168.2.254"
    external_traffic_policy = "Local"
    port {
      name        = "http"
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
    port {
      name        = "https"
      port        = 443
      target_port = 443
      protocol    = "TCP"
    }
    port {
      name        = "plex"
      port        = 32400
      target_port = 32400
      protocol    = "TCP"
    }
    port {
      name        = "unifi"
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_service" "metallb-ingress-udp" {
  metadata {
    name      = "ingress-udp"
    namespace = "ingress"
    annotations = {
      "metallb.universe.tf/allow-shared-ip" = "true"
    }
  }
  spec {
    selector = {
      name : "nginx-ingress-microk8s"
    }
    type                    = "LoadBalancer"
    load_balancer_ip        = "192.168.2.254"
    external_traffic_policy = "Local"
    port {
      name        = "unifi-discovery"
      port        = 10001
      target_port = 10001
      protocol    = "UDP"
    }
  }
}
