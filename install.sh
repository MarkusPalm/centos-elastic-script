#!/bin/sh

#remove root password
passwd -d root

#set recommended limits
sysctl -w vm.max_map_count=262144

echo "elasticsearch soft nofile 65536
elasticsearch hard nofile 65536
elasticsearch hard nproc 4096
elasticsearch soft nproc 4096
elasticsearch soft memlock unlimited
elasticsearch hard memlock unlimited" >> /etc/security/limits.conf

#disable selinux
sed -i 's/enforcing/disabled/' /etc/selinux/config

#install openjdk
dnf -y upgrade
dnf install -y java-1.8.0-openjdk-headless nano

#install forticlient (optional)
dnf config-manager --add-repo https://repo.fortinet.com/repo/centos/7/os/x86_64/fortinet.repo
dnf install -y forticlient

#install elasticsearch 6.8.0 (replace with your version)
curl -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.8.0.rpm 
dnf install -y elasticsearch-6.8.0.rpm
rm elasticsearch-6.8.0.rpm 

#install kibana (match to elasticsearch version)
curl -O https://artifacts.elastic.co/downloads/kibana/kibana-6.8.0-x86_64.rpm
dnf install -y kibana-6.8.0-x86_64.rpm
rm kibana-6.8.0-x86_64.rpm

#install curator (match to elasticsearch version)
curl -O https://packages.elastic.co/curator/5/centos/7/Packages/elasticsearch-curator-5.7.6-1.x86_64.rpm
dnf install -y elasticsearch-curator-5.7.6-1.x86_64.rpm
rm elasticsearch-curator-5.7.6-1.x86_64.rpm

dnf clean all

#open required ports
firewall-cmd --zone=public --add-port=9200/tcp --permanent
firewall-cmd --zone=public --add-port=9300/tcp --permanent
firewall-cmd --zone=public --add-port=5601/tcp --permanent

#data node config
echo "node.name: <host>
cluster.name: <cluster-name>
network.host: <host-ip>
discovery.zen.minimum_master_nodes: 3
discovery.zen.ping.unicast.hosts: ["<master-01>","<master-02>","<etc...>"]
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
http.port: 9200
node.master: false
node.data: true
node.ingest: true
search.remote.connect: false
node.attr.box_type: hot
xpack.ml.enabled: false
xpack.monitoring.enabled: true
xpack.monitoring.collection.enabled: true
bootstrap.memory_lock: true" > /etc/elasticsearch/elasticsearch.yml

#kibana config
echo "server.port: 5601
server.host: "<host-ip>"
server.name: "<host>"
elasticsearch.hosts: ["http://<host-ip>:9200"]" > /etc/kibana/kibana.yml

#allocate half of system ram
sed -i "/-Xms1g/c\-Xms<ram-amount>g" /etc/elasticsearch/jvm.options
sed -i "/-Xmx1g/c\-Xmx<ram-amount>g" /etc/elasticsearch/jvm.options

#set limitlock
sed -i '/#LimitMEMLOCK=infinity/LimitMEMLOCK=infinity/' /etc/sysconfig/elasticsearch

#enable elasticsearch and kibana on startup
systemctl enable elasticsearch.service
systemctl enable kibana.service

#restart
reboot now
