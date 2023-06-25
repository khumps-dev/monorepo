resource "helm_release" "grafana-oncall-dev" {
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "oncall"
  name             = "oncall-dev"
  namespace        = "grafana-oncall"
  create_namespace = true
  timeout          = "600"
  set {
    name  = "base_url"
    value = "oncall-dev.khumps.dev"
  }

  set {
    name  = "grafana.\"grafana.ini\".server.domain"
    value = "oncall-dev.khumps.dev"
  }

  #   set {
  #     name  = "oncall.slack.enabled"
  #     value = "false"
  #   }

  #   set {
  #     name  = "oncall.slack.clientId"
  #     value = "false"
  #   }

  #   set {
  #     name  = "oncall.slack.clientSecret"
  #     value = "false"
  #   }

  #   set {
  #     name  = "oncall.slack.signingSecret"
  #     value = "false"
  #   }

  # We already have our own nginx ingress installed (which isn't getting used since this is internal)
  set {
    name  = "ingress-nginx.enabled"
    value = "false"
  }

  # We already have our own cert-manager installed
  set {
    name  = "cert-manager.enabled"
    value = "false"
  }

  # We will run the ingress through cloudflare-tunnel
  set {
    name  = "ingress.enabled"
    value = "false"
  }

  # We run our grafana through the kube-prometheus stack
  set {
    name  = "grafana.enabled"
    value = "false"
  }

  set {
    name  = "externalGrafana.url"
    value = "http://grafana.monitoring:3000"
  }

}
