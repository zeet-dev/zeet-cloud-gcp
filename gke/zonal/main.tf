terraform {
  # required_version = "~> 1.1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.15.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.15.0"
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
  version = "11.3.0"

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

module "gke_auth" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  version = "~> 19.0"

  project_id   = var.project_id
  cluster_name = module.gke.name
  location     = module.gke.location

  depends_on = [module.gke]
}

resource "local_file" "kubeconfig" {
  content  = module.gke_auth.kubeconfig_raw
  filename = "kubeconfig_${var.cluster_name}"
}

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 4.1.0"

  project_id   = var.project_id
  network_name = "zeet-${var.cluster_name}"

  subnets = [
    {
      subnet_name   = "zeet-${var.cluster_name}-subnet-01"
      subnet_ip     = "10.0.0.0/19"
      subnet_region = var.region
      subnet_private_access = true
    }
  ]

  secondary_ranges = {
    "zeet-${var.cluster_name}-subnet-01" = [
      {
        range_name    = "zeet-${var.cluster_name}-subnet-01-pods"
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = "zeet-${var.cluster_name}-subnet-01-services"
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
}

# google_client_config and kubernetes provider must be explicitly specified like the following.
data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

locals {
  # TODO: move to a shared location
  available_gpu_in_zones = {
    "asia-east1-a":              ["t4", "p100", "k80"],
		"asia-east1-b":              ["k80"],
		"asia-east1-c":              ["t4", "v100", "p100"],
		"asia-east2-a":              ["t4"],
		"asia-east2-b":              [],
		"asia-east2-c":              ["t4"],
		"asia-northeast1-a":         ["a100", "t4"],
		"asia-northeast1-b":         [],
		"asia-northeast1-c":         ["a100", "t4"],
		"asia-northeast2-a":         [],
		"asia-northeast2-b":         [],
		"asia-northeast2-c":         [],
		"asia-northeast3-a":         ["a100"],
		"asia-northeast3-b":         ["a100", "t4"],
		"asia-northeast3-c":         ["t4"],
		"asia-south1-a":             ["t4"],
		"asia-south1-b":             ["t4"],
		"asia-south1-c":             [],
		"asia-southeast1-a":         ["t4"],
		"asia-southeast1-b":         ["a100", "l4", "t4", "p4"],
		"asia-southeast1-c":         ["a100", "t4", "p4"],
		"asia-southeast2-a":         ["t4"],
		"asia-southeast2-b":         ["t4"],
		"asia-southeast2-c":         [],
		"australia-southeast1-a":    ["t4", "p4"],
		"australia-southeast1-b":    ["p4"],
		"australia-southeast1-c":    ["t4", "p100"],
		"europe-central2-a":         [],
		"europe-central2-b":         ["t4"],
		"europe-central2-c":         ["t4"],
		"europe-north1-a":           [],
		"europe-north1-b":           [],
		"europe-north1-c":           [],
		"europe-southwest1-a":       [],
		"europe-southwest1-b":       [],
		"europe-southwest1-c":       [],
		"europe-west1-b":            ["p100", "k80", "t4"],
		"europe-west1-c":            ["t4"],
		"europe-west1-d":            ["p100", "k80", "t4"],
		"europe-west12-a":           [],
		"europe-west12-b":           [],
		"europe-west12-c":           [],
		"europe-west2-a":            ["t4"],
		"europe-west2-b":            ["t4"],
		"europe-west2-c":            [],
		"europe-west3-a":            [],
		"europe-west3-b":            ["t4"],
		"europe-west3-c":            [],
		"europe-west4-a":            ["a100", "l4", "t4", "v100", "p100"],
		"europe-west4-b":            ["a100", "l4", "t4", "p4", "v100"],
		"europe-west4-c":            ["l4", "t4", "p4", "v100"],
		"europe-west6-a":            [],
		"europe-west6-b":            [],
		"europe-west6-c":            [],
		"europe-west8-a":            [],
		"europe-west8-b":            [],
		"europe-west8-c":            [],
		"europe-west9-a":            [],
		"europe-west9-b":            [],
		"europe-west9-c":            [],
		"me-central1-a":             [],
		"me-central1-b":             [],
		"me-central1-c":             [],
		"me-west1-a":                [],
		"me-west1-b":                ["t4"],
		"me-west1-c":                ["t4"],
		"northamerica-northeast1-a": ["p4"],
		"northamerica-northeast1-b": ["p4"],
		"northamerica-northeast1-c": ["t4", "p4"],
		"southamerica-east1-a":      [],
		"southamerica-east1-b":      ["t4"],
		"southamerica-east1-c":      ["t4"],
		"us-central1-a":             ["a100", "l4", "t4", "p4", "v100", "k80"],
		"us-central1-b":             ["a100", "l4", "t4", "v100"],
		"us-central1-c":             ["a100", "t4", "p4", "v100", "p100", "k80"],
		"us-central1-f":             ["a100", "t4", "v100", "p100"],
		"us-east1-b":                ["a100", "l4", "p100"],
		"us-east1-c":                ["t4", "v100", "p100", "k80"],
		"us-east1-d":                ["l4", "t4", "k80"],
		"us-east4-a":                ["l4", "t4", "p4"],
		"us-east4-b":                ["t4", "p4"],
		"us-east4-c":                ["a100", "t4", "p4"],
		"us-east5-a":                [],
		"us-east5-b":                [],
		"us-east5-c":                [],
		"us-south1-a":               [],
		"us-south1-b":               [],
		"us-south1-c":               [],
		"us-west1-a":                ["l4", "t4", "v100", "p100"],
		"us-west1-b":                ["a100", "l4", "t4", "v100", "p100", "k80"],
		"us-west1-c":                [],
		"us-west2-a":                [],
		"us-west2-b":                ["p4", "t4"],
		"us-west2-c":                ["p4", "t4"],
		"us-west3-a":                [],
		"us-west3-b":                [],
		"us-west3-c":                [],
		"us-west4-a":                ["t4"],
		"us-west4-b":                ["a100", "t4"],
		"us-west4-c":                [],
  }

  reserved_gpu_types = ["a100", "l4"]
  accelerator_types = {
    "t4": "nvidia-tesla-t4",
    "v100": "nvidia-tesla-v100",
    "p100": "nvidia-tesla-p100",
    "p4": "nvidia-tesla-p4",
    "k80": "nvidia-tesla-k80",
    "a100": "nvidia-tesla-a100",
    "l4": "nvidia-l4",
  }

  generic_gpu_instance_sizes = [
    "n1-standard-1",
    "n1-standard-2",
    "n1-standard-4",
    "n1-standard-8",
    "n1-highmem-2",
    "n1-highmem-4",
    "n1-highmem-8",
  ]

  reserved_sizes = {
    "a100" = var.enable_a100 ? [
      "a2-highgpu-1g",
      "a2-highgpu-2g",
      "a2-highgpu-4g",
    ] : [],
    "l4" = var.enable_l4 ? [
      "g2-standard-4",
      "g2-standard-8",
      "g2-standard-12",
    ] : [],
  }

  gpu_instances = {for gpu in local.available_gpu_in_zones[var.zone] : "${gpu}" => 
    can(local.reserved_sizes[gpu]) ? local.reserved_sizes[gpu] : local.generic_gpu_instance_sizes
  }
}

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/beta-public-cluster"
  version = "~> 19.0.0"

  project_id        = var.project_id
  name              = "zeet-${var.cluster_name}"
  release_channel   = "STABLE"
  region            = var.region
  regional          = false
  zones             = [var.zone]
  network           = module.vpc.network_name
  subnetwork        = module.vpc.subnets_names[0]
  ip_range_pods     = "zeet-${var.cluster_name}-subnet-01-pods"
  ip_range_services = "zeet-${var.cluster_name}-subnet-01-services"

  horizontal_pod_autoscaling = true
  gce_pd_csi_driver          = true
  enable_tpu                 = var.enable_tpu

  http_load_balancing = false
  network_policy      = false
  istio               = false
  cloudrun            = false
  dns_cache           = false

  remove_default_node_pool = true

  cluster_autoscaling = {
    enabled             = true
    autoscaling_profile = "OPTIMIZE_UTILIZATION"
    max_cpu_cores       = 250
    min_cpu_cores       = 2
    max_memory_gb       = 1000
    min_memory_gb       = 4
    gpu_resources       = []
  }

  node_pools = concat([
    {
      name                      = "e2-standard-2-system"
      machine_type              = "e2-standard-2"
      node_locations            = var.zone
      min_count                 = 1
      max_count                 = 10
      local_ssd_count           = 0
      local_ssd_ephemeral_count = 0
      disk_size_gb              = 100
      disk_type                 = "pd-standard"
      image_type                = "COS_CONTAINERD"
      auto_repair               = true
      auto_upgrade              = true
      preemptible               = false
      initial_node_count        = 1
    },
    {
      name                      = "e2-standard-2-guara-preemp"
      machine_type              = "e2-standard-2"
      node_locations            = var.zone
      min_count                 = 0
      max_count                 = 10
      local_ssd_count           = 0
      local_ssd_ephemeral_count = 0
      disk_size_gb              = 100
      disk_type                 = "pd-standard"
      image_type                = "COS_CONTAINERD"
      auto_repair               = true
      auto_upgrade              = true
      preemptible               = true
      initial_node_count        = 0
    },
    {
      name                      = "e2-standard-2-dedicated"
      machine_type              = "e2-standard-2"
      node_locations            = var.zone
      min_count                 = 0
      max_count                 = 10
      local_ssd_count           = 0
      local_ssd_ephemeral_count = 0
      disk_size_gb              = 100
      disk_type                 = "pd-standard"
      image_type                = "COS_CONTAINERD"
      auto_repair               = true
      auto_upgrade              = true
      preemptible               = false
      initial_node_count        = 0
    }
    ], flatten([for gpu, sizes in local.gpu_instances : 
      [for size in sizes: {
      name                      = "${size}-nvidia-${gpu}"
      machine_type              = size
      node_locations            = var.zone
      min_count                 = 0
      max_count                 = 20
      local_ssd_count           = 0
      local_ssd_ephemeral_count = 0
      accelerator_count         = 1
      # accelerator_type is actually need for a100 & l4 as well
      # https://cloud.google.com/kubernetes-engine/docs/how-to/gpus
      accelerator_type          = local.accelerator_types[gpu]
      disk_size_gb              = 200
      disk_type                 = "pd-standard"
      image_type                = "COS_CONTAINERD"
      auto_repair               = true
      auto_upgrade              = true
      preemptible               = false
      initial_node_count        = 0
    }]]),

  )

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }



  node_pools_labels = merge({
    all = {
      ZeetClusterId = var.cluster_id
      ZeetUserId    = var.user_id
    }

    e2-standard-2-system = {
      "zeet.co/dedicated" = "system"
    }

    e2-standard-2-guara-preemp = {
      "zeet.co/dedicated" = "guaranteed"
    }

    e2-standard-2-dedicated = {
      "zeet.co/dedicated" = "dedicated"
    }

    }, flatten([
    for gpu, sizes in local.gpu_instances:
      {for size in sizes : "${size}-nvidia-${gpu}" => {
      "zeet.co/dedicated"                = "dedicated"
      "cloud.google.com/gke-accelerator" = local.accelerator_types[gpu]
    }}])...
  )


  node_pools_metadata = {
    all = {
      ZeetClusterId = var.cluster_id
      ZeetUserId    = var.user_id
    }
  }

  node_pools_taints = {
    all = []

    e2-standard-2-guara-preemp = [
      {
        key    = "zeet.co/dedicated"
        value  = "guaranteed"
        effect = "NO_SCHEDULE"
      },
    ]

    e2-standard-2-dedicated = [
      {
        key    = "zeet.co/dedicated"
        value  = "dedicated"
        effect = "NO_SCHEDULE"
      },
    ]
  }

  node_pools_tags = {
    all = []
  }

  depends_on = [module.enables-google-apis]
}
