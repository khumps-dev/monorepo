locals {
  storage_class_name = "nfs-freenas"
}
resource "helm_release" "nfs-provisioner" {
  repository = "https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner"
  chart      = "nfs-subdir-external-provisioner"
  name       = "nfs-provisioner"
  set {
    name  = "nfs.server"
    value = "192.168.2.5"
  }
  set {
    name  = "nfs.path"
    value = "/mnt/Main/singularity"
  }

  set {
    name  = "storageClass.name"
    value = "nfs-freenas"
  }
  set {
    name  = "storageClass.archiveOnDelete"
    value = "true"
  }
}
