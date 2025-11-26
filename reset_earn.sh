#!/bin/bash

cd /dome/ubuntun/earn/InternetIncome-main
#
sudo rm -rf containers.txt
sudo rm -rf earnappdata
sudo rm -rf containernames.txt
sudo rm -rf resolv.conf
sudo bash internetIncome.sh --start
