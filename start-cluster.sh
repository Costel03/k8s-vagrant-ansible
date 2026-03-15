#!/bin/bash

set -e  # Exit on first error

MASTER_IP="192.168.56.10"
WORKER1_IP="192.168.56.11"
WORKER2_IP="192.168.56.12"

echo "➡️  Starting up VMs..."
vagrant.exe up --provision

echo "🔑 Setting up SSH keys & config..."
bash "$(dirname "$0")/setup-access.sh"

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
wait_for_ssh "$MASTER_IP"
wait_for_ssh "$WORKER1_IP"
wait_for_ssh "$WORKER2_IP"

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

# 🔑 Fetch kubeconfig now that the cluster is up
echo "📋 Fetching kubeconfig from master..."
bash "$(dirname "$0")/setup-access.sh"

echo "✅ Cluster is ready! Try: kubectl get nodes"