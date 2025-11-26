#!/bin/bash
set -e

# 🧩 Bước 1: Chuyển vào thư mục
cd /dome/ubuntun/earn/InternetIncome-main || { echo "❌ Thư mục không tồn tại!"; exit 1; }

# 🧩 Bước 2: Xóa file và thư mục nếu tồn tại
[ -f containers.txt ] && sudo rm -f containers.txt
[ -d earnappdata ] && sudo rm -rf earnappdata
[ -f containernames.txt ] && sudo rm -f containernames.txt
[ -f resolv.conf ] && sudo rm -f resolv.conf

# 🧩 Bước 3: Chạy internetIncome.sh
sudo bash internetIncome.sh --start
