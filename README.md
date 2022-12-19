## Stack Tech Used
1. Kubernetes [1 Master & 1 Worker]
2. Jenkins
3. Gitlab
4. Sonar CE
5. MetalLB
6. Nginx Ingress
7. Wordpress
8. Postgresql
9. Mysql
10. Dockerhub
11. Docker
12. Ansible
13. Maven
14. Bitbucket

## Installation Kubernetes
Master: A Kubernetes Master is where control API calls for the pods, replications controllers, services, nodes and other components of a Kubernetes cluster are executed.
Node: A Node is a system that provides the run-time environments for the containers. A set of container pods can span multiple nodes.
1. Install Kubernetes Cluster on Ubuntu 20.04
   ```sh
   sudo apt update
   sudo apt -y full-upgrade
   [ -f /var/run/reboot-required ] && sudo reboot -f
   ```
2. Install kubelet, kubeadm and kubectl
   ```sh
   sudo apt -y install curl apt-transport-https
   curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
   echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
   sudo apt update
   sudo apt -y install vim git curl wget kubelet kubeadm kubectl
   sudo apt-mark hold kubelet kubeadm kubectl
   ```
3. Disable Swap
   ```sh
   sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
   ```
   Now disable Linux swap space permanently in /etc/fstab. Search for a swap line and add # (hashtag) sign in front of the line.
   ```sh
   $ sudo vim /etc/fstab
   #/swap.img	none	swap	sw	0	0
   ```
   Enable kernel modules and configure sysctl.
   ```sh
   # Enable kernel modules
   sudo modprobe overlay
   sudo modprobe br_netfilter

   # Add some settings to sysctl
   sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
   net.bridge.bridge-nf-call-ip6tables = 1
   net.bridge.bridge-nf-call-iptables = 1
   net.ipv4.ip_forward = 1
   EOF

   # Reload sysctl
   sudo sysctl --system
   ```
4. Install Container runtime, I'am user Docker on this lab
   ```sh
   # Add repo and Install packages
    sudo apt update
    sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt update
    sudo apt install -y containerd.io docker-ce docker-ce-cli

    # Create required directories
    sudo mkdir -p /etc/systemd/system/docker.service.d

    # Create daemon json config file
    sudo tee /etc/docker/daemon.json <<EOF
    {
      "exec-opts": ["native.cgroupdriver=systemd"],
      "log-driver": "json-file",
      "log-opts": {
        "max-size": "100m"
      },
      "storage-driver": "overlay2"
    }
    EOF

    # Start and enable Services
    sudo systemctl daemon-reload 
    sudo systemctl restart docker
    sudo systemctl enable docker
   ```
5. Install Mirantis cri-dockerd as Docker Engine shim for Kubernetes
   Install cri-dockerd using ready binary
   ```sh
   sudo apt update
   sudo apt install git wget curl
   VER=$(curl -s https://api.github.com/repos/Mirantis/cri-dockerd/releases/latest|grep tag_name | cut -d '"' -f 4|sed 's/v//g')
   echo $VER
   wget https://github.com/Mirantis/cri-dockerd/releases/download/v${VER}/cri-dockerd-${VER}.amd64.tgz
   tar xvf cri-dockerd-${VER}.amd64.tgz
   sudo mv cri-dockerd/cri-dockerd /usr/local/bin/
   cri-dockerd --version
   ```
   Configure systemd units for cri-dockerd:
   ```sh
   wget https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.service
   wget https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.socket
   sudo mv cri-docker.socket cri-docker.service /etc/systemd/system/
   sudo sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
   sudo systemctl daemon-reload
   sudo systemctl enable cri-docker.service
   sudo systemctl enable --now cri-docker.socket
   systemctl status cri-docker.socket
   ```
6. Initialize master node
   ```sh
   lsmod | grep br_netfilter
   sudo systemctl enable kubelet
   sudo kubeadm init \
   --pod-network-cidr=192.168.0.0/16 \
   --cri-socket unix:///run/cri-dockerd.sock 
   ```
   Configure kubectl using commands in the output:
   ```sh
   mkdir -p $HOME/.kube
   sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
   kubectl cluster-info
   ```
   Additional Master nodes can be added using the command in installation output:
   ```sh
   kubeadm join master-ip:6443 --token sr4l2l.2kvot0pfalh5o4ik \
     --discovery-token-ca-cert-hash sha256:c692fb047e15883b575bd6710779dc2c5af8073f7cab460abd181fd3ddb29a18 \
     --control-plane
   ```
7. Install network plugin on Master
   ```sh
   kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml 
   kubectl create -f https://docs.projectcalico.org/manifests/custom-resources.yaml
   ```
   Confirm that all of the pods are running:
   ```sh
   watch kubectl get pods --all-namespaces
   ```
## Installation Jenkins
1. First, add the repository key to the system:
   ```sh
   wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
   sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
   sudo apt update
   sudo apt install jenkins
   ```
2. Starting Jenkins
   ```sh
   sudo systemctl start jenkins
   sudo systemctl status jenkins
   ```
3. Allow port 8080
   ```sh
   sudo ufw allow 8080
   ```
4. Setting Up Jenkins
   To set up your installation, visit Jenkins on its default port, 8080, using your server domain name or IP address: http://your_server_ip_or_domain:8080
   In the terminal window, use the cat command to display the password:
   ```sh
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```
   Copy the 32-character alphanumeric password from the terminal and paste it into the Administrator password field, then click Continue.
##

   
   
   
