resource "null_resource" "mayastor_dependencies" {
  for_each = var.workers

  connection {
    type = "ssh"
    host = each.value
  }

  # NOTE: kernel is tightly correlated with image used for installation. See ../k8s/main.tf search "ubuntu/images"
  # and keep them in sync.
  provisioner "remote-exec" {
    inline = [
      "set -xve",
      "echo \"${self.triggers.nr_hugepages}\" > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages",
      "echo \"vm.nr_hugepages = ${self.triggers.nr_hugepages}\" > /etc/sysctl.d/10-mayastor-hugepages.conf",
      "apt-get -qy update && apt-get -qy install linux-modules-extra-5.8.0-43-generic",
      "echo 'nvme-tcp' >> /etc/modules",
      "systemd-run /bin/sh -c 'sleep 1 && reboot'", # needed to surely get the hugepages right after boot
    ]
  }

  triggers = {
    nr_hugepages = var.nr_hugepages
  }
}

// Set label openebs.io/engine=mayastor on all cluster nodes - we want to run MSN on all nodes
resource "null_resource" "mayastor_node_label" {
  for_each = toset(keys(var.workers))
  triggers = {
    k8s_master_ip = var.k8s_master_ip
  }
  connection {
    host = self.triggers.k8s_master_ip
  }
  provisioner "remote-exec" {
    inline = ["kubectl label node \"${each.key}\" openebs.io/engine=mayastor"]
  }
  provisioner "remote-exec" {
    when   = destroy
    inline = ["kubectl label node \"${each.key}\" openebs.io/engine-"]
  }
}

