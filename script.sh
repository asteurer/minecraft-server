#!/bin/bash

domain=minecraft-server
ip_addr=192.168.0.225

# curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--tls-san $(curl http://checkip.amazonaws.com)" sh -
# Retrieve the KUBECONFIG file from the server, alter it, then place it in the ~/.kube directory
ssh \
	-o StrictHostKeyChecking=no \
	-o UserKnownHostsFile=/dev/null \
	root@$ip_addr \
	'cat /etc/rancher/k3s/k3s.yaml' | IP_ADDR=$ip_addr DOMAIN=$domain python3 kubeconfig_edit.py > ~/.kube/$domain.config