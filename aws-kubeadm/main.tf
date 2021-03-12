module "k8s" {
  source = "./modules/k8s"

  cluster_name = var.cluster_name
  num_workers  = var.num_workers

  aws_instance_root_size_gb = var.aws_instance_root_size_gb
  aws_instance_type_worker  = var.aws_instance_type_worker
  aws_region                = var.aws_region
  docker_version            = var.docker_version
  ebs_volume_size           = var.ebs_volume_size
  flannel_version           = var.flannel_version
  kubernetes_version        = var.kubernetes_version

  ssh_public_keys = var.ssh_public_keys

  tags = var.tags

  install_packages            = var.install_packages
  mayastor_use_develop_images = var.mayastor_use_develop_images
}

module "mayastor-dependencies" {
  source = "./modules/mayastor-dependencies"

  docker_insecure_registry = var.docker_insecure_registry
  k8s_master_ip            = module.k8s.cluster_nodes[0].public_ip
  kernel_version           = var.kernel_version

  workers = {
    for worker in slice(module.k8s.cluster_nodes, 1, length(module.k8s.cluster_nodes)) :
    worker.name => worker.public_ip
  }
  depends_on = [module.k8s]
}

module "mayastor" {
  count      = var.deploy_mayastor ? 1 : 0
  depends_on = [module.mayastor-dependencies, module.k8s]

  k8s_master_ip               = module.k8s.cluster_nodes[0].public_ip
  mayastor_disk               = module.k8s.mayastor_disk
  mayastor_replicas           = var.mayastor_replicas
  mayastor_use_develop_images = var.mayastor_use_develop_images
  node_names                  = [for worker in slice(module.k8s.cluster_nodes, 1, length(module.k8s.cluster_nodes)) : worker.name]
  server_upload_dir           = "/root/tf-upload"
  source                      = "./modules/mayastor"
}
