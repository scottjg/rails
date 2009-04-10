#!/bin/bash

echo "Setting up Rails Continuous Integration server..."

if [ -e /home/ci ]; then echo "ci user already exists.  To delete the ci user and start from scratch, type 'sudo deluser --remove-home ci'" && exit; fi
  
echo "  Creating ci user..."
sudo useradd -s /bin/bash -m -p `mkpasswd -H md5 password` ci

echo "  Giving ci user no-password sudo privileges"
rm /tmp/sudoers.tmp
sudo cp /etc/sudoers /etc/sudoers.bak
cp /etc/sudoers /tmp/sudoers.tmp
echo "ci      ALL=(ALL) NOPASSWD: ALL" >> /tmp/sudoers.tmp
visudo -q -c -s -f /tmp/sudoers.tmp
if [ ! $? = 0 ]; then echo "error editing sudoers file, run 'visudo -q -c -s -f /tmp/sudoers.tmp'" && exit; fi
sudo cp /tmp/sudoers.tmp /etc/sudoers
