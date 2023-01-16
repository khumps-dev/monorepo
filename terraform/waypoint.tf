resource "helm_release" "waypoint" {
  name             = "waypoint"
  namespace        = "waypoint"
  chart            = "waypoint"
  repository       = "https://helm.releases.hashicorp.com"
  create_namespace = true

  set {
    name  = "server.storage.storageClass"
    value = "nfs-freenas"
  }

  set {
    name  = "runner.storage.storageClass"
    value = "nfs-freenas"
  }

  set {
    name  = "ui.service.type"
    value = "ClusterIP"
  }

  set {
    name = "ui.ingress.enabled"
    # type = "string"
    value = "true"
  }

  set {
    name  = "ui.ingress.hosts[0].host"
    value = "waypoint.infra.khumps.dev"
  }

  # set {
  #     name = "ui.ingress.hosts[0].paths"
  #     value = "{/waypoint(/|$)(.*)}"
  # }

  set {
    name  = "ui.ingress.annotations.kubernetes\\.io/tls-acme"
    type  = "string"
    value = "true"
  }

  # set {
  #     name = "ui.ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/auth-type"
  #     value = "basic"
  # }

  # set {
  #     name = "ui.ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/auth-secret"
  #     value = "default/basic-auth"
  # }

  # set {
  #     name = "ui.ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/auth-realm"
  #     value = "khumps.dev - Waypoint"
  # }

  # set {
  #     name = "ui.ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/rewrite-target"
  #     value = "/$2"
  # }

  set {
    name  = "ui.ingress.tls[0].hosts[0]"
    value = "waypoint.infra.khumps.dev"
  }

  set {
    name  = "ui.ingress.tls[0].secretName"
    value = "waypoint-infra-khumps-dev-tls-acme"
  }
}
