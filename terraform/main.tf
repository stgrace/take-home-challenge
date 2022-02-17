resource "google_compute_subnetwork" "nodes" {
  name          = "nodes-subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  region        = "europe-west1"
  project       = "devoteam-341616"
  network       = google_compute_network.vpc_devoteam.id
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.1.0.0/16"
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.0.0/16"
  }
}

resource "google_compute_network" "vpc_devoteam" {
  project                 = "devoteam-341616"
  name                    = "vpc-devoteam"
  auto_create_subnetworks = true
  mtu                     = 1460
}

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google"
  project_id                 = "devoteam-341616"
  name                       = "devoteam-cluster-1"
  region                     = "europe-west1"
  zones                      = ["europe-west1-d", "europe-west1-b", "europe-west1-c"]
  network                    = google_compute_network.vpc_devoteam.name
  subnetwork                 = google_compute_subnetwork.nodes.name
  ip_range_pods              = "pods"
  ip_range_services          = "services"
  http_load_balancing        = false
  horizontal_pod_autoscaling = true
  network_policy             = false

  node_pools = [
    {
      name                      = "devoteam-pool"
      machine_type              = "e2-medium"
      node_locations            = "europe-west1-d"
      min_count                 = 1
      max_count                 = 4
      local_ssd_count           = 0
      disk_size_gb              = 100
      disk_type                 = "pd-standard"
      image_type                = "COS_CONTAINERD"
      auto_repair               = true
      auto_upgrade              = true
      service_account           = "devoteam-sa@devoteam-341616.iam.gserviceaccount.com"
      preemptible               = false
      initial_node_count        = 4
    },
  ]

  node_pools_oauth_scopes = {
    all = []

    devoteam-pool = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}