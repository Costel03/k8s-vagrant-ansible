#!/bin/bash
#
# bootstrap-cluster.sh
#
# Full cluster bootstrap script. Run from WSL after `vagrant up` completes
# and SSH keys have been copied (setup-access.sh).
#
# Usage:
#   cd /mnt/c/Users/iacob/Documents/repos/k8s-vagrant-ansible
#   ./bootstrap-cluster.sh
#
set -euo pipefail

ANSIBLE_DIR="/mnt/c/Users/iacob/Documents/repos/k8s-vagrant-ansible/ansible-ubuntu"
ARGOCD_VALUES="/mnt/c/Users/iacob/Documents/repos/ArgoCD/helm/argocd/values.yaml"
APP_OF_APPS="/mnt/c/Users/iacob/Documents/repos/ArgoCD/bootstrap/app-of-apps.yaml"

# ── Colours ──────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}==>${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ── 1. Copy SSH keys ──────────────────────────────────────────────────
info "Step 1/5 — Copying SSH keys and fetching kubeconfig..."
bash /mnt/c/Users/iacob/Documents/repos/k8s-vagrant-ansible/setup-access.sh

# ── 2. Run Ansible ────────────────────────────────────────────────────
info "Step 2/5 — Running Ansible playbook (containerd, kubeadm, Calico)..."
cd "$ANSIBLE_DIR"
ansible-playbook -i inventory.ini playbook.yml

# ── 3. Wait for nodes ready ───────────────────────────────────────────
info "Step 3/5 — Waiting for all nodes to be Ready..."
for i in $(seq 1 30); do
  NOT_READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -v " Ready" || true)
  if [[ -z "$NOT_READY" ]]; then
    info "All nodes are Ready."
    break
  fi
  echo "  Waiting... ($i/30)"
  sleep 10
done
kubectl get nodes

# ── 4. Install ArgoCD ─────────────────────────────────────────────────
info "Step 4/5 — Installing ArgoCD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

helm repo add argo https://argoproj.github.io/argo-helm --force-update
helm repo update

helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --values "$ARGOCD_VALUES" \
  --wait --timeout 5m

info "Waiting for ArgoCD server to be ready..."
kubectl rollout status deployment/argocd-server -n argocd --timeout=180s

# ── 5. Apply App-of-Apps ──────────────────────────────────────────────
info "Step 5/5 — Applying App-of-Apps bootstrap..."
kubectl apply -f "$APP_OF_APPS"

# ── Done ──────────────────────────────────────────────────────────────
echo ""
info "Cluster bootstrap complete!"
echo ""
echo "ArgoCD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
echo ""
warn "NEXT STEPS (manual):"
echo "  1. Wait for ArgoCD to sync all apps (metallb → nfs → vault → eso → ingress → monitoring)"
echo "  2. Unseal Vault:"
echo "       kubectl exec -n hashicorp-vault vault-0 -- vault operator init   # first time only"
echo "       kubectl exec -n hashicorp-vault vault-0 -- vault operator unseal  # run 3x with unseal keys"
echo "  3. Create vault-token secret for External Secrets Operator:"
echo "       kubectl create secret generic vault-token -n eso \\"
echo "         --from-literal=token=<YOUR_VAULT_TOKEN>"
echo "  4. Access ArgoCD UI at: http://argocd.local (add to /etc/hosts: 192.168.56.20 argocd.local)"
