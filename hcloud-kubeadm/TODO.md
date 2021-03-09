# TODO

[ ] enable metrics/handle(?) for moac
    - `csi-attacher W1109 13:25:33.325934       1 metrics.go:142] metrics endpoint will not be started because `metrics-address` was not specified.`
[ ] fix auth to kubelet and don't use --deprecated-kubelet-completely-insecure in `module/k8s/install-metrics-server.tf`
[ ] for the love of God handle machines' ssh keys properly instead of ignoring them
    - pass pre-generated keys using `user_data` (`cloud-init`) to `hcloud_server` resource?
    - use CA based ssh keys?
[ ] use hetzner VPC (network) in hcloud
[ ] automatic runs of [./TEST_SCENARIOS.md](./TEST_SCENARIOS.md)
[ ] add deploy yamls contents to triggers for `module.mayastor.null_resource.mayastor` to ease up updates

# Wishlist

[ ] make modules separable - usable by themselves - probably won't happen
    - document variables and have defaults in modules' `variables.tf`
    - figure out how to get required variable values without top-level module
    - ...?
[ ] somehow partition existing nvme disk to use as a device for mayastor - faster, local, non ceph-based
    - on Debian passing `user_data=resize_rootfs: false`; manually removing sda1 with parted, creating two partitions instead, resizing rootfs and rebooting worked, however on ubuntu with same version of parted I wasn't able to force answers Yes, Ignore to parted for working with used partition. Rescue system might help.
[ ] speed up infra build by deploying master and nodes together
    - WARNING - if provisioning of master fails subsequent terraform apply will not fix it as only resource that is being waited for will be recreated
       - might still be useful as it speed up the happy path
    - just removing dependency of nodes to master doesn't work -> nodes are stuck on kubeadm join
        - split kubeadm join from node install
        - when master is fully bootstrapped, installed create a file somewhere
        - create another resource that will wait for this file on master
        - do kubeadm join on nodes depending on this resource
[ ] make deploy of mayastor optional depending on a variable `deploy_mayastor` (like in `aws-kubeadm`)
[ ] move installing iscsi daemon from k8s to mayastor-dependencies module
