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
