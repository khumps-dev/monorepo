resource "kubernetes_manifest" "pool_192-168-60-0" {
  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "IPAddressPool"
    metadata = {
      name      = "192-168-60-0-pool"
      namespace = "metallb-system"
    }
    spec = {
      addresses = [
        "192.168.60.250-192.168.60.254"
      ]
      autoAssign = true
    }
  }
}

resource "kubernetes_manifest" "advertisement_192-168-60-0" {
  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "L2Advertisement"
    metadata = {
      name      = "192-168-60-0-advertisement"
      namespace = "metallb-system"
    }
    spec = {
      ipAddressPools = [
        kubernetes_manifest.pool_192-168-60-0.manifest.metadata.name
      ]
    }
  }
}



resource "kubernetes_service" "prod-vlan_metallb-ingress-tcp" {
  metadata {
    name      = "ingress-tcp-prod-vlan"
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
    load_balancer_ip        = "192.168.60.254"
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

resource "kubernetes_service" "prod-vlan_metallb-ingress-udp" {
  metadata {
    name      = "ingress-udp-prod-vlan"
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
    load_balancer_ip        = "192.168.60.254"
    external_traffic_policy = "Local"
    port {
      name        = "unifi-discovery"
      port        = 10001
      target_port = 10001
      protocol    = "UDP"
    }
  }
}
