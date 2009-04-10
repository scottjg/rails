#!/bin/bash

echo "Setting up Rails Continuous Integration server..."

if [ -e /home/ci ]; then echo "ci user already exists.  To delete the ci user and start from scratch, type 'sudo deluser --remove-home ci'" && exit; fi
  
echo "  Creating ci user..."
sudo useradd -s /bin/bash -m -p `mkpasswd -H md5 password` ci

echo "  Giving ci user no-password sudo privileges"
