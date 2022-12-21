#!/bin/bash

apt-get update -y
apt-get upgrade -y

local_ip=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
provider_id="$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)/$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"

instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

CUR_HOSTNAME=$(cat /etc/hostname)
NEW_HOSTNAME=$instance_id

hostnamectl set-hostname $NEW_HOSTNAME
hostname $NEW_HOSTNAME
sudo sed -i "s/$CUR_HOSTNAME/$NEW_HOSTNAME/g" /etc/hosts
sudo sed -i "s/$CUR_HOSTNAME/$NEW_HOSTNAME/g" /etc/hostname

curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.23.9+k3s1 K3S_TOKEN=coIeS98V5UxzKYTLX0Uzzd4pkxfPSwBxiCUFtUm1sURd66mnZlT3uhk sh -s - --cluster-init --node-ip $local_ip --advertise-address $local_ip  --kubelet-arg="cloud-provider=external" --flannel-backend=none  --disable-cloud-controller --disable=servicelb --disable=traefik --write-kubeconfig-mode 644 --kubelet-arg="provider-id=aws:///$provider_id"

kubectl apply -f https://github.com/aws/aws-node-termination-handler/releases/download/v1.13.3/all-resources.yaml
kubectl apply -f https://raw.githubusercontent.com/rahul-yadav-hub/K3s-aws/main/aws/rbac.yml
kubectl apply -f https://raw.githubusercontent.com/rahul-yadav-hub/K3s-aws/main/aws/aws-cloud-controller-manager-daemonset.yml
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml