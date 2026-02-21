#!/bin/bash

set -e  # Exit on first error

master_node_ip_address="192.168.56.17"
worker_node1_ip_address="192.168.56.18"
worker_node2_ip_address="192.168.56.19"

echo "➡️  Starting up VMs..."
vagrant.exe up --provision

echo "🔑 Removing old SSH fingerprints..."
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$master_node_ip_address" || true
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$worker_node1_ip_address" || true
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$worker_node2_ip_address" || true

echo "🔐 Fixing private key permissions..."
chmod 600 ~/Documents/k8s-cluster/.vagrant/machines/*/virtualbox/private_key

# ✅ Function to check SSH port (22) reachability
wait_for_ssh() {
  local ip="$1"
  echo "⏳ Waiting for SSH to become available on $ip..."
  for _ in {1..20}; do
    if nc -z "$ip" 22; then
      echo "✅ SSH is up on $ip"
      return 0
    fi
    sleep 3
  done
  echo "❌ Timed out waiting for SSH on $ip"
  return 1
}

# 🧪 Check that all required nodes are reachable
wait_for_ssh "$master_node_ip_address"
wait_for_ssh "$worker_node1_ip_address"
wait_for_ssh "$worker_node2_ip_address"

echo "📡 Checking connectivity to all nodes with Ansible ping..."
if ! ANSIBLE_HOST_KEY_CHECKING=False ansible -i ansible-ubuntu/inventory.ini all -m ping; then
    echo "❌ One or more nodes are unreachable. Check network or SSH access."
    exit 1
fi

# 📦 Run the Ansible playbook
echo "🚀 Running Ansible playbook to deploy the cluster..."
if ! ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ansible-ubuntu/inventory.ini ansible-ubuntu/playbook.yml; then
  echo "❌ Ansible playbook execution failed."
  exit 1
fi


echo "✅ Ansible playbook executed successfully."