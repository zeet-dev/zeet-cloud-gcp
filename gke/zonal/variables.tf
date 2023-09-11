variable "project_id" {
  type        = string
  description = "The GCP project ID"
}

variable "region" {
  type        = string
  description = "The GCP region"
}

variable "zone" {
  type = string
}

variable "cluster_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "cluster_domain" {
  type = string
}

variable "user_id" {
  type = string
}

variable "enable_tpu" {
  type = bool
}

# the following two variables determins whether to turn on gpu support if the zone has them
variable "enable_a100" {
  type    = bool
  default = false
}

variable "enable_l4" {
  type    = bool
  default = false
}
