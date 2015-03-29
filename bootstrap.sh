#!/usr/bin/env bash

apt-get update
apt-get install -y curl git gcc redis-server

gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
curl -L https://get.rvm.io | bash -s stable
source /usr/local/rvm/scripts/rvm
echo "source /usr/local/rvm/scripts/rvm" >> ~/.bashrc

rvm install ruby-2.2.1
rvm use ruby-2.2.1@uawc --default --create

mkdir /opt -p
cd /opt
git clone https://github.com/Ser1aL/uawc.git
cd uawc

bundle install

echo 'Starting services'
cd /opt/uawc && ./restart_server.sh
echo 'Puma started!'
cd /opt/uawc && ./restart_resque.sh
echo 'Resque started!'