resource "helm_release" "cert-manager" {
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }
  set {
    name  = "ingressShim.defaultIssuerName"
    value = "letsencrypt-prod"
  }
  set {
    name  = "ingressShim.defaultIssuerKind"
    value = "ClusterIssuer"
  }
  set {
    name  = "ingressShim.defaultIssuerGroup"
    value = "cert-manager.io"
  }
}

resource "kubernetes_manifest" "letsencrypt-prod" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = "kmanh999@gmail.com"
        privateKeySecretRef = {
          name = "letsencrypt-production-issuer-account-key"
        }
        solvers = [
          {
            dns01 = {
              cloudflare = {
                email = "kmanh999@gmail.com"
                apiTokenSecretRef = {
                  name = "cloudflare-api-key-secret"
                  key  = "api-key"
                }
              }
            }
          },
        ]
      }
    }
  }
}
