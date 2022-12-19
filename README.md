## Documentation still progress 80%
Arsitektur CI/CD 
![image](https://user-images.githubusercontent.com/22531977/208345070-9612be93-3a85-496c-85cf-0e7f40f2b8b9.png)
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
![kubernetes namespaces](https://user-images.githubusercontent.com/22531977/208349345-7bceaf12-944b-43a1-b740-01b0a4023d83.PNG)
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
   
## Installation Gitlab
1. Installing the Dependencies
   ```sh
   sudo apt update
   sudo apt install ca-certificates curl openssh-server postfix tzdata perl
   ```
2. Installing GitLab
   ```sh
   cd /tmp
   curl -LO https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh
   less /tmp/script.deb.sh
   sudo bash /tmp/script.deb.sh
   sudo apt install gitlab-ce
   ```
3. Adjusting the Firewall Rules
   ```sh
   sudo ufw status
   sudo ufw allow http
   sudo ufw allow https
   sudo ufw allow OpenSSH
   sudo ufw status
   ```
4. Editing the GitLab Configuration File
   ```sh
   sudo nano /etc/gitlab/gitlab.rb
   ...
   ## GitLab URL
   ##! URL on which GitLab will be reachable.
   ##! For more details on configuring external_url see:
   ##! https://docs.gitlab.com/omnibus/settings/configuration.html#configuring-the-external-url-for-gitlab
   ##!
   ##! Note: During installation/upgrades, the value of the environment variable
   ##! EXTERNAL_URL will be used to populate/replace this value.
   ##! On AWS EC2 instances, we also attempt to fetch the public hostname/IP
   ##! address from AWS. For more details, see:
   ##! https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-retrieval.html
   external_url 'https://your_domain'
   ...
   ```
5. Reconfigure GitLab:
   ```sh
   sudo gitlab-ctl reconfigure
   ```
6. Performing Initial Configuration Through the Web Interface
   ```sh
   Visit the domain name of your GitLab server in your web browser:
   https://your_domain
   ```
![2](https://user-images.githubusercontent.com/22531977/208348929-0ccd2a69-a415-4963-a0a1-a558d7189683.PNG)
## Installations Sonar CE
1. Install OpenJDK 11
   ```sh
   sudo apt-get install openjdk-11-jdk -y
   ```
2. Install and Configure PostgreSQL
   ```sh
   sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
   wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -
   sudo apt install postgresql postgresql-contrib -y
   sudo systemctl enable postgresql
   sudo systemctl start postgresql
   sudo passwd postgres
   su - postgres
   createuser sonar
   psql
   ALTER USER sonar WITH ENCRYPTED password 'my_strong_password';
   CREATE DATABASE sonarqube OWNER sonar;
   GRANT ALL PRIVILEGES ON DATABASE sonarqube to sonar;
   \q
   exit
   ```
3. Download and Install SonarQube
   ```sh
   sudo apt-get install zip -y
   sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-<VERSION_NUMBER>.zip
   sudo unzip sonarqube-<VERSION_NUMBER>.zip
   sudo mv sonarqube-<VERSION_NUMBER> /opt/sonarqube
   ```
4. Add SonarQube Group and User
   ```sh
   sudo groupadd sonar
   sudo useradd -d /opt/sonarqube -g sonar sonar
   sudo chown sonar:sonar /opt/sonarqube -R
   ```
5. Configure SonarQube
   ```sh
   sudo nano /opt/sonarqube/conf/sonar.properties
   sonar.jdbc.username=sonar
   sonar.jdbc.password=my_strong_password
   sonar.jdbc.url=jdbc:postgresql://localhost:5432/sonarqube
   ```
   Save and exit the file.
   Edit the sonar script file.
   ```sh
   sudo nano /opt/sonarqube/bin/linux-x86-64/sonar.sh
   ```
   About 50 lines down, locate this line:
   ```sh
   RUN_AS_USER=sonar
   ```
   save and exit the file
6. Setup Systemd service
   ```sh
   sudo nano /etc/systemd/system/sonar.service
   ```
   paste the following lines to the file.
   ```
   [Unit]

   Description=SonarQube service
   After=syslog.target network.target

   [Service]
   Type=forking

   ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
   ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop

   User=sonar
   Group=sonar

   Restart=always

   LimitNOFILE=65536
   LimitNPROC=4096

   [Install]
   WantedBy=multi-user.target
   ```
   Save and exit the file.
   Enable the SonarQube service to run at system startup.
   ```sh
   sudo systemctl enable sonar
   sudo systemctl start sonar
   sudo systemctl status sonar
   ```
7. Modify Kernel System Limits
   ```sh
   sudo nano /etc/sysctl.conf
   ```
   Add the following lines.
   ```sh
   vm.max_map_count=262144
   fs.file-max=65536
   ulimit -n 65536
   ulimit -u 4096
   ```
   save and Reboot the system to apply the changes.
   ```sh
   sudo reboot
   ```
8. Access SonarQube Web Interface [username: admin and password: admin]
   ```sh
   http://192.0.2.123:9000
   ```
## Setup NFS Server and Storage Class for Kubernetes Cluster
On NFS server node
```sh
sudo systemctl status nfs-server
sudo apt install nfs-kernel-server nfs-common portmap
sudo start nfs-server
mkdir -p /srv/nfs/mydata 
chmod -R 777 /srv/nfs/

sudo echo "/srv/nfs/mydata  *(rw,sync,no_subtree_check,no_root_squash,insecure)" >> /etc/exports
sudo exportfs -rv
showmount -e
```
On master Node
```sh
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/

helm install nfs nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --set nfs.server=10.8.60.205 --set nfs.path=/srv/nfs/mydata --set storageClass.name=nfs --set storageClass.defaultClass=true -n nfs --create-namespace
```
## Setup MetalLB for Load Balancer
On master node
```sh
helm repo add metallb https://metallb.github.io/metallb
helm repo update

vim address-pool.yaml
configInline:
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 10.8.60.201-10.8.60.205

helm install metallb metallb/metallb -f address-pool.yaml -n metallb --create-namespace
```
## Setup NGINX ingress
On master node
```sh
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress ingress-nginx/ingress-nginx --set controller.service.loadBalancerIP=10.8.60.214 -n ingress --create-namespace
```
kubectl create deployment nginx --image=nginx kubectl expose deploy nginx --port 80 --type LoadBalancer
## Deploy Aplikasi Nginx 
On master node
```sh
kubectl create deploy nginx-app --image=nginx
kubectl expose deploy nginx-app --type=LoadBalancer --port=80
```
## Deploy mysql & wordpress
Create a kustomization.yaml 
```sh
cat <<EOF >./kustomization.yaml
secretGenerator:
- name: mysql-pass
  literals:
  - password=YOUR_PASSWORD
EOF
```
Add resource configs for MySQL and WordPress 
```sh
curl -LO https://k8s.io/examples/application/wordpress/mysql-deployment.yaml
curl -LO https://k8s.io/examples/application/wordpress/wordpress-deployment.yaml
```
Add them to kustomization.yaml file
```sh
cat <<EOF >>./kustomization.yaml
resources:
  - mysql-deployment.yaml
  - wordpress-deployment.yaml
EOF
```
Apply and Verify 
The kustomization.yaml contains all the resources for deploying a WordPress site and a MySQL database. You can apply the directory by
```sh
kubectl apply -k ./
```
![wordpress](https://user-images.githubusercontent.com/22531977/208349139-90d2b836-18f5-4791-b03b-e5a59b0bd8d9.PNG)

## Installation Maven
1. Download the JDK Binaries
   ```sh
   wget https://download.java.net/java/GA/jdk13.0.1/cec27d702aa74d5a8630c65ae61e4305/9/GPL/openjdk-13.0.1_linux-x64_bin.tar.gz
   tar -xvf openjdk-13.0.1_linux-x64_bin.tar.gz
   mv jdk-13.0.1 /opt/
   ```
2. Setting JAVA_HOME and Path Environment Variables
   ```sh
   JAVA_HOME='/opt/jdk-13.0.1'
   PATH="$JAVA_HOME/bin:$PATH"
   export PATH
   ```
3. Verify the Java Installation
   ```sh
   java -version
   ```
4. Download the Maven Binaries
   ```sh
   wget https://mirrors.estointernet.in/apache/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz  
   tar -xvf apache-maven-3.6.3-bin.tar.gz
   mv apache-maven-3.6.3 /opt/
   ```
5. Setting M2_HOME and Path Variables
   ```sh
   M2_HOME='/opt/apache-maven-3.6.3'
   PATH="$M2_HOME/bin:$PATH"
   export PATH
   ```
6. Verify the Maven installation
   ```sh
   mvn -version
   Apache Maven 3.6.3 (cecedd343002696d0abb50b32b541b8a6ba2883f)
   Maven home: /opt/apache-maven-3.6.3
   Java version: 13.0.1, vendor: Oracle Corporation, runtime: /opt/jdk-13.0.1
   Default locale: en, platform encoding: UTF-8
   OS name: "linux", version: "4.15.0-47-generic", arch: "amd64", family: "unix"
   ```
## Installation Ansible
```sh
sudo apt-add-repository ppa:ansible/ansible
sudo apt update
sudo apt install ansible
```
## Installation Jfrog Artifactory
1. Import repository GPG Key
   ```sh
   sudo apt update
   wget -qO - https://api.bintray.com/orgs/jfrog/keys/gpg/public.key | sudo apt-key add -
   ```
2. Add JFrog Artifactory to Ubuntu 20.04
   ```sh
   echo "deb https://jfrog.bintray.com/artifactory-debs focal main" | sudo tee /etc/apt/sources.list.d/jfrog.list
   sudo apt update
   ```
3. Install JFrog Artifactory on Ubuntu 20.04
   ```sh
   sudo apt update
   sudo apt install jfrog-artifactory-oss
   ```
   start and enable service
   ```sh
   sudo systemctl start artifactory.service
   sudo systemctl enable artifactory.service
   ```
4. Access Artifactory Web Interface
   ```sh
   http://SERVERIP_OR_DOMAIN:8081/artifactory﻿
   ```
   The default logins are:
   ```sh
   Username: admin
   Password: password
   ```
## Setup Configuration on Jenkins
Generate token
Login to sonarqube web admin > login > going to My Account > Security > Enter token name > Generate token

Configure sonarqube server
Login to jenkins web admin > login > going to Manage Jenkins > Configure System > Sonarqube server > Fill data > Save

Configure scanner server
Login to jenkins web admin > login > going to Manage Jenkins > Manage plugins > Available plugins > Search "sonarqube" on search box > click checkbox "sonarqube" > Download and install > restart jenkins

Going to Manage Jenkins > Global tool configuration > Sonarqube scanner > Fill data > Save

Configure Maven
Login to jenkins web admin > login > going to Manage Jenkins > Manage plugins > Available plugins > Search "Maven" on search box > click checkbox "Maven plugin" > Download and install > restart jenkins

Configure Jfrog
Login to jenkins web admin > login > going to Manage Jenkins > Manage plugins > Available plugins > Search "Jfrog" on search box > click checkbox "Jfrog plugin" > Download and install > restart jenkins


Going to Manage Jenkins > Global tool configuration > Maven > Maven installations > Fill data > Save

Add credentials bitbucket, public key ssh, sonar

Config jenkins pipeline
Login to jenkins web admin > new item > pipeline > pipeline script from SCM > Fill data
![pipeline](https://user-images.githubusercontent.com/22531977/208350034-26aa2f4e-3ab8-450a-a579-c78df2ec9fbc.PNG)
![maven](https://user-images.githubusercontent.com/22531977/208350274-ba0cfd29-a28a-4faa-9519-750067b85c14.PNG)
![imran](https://user-images.githubusercontent.com/22531977/208355225-4e4b82af-b3e9-4ce3-b96b-82e00642c1ac.PNG)



   
   
   
