resource "helm_release" "rabbitmq-cluster-operator" {
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "rabbitmq-cluster-operator"
  name             = "rabbitmq-cluster-operator"
  namespace        = "rabbitmq"
  create_namespace = true
}
