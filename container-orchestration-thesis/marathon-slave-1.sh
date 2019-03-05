#!/bin/bash


if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# https://github.com/mesosphere/open-docs/blob/master/getting-started/install.md#verifying-installation

# Install keyserver
# Only works on 16.04
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv DF7D54CBE56151BF DISTRO=$(lsb_release -is | tr '[:upper:]' '[:lower:]') CODENAME=$(lsb_release -cs)

echo "deb http://repos.mesosphere.com/ubuntu xenial main" | sudo tee /etc/apt/sources.list.d/mesosphere.list

sudo apt-get -y update
sudo apt-get -y install mesos --allow-unauthenticated

# Install marathon as well otherwise the marathon user is not created
sudo apt-get -y install marathon --allow-unauthenticated

sudo -- sh -c "echo $(( RANDOM % 255 )) > /etc/zookeeper/conf/myid"


# Single server setup
#   tickTime=2000
#   dataDir=/var/zookeeper
#   clientPort=2181
# > bin/zkServer.sh start

# Multi-sever deployment
#tickTime=2000
# read -p 'zookeeper address 1: ' zkaddr1
#read -p 'zookeeper address 2: ' zkaddr2

# cat >/etc/zookeeper/conf/zoo.cfg <<EOL
# dataDir=/var/zookeeper/
# clientPort=2181
# initLimit=5
# syncLimit=2
# server.1=${zkaddr1}:2888:3888
# EOL
#server.2=${zkaddr2}:2888:3888

# read -p 'Install Master '
# sudo systemctl restart zookeeper

sudo systemctl stop zookeeper
sudo sh -c "echo manual > /etc/init/zookeeper.override"
sudo systemctl disable zookeeper
sudo systemctl stop mesos-master
sudo systemctl disable mesos-master
sudo systemctl stop marathon
sudo systemctl disable marathon

read -p 'Mesos Master address 1 : ' mmstr

cat >/etc/mesos/zk <<EOL
zk://${mmstr}:2181/mesos
EOL


sudo systemctl stop mesos-slave
echo 'docker,mesos' > /etc/mesos-slave/containerizers
sudo systemctl start mesos-slave
