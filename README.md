# Kubernetes Cluster with Vagrant & Ansible

Deploy a 3-node Kubernetes cluster on VirtualBox VMs using Vagrant for provisioning and Ansible for configuration. Designed for a **Windows + WSL** workflow.

## Cluster Overview

| Node | IP | Resources |
|---|---|---|
| k8s-master | 192.168.56.10 | 6 GB RAM, 3 CPUs |
| k8s-worker1 | 192.168.56.11 | 4 GB RAM, 3 CPUs |
| k8s-worker2 | 192.168.56.12 | 4 GB RAM, 3 CPUs |

**Stack:** Ubuntu 22.04 (Jammy), Kubernetes v1.35.2, Containerd 1.7.23, Calico v3.29.1

## Prerequisites

- [VirtualBox](https://www.virtualbox.org/) installed on Windows
- [Vagrant](https://www.vagrantup.com/) installed on Windows
- WSL2 with Ubuntu (or similar)
- Ansible installed in WSL (`pip install ansible` or `apt install ansible`)

Install the required Vagrant plugin (once, from PowerShell):
```powershell
vagrant plugin install vagrant-hostmanager
```

## Quick Start (automated)

Run everything with a single script from **WSL**:

```bash
cd /mnt/c/Users/iacob/Documents/repos/k8s-vagrant-ansible
chmod +x start-cluster.sh setup-access.sh
bash start-cluster.sh
```

This script will:
1. Create the VMs with `vagrant up`
2. Copy SSH keys & configure SSH aliases (`setup-access.sh`)
3. Wait for all nodes to be reachable
4. Run the Ansible playbook to deploy Kubernetes
5. Fetch the kubeconfig to `~/.kube/config`

When it finishes you can immediately run:
```bash
kubectl get nodes
```

## Step-by-Step (manual)

### 1. Create the VMs (PowerShell)

```powershell
cd C:\Users\iacob\Documents\repos\k8s-vagrant-ansible
vagrant up
```

### 2. Set up SSH access & keys (WSL)

```bash
cd /mnt/c/Users/iacob/Documents/repos/k8s-vagrant-ansible
chmod +x setup-access.sh
bash setup-access.sh
```

This copies the Vagrant private keys and writes `~/.ssh/config` entries so you can connect with just:
```bash
ssh k8s-master
ssh k8s-worker1
ssh k8s-worker2
```

### 3. Deploy Kubernetes with Ansible (WSL)

```bash
cd /mnt/c/Users/iacob/Documents/repos/k8s-vagrant-ansible
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ansible-ubuntu/inventory.ini ansible-ubuntu/playbook.yml
```

### 4. Fetch the kubeconfig (WSL)

Run `setup-access.sh` again — now that the cluster is initialized it will also copy the kubeconfig:

```bash
bash setup-access.sh
```

### 5. Verify

```bash
kubectl get nodes
```

## What the Ansible Playbook Does

| Step | Scope | Description |
|---|---|---|
| 1 | All nodes | Disable swap |
| 2 | All nodes | Load kernel modules (`overlay`, `br_netfilter`) |
| 3 | All nodes | Apply sysctl networking parameters |
| 4 | All nodes | Install Containerd 1.7.23 with SystemdCgroup |
| 5 | All nodes | Add Kubernetes v1.35 apt repository |
| 6 | All nodes | Install kubelet, kubeadm, kubectl |
| 7 | Master | Initialize control plane with `kubeadm init` |
| 8 | Master | Install Calico CNI |
| 9 | Workers | Join the cluster using `kubeadm join` |

## Project Structure

```
.
├── Vagrantfile              # VM definitions (k8s-master, k8s-worker1, k8s-worker2)
├── start-cluster.sh         # One-command full deployment (WSL)
├── setup-access.sh          # Copy SSH keys, configure aliases, fetch kubeconfig
├── ansible-ubuntu/
│   ├── inventory.ini        # Ansible host inventory
│   ├── playbook.yml         # Main playbook
│   ├── group_vars/
│   │   └── all.yml          # Kubernetes version variable
│   └── roles/
│       ├── common/tasks/    # Shared setup (containerd, k8s packages)
│       ├── master/tasks/    # Control plane init, Calico, join token
│       └── worker/tasks/    # Join cluster, copy kubeconfig
```

## Troubleshooting

### Reset the cluster
SSH into the master and reset:
```bash
ssh k8s-master
sudo kubeadm reset -f
sudo rm -rf /etc/kubernetes/* /var/lib/etcd /var/lib/kubelet/* /root/.kube
sudo reboot
```
Then re-run the Ansible playbook.

### Destroy and rebuild from scratch
```powershell
# PowerShell
vagrant destroy -f
vagrant up
```
```bash
# WSL
bash start-cluster.sh
```

### Stale Vagrant state after renaming VMs
If you see errors about old machine names, remove leftover state:
```bash
rm -rf /mnt/c/Users/iacob/Documents/repos/k8s-vagrant-ansible/.vagrant/machines/<old-name>
```

### Label worker nodes
```bash
kubectl label node k8s-worker1 node-role.kubernetes.io/worker=worker
kubectl label node k8s-worker2 node-role.kubernetes.io/worker=worker
```