variable "workers" {
  type        = map(string)
  description = "A map of worker_name=>worker_public_ip"
}

variable "nr_hugepages" {
  type        = number
  description = "Number of 2MB hugepages to allocate on the worker node"
  default     = 1024
}

variable "docker_insecure_registry" {
  type        = string
  description = "Set trusted docker registry on worker nodes (handy for private registry)"
  default     = ""
}

variable "docker_registry_mirror" {
  type        = string
  description = "Use registry mirror (pull-through cache) to avoid failures when upstream (docekrhub, quay.io) for images fails or to avoid pull limits"
  default     = ""
}

variable "k8s_master_ip" {}

variable "kernel_version" {
  description = "Which kernel version to install. Must be a version available in used ubuntu version. A linux-modules-extra must exist for that version."
}

