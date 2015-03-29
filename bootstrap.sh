#!/usr/bin/env bash

apt-get update
apt-get install -y curl

apt-get install git gcc redis-server
apt-get install zlib zlib-devel libyaml-devel libffi-devel openssl-devel

gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
curl -L https://get.rvm.io | bash -s stable

rvm install ruby-2.1.1

mkdir /opt/uawc -p
cd /opt/uawc

# git clone