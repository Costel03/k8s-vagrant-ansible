#!/bin/bash

# Set your project path (adjust if needed)
PROJECT_PATH="/mnt/c/Users/iacob/Documents/kubernetes_cluster-project"
VAGRANT_MACHINES="$PROJECT_PATH/.vagrant/machines"
SSH_DIR="$HOME/.ssh"
KUBE_DIR="$HOME/.kube"

mkdir -p "$SSH_DIR"
mkdir -p "$KUBE_DIR"

# Copy all Vagrant private keys
for vm in master-node worker-node1 worker-node2; do
    KEY_SRC="$VAGRANT_MACHINES/$vm/virtualbox/private_key"
    KEY_DEST="$SSH_DIR/vagrant_$vm"
    if [ -f "$KEY_SRC" ]; then
        cp "$KEY_SRC" "$KEY_DEST"
        chmod 600 "$KEY_DEST"
        echo "Copied $KEY_SRC to $KEY_DEST"
    else
        echo "Key for $vm not found at $KEY_SRC"
    fi
done

# Optionally copy kubeconfig if it exists
KUBECONFIG_SRC="$PROJECT_PATH/kubeconfig"
KUBECONFIG_DEST="$KUBE_DIR/config"
if [ -f "$KUBECONFIG_SRC" ]; then
    cp "$KUBECONFIG_SRC" "$KUBECONFIG_DEST"
    chmod 600 "$KUBECONFIG_DEST"
    echo "Copied kubeconfig to $KUBECONFIG_DEST"
else
    echo "No kubeconfig found at $KUBECONFIG_SRC"
fi

echo "Done."