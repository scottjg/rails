#!/bin/bash

echo "Setting up Rails Continuous Integration server..."

wget -O ~/create_ci_user.sh http://github.com/thewoolleyman/cinabox/raw/master/create_ci_user.sh
chmod a+x ~/create_ci_user.sh
~/create_ci_user.sh
if [ ! $? = 0 ]; then echo "Unable to create ci user" && exit; fi

if [ -z $RAILS_GIT_DOWNLOAD_URL ]; then RAILS_GIT_DOWNLOAD_URL='http://github.com/thewoolleyman/rails/raw/master'; fi

echo "  Downloading cinabox..."
sudo su - -c "mkdir ~/cinabox" ci
sudo su - -c "wget -O ~/cinabox/cinabox.tar.gz http://github.com/thewoolleyman/cinabox/tarball/master" ci
echo "  Unzipping cinabox..."
sudo su - -c "tar --directory=/home/ci/cinabox --overwrite --strip-components=1 -zxvf ~/cinabox/cinabox.tar.gz" ci

echo "  Downloading cinabox..."
sudo su - -c "mkdir ~/railsci" ci
sudo su - -c "wget -O ~/railsci/setup_rails_dependencies.rb {$RAILS_GIT_DOWNLOAD_URL}/ci/setup_rails_dependencies.rb" ci
