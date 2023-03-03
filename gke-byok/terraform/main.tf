terraform {
  required_version = "~> 1.1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.55.0"
    }

    google-beta = {
      source  = "hashicorp/google"
      version = "~> 4.55.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

module "enables-google-apis" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 14.1.0"

  project_id = var.project_id

  activate_apis = [
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "containerregistry.googleapis.com",
    "container.googleapis.com",
    "storage-component.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "dns.googleapis.com",
    "tpu.googleapis.com",
  ]

  activate_api_identities = [
    {
      api   = "tpu.googleapis.com"
      roles = ["roles/viewer", "roles/storage.admin"]
    }
  ]

  disable_dependent_services  = false
  disable_services_on_destroy = false
}


data "google_container_cluster" "gke" {
  name     = var.cluster_name
  location = var.cluster_location
}

module "gke_auth" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  version = "~> 25.0.0"

  project_id   = var.project_id
  cluster_name = data.google_container_cluster.gke.name
  location     = data.google_container_cluster.gke.location
}

resource "local_file" "kubeconfig" {
  content  = module.gke_auth.kubeconfig_raw
  filename = "kubeconfig_${var.cluster_name}"
}

# google_client_config and kubernetes provider must be explicitly specified like the following.
data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.gke.master_auth.0.cluster_ca_certificate)
}
