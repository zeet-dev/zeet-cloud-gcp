locals {
  cluster_name_short = "${substr(var.cluster_name, 0, 8)}-${substr(var.cluster_id, 0, 4)}"
}

module "workload-identity-cert-manager" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version = "~> 25.0.0"

  gcp_sa_name = "${local.cluster_name_short}-cert-manager"
  name        = "cert-manager"
  namespace   = var.cert_manager_namespace
  project_id  = var.project_id
  roles       = ["roles/dns.admin"]

  use_existing_k8s_sa = true
  annotate_k8s_sa     = false
}

module "workload-identity-external-dns" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version = "~> 25.0.0"

  gcp_sa_name = "${local.cluster_name_short}-external-dns"
  name        = "external-dns"
  namespace   = var.external_dns_namespace
  project_id  = var.project_id
  roles       = ["roles/dns.admin"]

  use_existing_k8s_sa = true
  annotate_k8s_sa     = false
}
