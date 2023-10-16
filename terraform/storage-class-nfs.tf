locals {
  storage_class_name          = "nfs-freenas"
  nfs_host                    = "192.168.60.5"
  iscsi_target                = "192.168.60.5:3260"
  longhorn_storage_class_name = "longhorn"
}
resource "helm_release" "nfs-provisioner" {
  repository = "https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner"
  chart      = "nfs-subdir-external-provisioner"
  name       = "nfs-provisioner"
  set {
    name  = "nfs.server"
    value = local.nfs_host
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
