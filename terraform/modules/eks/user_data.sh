#!/bin/bash
# User data script for EKS worker nodes
# This script bootstraps the EKS worker nodes with the cluster

/etc/eks/bootstrap.sh ${cluster_name} \
  --b64-cluster-ca ${ca_data} \
  --apiserver-endpoint ${endpoint} \
  --container-runtime containerd \
  --kubelet-extra-args '--node-labels=nodegroup=custom'