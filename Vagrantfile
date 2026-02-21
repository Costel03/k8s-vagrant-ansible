VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/jammy64"
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true

  # Master Node
  config.vm.define "master-node" do |node|
    node.vm.hostname = "master-node"
    node.vm.network "private_network", ip: "192.168.56.10"
    node.vm.synced_folder ".", "/vagrant", disabled: true

    node.vm.provider :virtualbox do |v|
      v.memory = 6144
      v.cpus = 3
    end

    node.vm.provision "shell", inline: <<-SHELL
      export DEBIAN_FRONTEND=noninteractive
      apt-get update -y
      apt-get upgrade -yq
      apt-get install -y python3 python3-pip python-is-python3
    SHELL
  end

  # Worker Node 1
  config.vm.define "worker-node1" do |node|
    node.vm.hostname = "worker-node1"
    node.vm.network "private_network", ip: "192.168.56.11"
    node.vm.synced_folder ".", "/vagrant", disabled: true

    node.vm.provider :virtualbox do |v|
      v.memory = 4096
      v.cpus = 3
    end

    node.vm.provision "shell", inline: <<-SHELL
      export DEBIAN_FRONTEND=noninteractive
      apt-get update -y
      apt-get upgrade -yq
      apt-get install -y python3 python3-pip python-is-python3
    SHELL
  end

  # Optional: Add worker-node2 if needed
  config.vm.define "worker-node2" do |node|
    node.vm.hostname = "worker-node2"
    node.vm.network "private_network", ip: "192.168.56.12"
    node.vm.synced_folder ".", "/vagrant", disabled: true
  
    node.vm.provider :virtualbox do |v|
      v.memory = 4096
      v.cpus = 3
    end
  
    node.vm.provision "shell", inline: <<-SHELL
      export DEBIAN_FRONTEND=noninteractive
      apt-get update -y
      apt-get upgrade -yq
      apt-get install -y python3 python3-pip python-is-python3
    SHELL
  end  
end
