variable "hcloud_token" {}
variable "hetzner_location" {}
variable "hcloud_csi_token" {}

variable "server_upload_dir" {}

variable "admin_ssh_keys" {}

variable "master_image" { default = "ubuntu-20.04" }
variable "master_type" { default = "cx21" }
variable "node_count" {}
variable "node_image" { default = "ubuntu-20.04" }
variable "node_type" {}

variable "docker_version" {}
variable "kubernetes_version" {}
variable "feature_gates" {
  description = "Add Feature Gates e.g. 'DynamicKubeletConfig=true'"
  default     = ""
}
variable "hcloud_csi_version" { default = "1.4.0" }

variable "pod_network_cidr" { default = "10.244.0.0/16" }

variable "metrics_server_version" { default = "0.3.7" }

variable "install_packages" { description = "Additional deb packages to install during instance bootstrap." }

variable "cluster_name" {
  type        = string
  description = "Cluster name. Used as a suffix for SSH keys, node names and volumes."
}

variable "existing_ssh_keys" {
  type        = list(string)
  description = "Use following keys (by name) from HCloud project. Keys must already exist in the project."
}
