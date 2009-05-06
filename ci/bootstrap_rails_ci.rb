#!/bin/bash

echo "Setting up Rails Continuous Integration server..."

# TODO: prompt to autodelete existing ci user
if [ -e /home/ci ]; then echo "ci user already exists.  To delete the ci user and start from scratch, type 'sudo deluser --remove-home ci'" && exit; fi

echo "  Creating ci user..."
if [ -z $CI_PASSWORD ] read -p "    Please type password for ci user and press enter:" -s -a CI_PASSWORD
sudo useradd -s /bin/bash -m -p `mkpasswd -H md5 $CI_PASSWORD` ci

echo "  Giving ci user no-password sudo privileges"
rm /tmp/sudoers.tmp
sudo cp /etc/sudoers /etc/sudoers.bak
cp /etc/sudoers /tmp/sudoers.tmp
echo "ci      ALL=(ALL) NOPASSWD: ALL" >> /tmp/sudoers.tmp
visudo -q -c -s -f /tmp/sudoers.tmp
if [ ! $? = 0 ]; then echo "error editing sudoers file" && exit; fi
sudo cp /tmp/sudoers.tmp /etc/sudoers

if [ -z $RAILS_GIT_URL ]; then RAILS_GIT_URL='http://github.com/thewoolleyman/rails'; fi

echo "  Downloading cinabox..."
sudo su - -c "mkdir ~/cinabox" ci
sudo su - -c "wget -O ~/cinabox/cinabox.tar.gz http://github.com/thewoolleyman/cinabox/tarball/master" ci
echo "  Unzipping cinabox..."
sudo su - -c "tar --directory=~/cinabox --overwrite -zxvf ~/cinabox/cinabox.tar.gz" ci
echo "  Running cinabox bootstrap_ruby.sh..."
sudo su - -c "echo 'TODO: run boostrap_ruby.sh" ci

sudo su - -c "mkdir ~/railsci" ci
sudo su - -c "wget -O ~/railsci/setup_rails_dependencies.rb {$RAILS_GIT_URL}/raw/master/ci/setup_rails_dependencies.rb" ci
