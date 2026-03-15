VAGRANTFILE_API_VERSION = "2"

# Node definitions – easy to add/remove nodes
NODES = [
  { name: "k8s-master",  ip: "192.168.56.10", memory: 6144, cpus: 3 },
  { name: "k8s-worker1", ip: "192.168.56.11", memory: 4096, cpus: 3 },
  { name: "k8s-worker2", ip: "192.168.56.12", memory: 4096, cpus: 3 },
]

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/jammy64"
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true

  NODES.each do |node_cfg|
    config.vm.define node_cfg[:name] do |node|
      node.vm.hostname = node_cfg[:name]
      node.vm.network "private_network", ip: node_cfg[:ip]
      node.vm.synced_folder ".", "/vagrant", disabled: true

      node.vm.provider :virtualbox do |v|
        v.name   = node_cfg[:name]
        v.memory = node_cfg[:memory]
        v.cpus   = node_cfg[:cpus]
      end

      node.vm.provision "shell", inline: <<-SHELL
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        apt-get upgrade -yq
        apt-get install -y python3 python3-pip python-is-python3
      SHELL
    end
  end
end
