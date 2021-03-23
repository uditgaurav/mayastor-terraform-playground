# FIXME: use configuration management tool rather than terraform ;-)
#
# Or so they say in doc. However this seem to work, install/uninstall/update
# :-) Please let me know if not.

resource "null_resource" "docker_daemon_config_workers" {
  for_each = var.workers

  connection {
    type = "ssh"
    host = jsondecode(self.triggers.workers)[each.key]
  }

  provisioner "file" {
    content     = self.triggers.docker_config
    destination = "/etc/docker/daemon.json"
  }

  provisioner "remote-exec" {
    inline = ["systemctl restart docker"]
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "set -e",
      "rm -f /etc/docker/daemon.json",
      "systemctl restart docker",
    ]
  }

  triggers = {
    docker_config = <<-EOF
    {
      "insecure-registries" : ${var.docker_insecure_registry != "" ? jsonencode([var.docker_insecure_registry]) : "[]"}
      ${var.docker_registry_mirror != "" ? ",\"registry-mirrors\": [\"${var.docker_registry_mirror}\"]" : ""}
    }
    EOF
    workers       = jsonencode(var.workers)
  }
}

