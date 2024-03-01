locals {
  domain = var.cluster_domain
}

module "dns" {
  source      = "terraform-google-modules/cloud-dns/google"
  version     = "3.0.0"
  project_id  = var.project_id
  type        = "public"
  name        = "zeet-${var.cluster_name}"
  description = "Managed by Zeet"
  domain      = "${local.domain}."
}
