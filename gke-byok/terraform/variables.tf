// GCP Provider
variable "project_id" {
  type        = string
  description = "The GCP project ID"
}

variable "region" {
  type        = string
  description = "The GCP region"
}

// ZEET
variable "user_id" {
  type = string
}

variable "cluster_id" {
  type = string
}

// GKE Cluster
variable "cluster_name" {
  type = string
}

variable "cluster_location" {
  type = string
}

variable "cluster_domain" {
  type = string
}


variable "cert_manager_namespace" {
  type = string
  default = "cert-manager"
}

variable "external_dns_namespace" {
  type = string
  default = "external-dns"
}
