#!/bin/bash
# Cài đặt 
sudo docker rmi -f $(sudo docker images -q) || true
# Cài đặt 
sudo docker rm -f $(sudo docker ps -aq) || true

cd InternetIncome-main
#
sudo rm -rf containers.txt
sudo rm -rf earnappdata
sudo rm -rf containernames.txt
sudo rm -rf resolv.conf
sudo cp /home/ubuntu/updateproxy.txt /home/ubuntu/InternetIncome-main/proxies.txt
sudo bash internetIncome.sh --start
