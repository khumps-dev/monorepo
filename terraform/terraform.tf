
terraform {
  backend "kubernetes" {
    secret_suffix    = "tfstate"
    load_config_file = true
    config_path      = "~/.kube/config"
  }
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.11.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

provider "cloudflare" {
  # api_token = SET BY CLOUDFLARE_API_TOKEN ENV VAR
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "singularity"
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "singularity"
  }
}

provider "kubectl" {
  config_path    = "~/.kube/config"
  config_context = "singularity"
}
