variable "aws_region" {
  type        = string
  description = "AWS region in which to create the cluster."
  default     = "eu-central-1"
}

variable "availability_zone" {
  type        = string
  description = "AWS availability zone where EBS data volumes will be created."
  default     = "eu-central-1a"
}

variable "num_workers" {
  type        = number
  description = "Number of worker nodes in k8s cluster"
  default     = 2
}

// default = {
//     "key1" : { "key_file" = "~/.ssh/id_rsa.pub" },
//     "key2" : { "key_data" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMQCA+Slye+ZcgLRxdIyQCpEcG/XKKwyxpRWuCSpS098 email@example.com" },
// }
variable "ssh_public_keys" {
  type        = map(map(string))
  description = "Map of maps of public ssh keys. See variables.tf for full example. Default is ~/.ssh/id_rsa.pub. Due to AWS limitations you **have** to have one key named 'key1' which is a RSA key."
  default = {
    "key1" = { "key_file" = "~/.ssh/id_rsa.pub" },
  }
}

variable "cluster_name" {
  type        = string
  description = "Name of the cluster. Used as a part of AWS names and tags of various cluster components."
  default     = "mayastor-tf-playground"
}

variable "tags" {
  type        = map(string)
  description = "A set of tags to assign to the created AWS resources. These tags will be assigned in addition to the default tags. The default tags include \"terraform-kubeadm:cluster\" which is assigned to all resources and whose value is the cluster name, and \"terraform-kubeadm:node\" which is assigned to the EC2 instances and whose value is the name of the Kubernetes node that this EC2 corresponds to."
  default     = {}
}

variable "flannel_version" {
  type        = string
  description = "Version of flannel CNI to deploy to the cluster."
  default     = "0.13.0"
}

variable "docker_version" {
  type        = string
  description = "Docker version to install."
  default     = "20.0.5"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version to install."
  default     = "1.20.4"
}

variable "deploy_mayastor" {
  type        = bool
  description = "Deploy mayastor itself. Set to false to skip."
  default     = true
}

variable "ebs_volume_size" {
  type        = number
  description = "Additional EBS volume size to attach to EC2 instance on workers in gigabytes."
  default     = 5
}

variable "mayastor_use_develop_images" {
  type        = bool
  description = "Use 'develop' tag for mayastor images instead of 'latest'"
  default     = false
}

variable "install_packages" {
  type        = list(string)
  description = "Additional deb packages to install during instance bootstrap."
  default = [
    "fio",
    "iotop",
    "nvme-cli",
    "strace",
    "sysstat",
    "tcpdump",
  ]
}

# Note: cannot use null as a default as validation doesn't like it
variable "mayastor_replicas" {
  type        = number
  default     = -1
  description = "How many replicas should mayastor default storageclass use? Leave default to use mayastor_replicas == number of cluster nodes. For mayastor_replicas > number of cluster nodes mayastor **will not start**."
  validation {
    condition     = var.mayastor_replicas == -1 || var.mayastor_replicas >= 1
    error_message = "The mayastor_replicas must be greater or equal to 1."
  }
}

variable "aws_instance_root_size_gb" {
  type        = number
  default     = 8
  description = "Root block device size for AWS instances in GiB. Clean install (currently) uses a little over 4. Not recommended to use less than default."
}

# TODO: avoid repeating instances here and in modules/k8s/variables.tf
variable "aws_instance_type_worker" {
  type        = string
  description = "EC2 instance type to use for kubernetes nodes. Not all types are supported. See modules/k8s/variables.tf - variable aws_worker_instances on how to add support for more."
  default     = "t3.xlarge"
  validation {
    condition     = contains(["t3.xlarge", "i3.xlarge"], var.aws_instance_type_worker)
    error_message = "Unsupported instance type. To add support check aws_worker_instances variable in modules/k8s/variables.tf."
  }
}

variable "docker_insecure_registry" {
  type        = string
  description = "Set trusted docker registry on worker nodes (handy for private registry)"
  default     = ""
}

variable "kernel_version" {
  description = "Which kernel version to install. Must be a version available in used ubuntu version. A linux-modules-extra must exist for that version."
  default     = "5.8.0-44-generic"
}
