#!/bin/bash
#
# setup-access.sh — Copy Vagrant SSH keys, configure SSH aliases,
#                   and fetch the kubeconfig from the master node.
#
# After running this script you can simply:
#   ssh k8s-master        (instead of the long ssh -i ... command)
#   ssh k8s-worker1
#   ssh k8s-worker2
#   kubectl get nodes     (kubeconfig is placed in ~/.kube/config)
#
set -euo pipefail

# ── Paths ────────────────────────────────────────────────────────────
# Resolve the Windows project path visible from WSL
WIN_PROJECT_PATH="/mnt/c/Users/iacob/Documents/repos/k8s-vagrant-ansible"
VAGRANT_MACHINES="$WIN_PROJECT_PATH/.vagrant/machines"
SSH_DIR="$HOME/.ssh"
KUBE_DIR="$HOME/.kube"

NODES=("k8s-master" "k8s-worker1" "k8s-worker2")
IPS=("192.168.56.10" "192.168.56.11" "192.168.56.12")

mkdir -p "$SSH_DIR" "$KUBE_DIR"

# ── 1. Copy Vagrant private keys ────────────────────────────────────
echo "==> Copying Vagrant SSH private keys..."
for vm in "${NODES[@]}"; do
    KEY_SRC="$VAGRANT_MACHINES/$vm/virtualbox/private_key"
    KEY_DEST="$SSH_DIR/$vm"
    if [[ -f "$KEY_SRC" ]]; then
        cp "$KEY_SRC" "$KEY_DEST"
        chmod 600 "$KEY_DEST"
        echo "    $vm  ✔"
    else
        echo "    $vm  ✘  (key not found at $KEY_SRC)"
    fi
done

# ── 2. Configure ~/.ssh/config for easy SSH access ──────────────────
echo "==> Configuring SSH aliases..."

# Marker used to identify our managed block
MARKER_BEGIN="# --- k8s-vagrant-ansible BEGIN ---"
MARKER_END="# --- k8s-vagrant-ansible END ---"

# Remove any previous managed block
if [[ -f "$SSH_DIR/config" ]]; then
    sed -i "/$MARKER_BEGIN/,/$MARKER_END/d" "$SSH_DIR/config"
fi

{
    echo "$MARKER_BEGIN"
    for i in "${!NODES[@]}"; do
        cat <<EOF
Host ${NODES[$i]}
    HostName ${IPS[$i]}
    User vagrant
    IdentityFile ${SSH_DIR}/${NODES[$i]}
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR

EOF
    done
    echo "$MARKER_END"
} >> "$SSH_DIR/config"

chmod 600 "$SSH_DIR/config"
echo "    SSH config updated  ✔"

# ── 3. Remove stale host-key fingerprints ───────────────────────────
echo "==> Cleaning old SSH fingerprints..."
for ip in "${IPS[@]}"; do
    ssh-keygen -f "$SSH_DIR/known_hosts" -R "$ip" 2>/dev/null || true
done

# ── 4. Fetch kubeconfig from master ─────────────────────────────────
echo "==> Fetching kubeconfig from k8s-master..."
if ssh k8s-master "test -f /home/vagrant/.kube/config" 2>/dev/null; then
    scp k8s-master:/home/vagrant/.kube/config "$KUBE_DIR/config"
    # Replace the internal API server address so kubectl works from the host
    sed -i "s|https://.*:6443|https://192.168.56.10:6443|g" "$KUBE_DIR/config"
    chmod 600 "$KUBE_DIR/config"
    echo "    kubeconfig saved to $KUBE_DIR/config  ✔"
else
    echo "    kubeconfig not available yet (cluster may not be initialized)"
fi

echo ""
echo "Done! You can now:"
echo "  ssh k8s-master       - connect to the control plane"
echo "  ssh k8s-worker1      - connect to worker 1"
echo "  ssh k8s-worker2      - connect to worker 2"
echo "  kubectl get nodes    - query the cluster"
