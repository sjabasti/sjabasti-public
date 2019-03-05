#!/bin/bash


# https://github.com/mesosphere/open-docs/blob/master/getting-started/install.md#verifying-installation
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Install keyserver
# Only works on 16.04
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv DF7D54CBE56151BF DISTRO=$(lsb_release -is | tr '[:upper:]' '[:lower:]') CODENAME=$(lsb_release -cs)

echo "deb http://repos.mesosphere.com/ubuntu xenial main" | sudo tee /etc/apt/sources.list.d/mesosphere.list

sudo apt-get -y update
sudo apt-get -y install mesos marathon --allow-unauthenticated

sudo -- sh -c "echo $(( RANDOM % 255 )) > /etc/zookeeper/conf/myid"

# use correct java
sudo apt-get -y install openjdk-8-jdk
echo "Use jave 8:"
sudo update-alternatives --config java

#read -p 'zookeeper 1: ' zkaddr1

# cat >/etc/zookeeper/conf/zoo.cfg <<EOL
# dataDir=/var/zookeeper/
# clientPort=2181
# initLimit=5
# syncLimit=2
# server.1=${zkaddr1}:2888:3888
# EOL
# server.2=${zkaddr2}:2888:3888


sudo service stop zookeeper
sudo service stop mesos-master
sudo service stop mesos-slave

sudo sh -c "echo manual > /etc/init/zookeeper.override"
sudo systemctl disable zookeeper

#https://stackoverflow.com/questions/40620544/systemd-zookeeper-service-failed
cat >/etc/systemd/system/zookeeper.service <<EOL
[Unit]
Description=ZooKeeper Service
Documentation=http://zookeeper.apache.org
Requires=network.target
After=network.target
After=syslog.target

[Service]
Environment=ZOO_LOG_DIR=/zookeeper/logs
SyslogIdentifier=zookeeper
Type=forking
User=zookeeper
Group=zookeeper
ExecStart=/usr/share/zookeeper/bin/zkServer.sh start
ExecStop=/usr/share/zookeeper/bin/zkServer.sh stop
ExecReload=/opt/zookeeper/bin/zkServer.sh restart

[Install]
WantedBy=default.target
EOL


sudo systemctl start zookeeper

sudo chown -R zookeeper:zookeeper /var/log/zookeeper /var/zookeeper


sudo systemctl start zookeeper
sudo systemctl enable zookeeper



cat >/etc/mesos/zk <<EOL
zk://<ip>:2181/mesos
EOL

# Only 1 master
cat >/etc/mesos-master/quorum <<EOL
1
EOL


sudo systemctl start mesos-master
sudo systemctl start mesos-slave


# Marathon
#https://stackoverflow.com/questions/48496184/marathon-exited-with-status-1
cat >/etc/default/marathon <<EOL
MARATHON_MASTER=zk://127.0.0.1:2181/mesos
MARATHON_ZK=zk://127.0.0.1:2181/marathon
EOL

sudo systemctl stop marathon
sudo systemctl start marathon


sudo systemctl stop mesos-slave
echo 'docker,mesos' > /etc/mesos-slave/containerizers
sudo systemctl start mesos-slave
