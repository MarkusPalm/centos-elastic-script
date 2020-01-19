#!/bin/sh

passwd -d root

sysctl -w vm.max_map_count=262144

echo "elasticsearch soft nofile 65536
elasticsearch hard nofile 65536
elasticsearch hard nproc 4096
elasticsearch soft nproc 4096
elasticsearch soft memlock unlimited
elasticsearch hard memlock unlimited" >> /etc/security/limits.conf

sed -i 's/enforcing/disabled/' /etc/selinux/config

dnf -y upgrade
dnf install -y java-1.8.0-openjdk-headless nano

dnf config-manager --add-repo https://repo.fortinet.com/repo/centos/7/os/x86_64/fortinet.repo
dnf install -y forticlient

curl -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.8.0.rpm 
dnf install -y elasticsearch-6.8.0.rpm
rm elasticsearch-6.8.0.rpm 

curl -O https://artifacts.elastic.co/downloads/kibana/kibana-6.8.0-x86_64.rpm
dnf install -y kibana-6.8.0-x86_64.rpm
rm kibana-6.8.0-x86_64.rpm

curl -O https://packages.elastic.co/curator/5/centos/7/Packages/elasticsearch-curator-5.7.6-1.x86_64.rpm
dnf install -y elasticsearch-curator-5.7.6-1.x86_64.rpm
rm elasticsearch-curator-5.7.6-1.x86_64.rpm

dnf clean all

firewall-cmd --zone=public --add-port=9200/tcp --permanent
firewall-cmd --zone=public --add-port=9300/tcp --permanent
firewall-cmd --zone=public --add-port=5601/tcp --permanent

echo "node.name: elastic-dh-01
cluster.name: fs-elastic-clu1
network.host: 172.31.102.40
discovery.zen.minimum_master_nodes: 3
discovery.zen.ping.unicast.hosts: ["172.31.102.30","172.31.102.31","172.31.102.32","172.31.102.33"]
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

echo "server.port: 5601
server.host: "172.31.102.40"
server.name: "elastic-dh-01"
elasticsearch.hosts: ["http://172.31.102.40:9200"]" > /etc/kibana/kibana.yml

sed -i "/-Xms1g/c\-Xms24g" /etc/elasticsearch/jvm.options
sed -i "/-Xmx1g/c\-Xmx24g" /etc/elasticsearch/jvm.options

sed -i '/#LimitMEMLOCK=infinity/LimitMEMLOCK=infinity/' /etc/sysconfig/elasticsearch

systemctl enable elasticsearch.service
systemctl enable kibana.service

reboot now