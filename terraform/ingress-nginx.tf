locals {
  ingress_class_name = "ingress-nginx"
}

resource "helm_release" "ingress-nginx" {
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  name             = "ingress-nginx"
  create_namespace = true
  set {
    name  = "controller.service.loadBalancerIP"
    value = "192.168.60.250"
  }
  set {
    name  = "controller.ingressClassResource.name"
    value = local.ingress_class_name
  }
  set {
    name  = "controller.service.externalTrafficPolicy"
    value = "Local"
  }
  set {
    name  = "tcp.8080"
    value = "unifi/unifi:8080"
  }
  set {
    name  = "tcp.32400"
    value = "plex/plex:32400"
  }
  set {
    name  = "udp.10001"
    value = "unifi/unifi:10001"
  }
}
