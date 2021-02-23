#! /bin/sh

set -eu

JOIN_CMD=$(cat ${join_file})

for node_ipv4 in ${k8s_nodes_ipv4}; do
	ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
		"root@$node_ipv4" -- $JOIN_CMD
	ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
		"root@$node_ipv4" -- systemctl enable docker kubelet
done

