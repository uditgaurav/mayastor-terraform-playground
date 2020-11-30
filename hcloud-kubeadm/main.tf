module "ssh-keys" {
  count = var.use_mayadata_ssh_keys ? 1 : 0
  source = "./modules/ssh-keys"
  admin_ssh_keys = var.admin_ssh_keys
}

module "k8s" {
  source = "./modules/k8s"

  admin_ssh_keys    = var.use_mayadata_ssh_keys ? module.ssh-keys.admin_ssh_keys : var.admin_ssh_keys
  hcloud_csi_token  = var.hcloud_csi_token
  hcloud_token      = var.hcloud_token
  hetzner_location  = var.hetzner_location
  node_count        = var.node_count
  server_upload_dir = var.server_upload_dir

  hugepages_2M_amount = var.hugepages_2M_amount

}

module "mayastor" {
  depends_on = [module.k8s]

  source = "./modules/mayastor"

  k8s_master_ip               = module.k8s.master_ip
  mayastor_disk               = "/dev/sdb"
  mayastor_use_develop_images = var.mayastor_use_develop_images
  node_names                  = module.k8s.nodes
  server_upload_dir           = var.server_upload_dir
}

