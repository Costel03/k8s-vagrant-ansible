## This is a K8-cluster deployment project. This set up was done with Windows WSL.  

- We are deploying a kubernetes cluster using 3 VMs provisioned by Vagrant and ansible for configuration. 

        - Step 1: Update and Upgrade Ubuntu (all nodes)
        - Step 2: Disable Swap (all nodes)
        - Step 3: Add Kernel Parameters (all nodes)
        - Step 4: Install Containerd Runtime (all nodes)
        - Step 5: Add Apt Repository for Kubernetes (all nodes)
        - Step 6: Install Kubectl, Kubeadm, and Kubelet (all nodes)
        - Step 7: Initialize Kubernetes Cluster with Kubeadm (master node)
        - Step 8: Add Worker Nodes to the Cluster (worker nodes)
        - Step 9: Install Kubernetes Network Plugin (master node)
        - Step 10: Verify the cluster and test (master node)


## Windows + WSL Workflow

### 1. VM Provisioning (Windows)
Open PowerShell or CMD in your project directory:

```bash
vagrant plugin install vagrant-hostmanager
vagrant up
```

### 2. Copy Vagrant SSH Keys to WSL
In WSL terminal:

```bash
cd /mnt/c/Users/iacob/Documents/kubernetes_cluster-project
chmod +x copy_vagrant_keys.sh
./copy_vagrant_keys.sh
```

### 3. Run Ansible Playbook from WSL
In WSL terminal:

```bash
cd /mnt/c/Users/iacob/Documents/kubernetes_cluster-project/ansible-ubuntu
ansible-playbook -i inventory.ini playbook.yml
```

### 4. Copy kubeconfig for kubectl in WSL
In WSL terminal:

```bash
mkdir -p ~/.kube
scp -i ~/.ssh/vagrant_master-node vagrant@192.168.56.10:/home/vagrant/.kube/config ~/.kube/config
chmod 600 ~/.kube/config
```

### 5. Use kubectl from WSL
```bash
kubectl get nodes
```

### 6. Troubleshooting
- If you need to reset the cluster, SSH to master node and run:
```bash
ssh -i ~/.ssh/vagrant_master-node vagrant@192.168.56.10
sudo kubeadm reset -f
sudo rm -rf /etc/kubernetes/* /var/lib/etcd /var/lib/kubelet/* /root/.kube
sudo reboot
```

Re-run the Ansible playbook after reboot.

## Once deplooyment is completed: export the kube config file

        (Handled automatically by Ansible playbook)

## Steps to add worker node to cluster

        (Handled automatically by Ansible playbook and SSH key copy script)

    - Use the below command to generate the token and command for worker node to join the cluster 

        - To join worker nodes, SSH to master node and run:
        ```bash
        kubeadm token create --print-join-command
        ```
        - Label worker nodes:
        ```bash
        kubectl label node worker-node1 node-role.kubernetes.io/worker=worker
        ```


    - Use the below command sequence to reset your cluster and remove the config set up 

        (See troubleshooting section above)