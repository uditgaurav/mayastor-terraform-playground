module "k8s" {
  source = "./modules/k8s"

  admin_ssh_keys     = var.admin_ssh_keys
  cluster_name       = var.cluster_name
  docker_version     = var.docker_version
  existing_ssh_keys  = var.existing_ssh_keys
  hcloud_csi_token   = var.hcloud_csi_token
  hcloud_token       = var.hcloud_token
  hetzner_location   = var.hetzner_location
  kubernetes_version = var.kubernetes_version
  node_count         = var.node_count
  node_type          = var.node_type
  server_upload_dir  = var.server_upload_dir

  install_packages = var.install_packages
}

module "mayastor-dependencies" {
  source = "./modules/mayastor-dependencies"

  docker_insecure_registry = var.docker_insecure_registry
  k8s_master_ip            = module.k8s.master_ip
  kernel_version           = var.kernel_version
  nr_hugepages             = var.nr_hugepages

  workers = {
    for worker in slice(module.k8s.cluster_nodes, 1, length(module.k8s.cluster_nodes)) :
    worker.name => worker.public_ip
  }
  depends_on = [module.k8s]
}

module "mayastor" {
  source = "./modules/mayastor"

  count                       = var.deploy_mayastor ? 1 : 0
  depends_on                  = [module.mayastor-dependencies]
  k8s_master_ip               = module.k8s.master_ip
  mayastor_disk               = "/dev/sdb"
  mayastor_replicas           = var.mayastor_replicas
  mayastor_use_develop_images = var.mayastor_use_develop_images
  node_names                  = [for worker in slice(module.k8s.cluster_nodes, 1, length(module.k8s.cluster_nodes)) : worker.name]
  server_upload_dir           = var.server_upload_dir
}

