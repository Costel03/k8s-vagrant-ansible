#!/bin/bash

PROJECT_PATH="/mnt/c/Users/iacob/Documents/k8s-local"
VAGRANT_MACHINES="$PROJECT_PATH/.vagrant/machines"
SSH_DIR="$HOME/.ssh"

mkdir -p "$SSH_DIR"

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

echo "Done."
echo "Done."