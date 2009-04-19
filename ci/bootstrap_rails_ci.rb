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

echo "  Downloading setup scripts..."
sudo su - -c 'mkdir ~/cinabox' ci
sudo su - -c 'wget -O ~/cinabox/cinabox.tar.gz wget http://github.com/thewoolleyman/cinabox/tarball/master' ci
sudo su - -c 'mkdir ~/railsci' ci
sudo su - -c 'wget -O ~/railsci/setup_rails_dependencies.rb http://github.com/rails/rails/blob/master/ci/setup_rails_ci.rb?raw=true' ci
