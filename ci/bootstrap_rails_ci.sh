#!/bin/bash

echo "Setting up Rails Continuous Integration server..."

wget -O /tmp/create_ci_user.sh http://github.com/thewoolleyman/cinabox/raw/master/create_ci_user.sh
chmod a+x /tmp/create_ci_user.sh
~/create_ci_user.sh
if [ ! $? = 0 ]; then echo "Unable to create ci user" && exit; fi

if [ -z $RAILS_GIT_DOWNLOAD_URL ]; then RAILS_GIT_DOWNLOAD_URL='http://github.com/thewoolleyman/rails/raw/master'; fi

echo "  Downloading cinabox.tar.gz to /home/ci/cinabox..."
sudo su - -c "mkdir ~/cinabox" ci
sudo su - -c "wget -O ~/cinabox/cinabox.tar.gz http://github.com/thewoolleyman/cinabox/tarball/master" ci
echo "  Unzipping cinabox.tar.gz to /home/ci/cinabox..."
sudo su - -c "tar --directory=/home/ci/cinabox --overwrite --strip-components=1 -zxvf ~/cinabox/cinabox.tar.gz" ci

echo "  Downloading setup_rails_dependencies to /home/ci/railsci..."
sudo su - -c "mkdir ~/railsci" ci
sudo su - -c "wget -O ~/railsci/setup_rails_dependencies.rb $RAILS_GIT_DOWNLOAD_URL/ci/setup_rails_dependencies.rb" ci

echo "  Download complete!  Please complete the remaining steps:"
echo "  1. Log in as ci user: 'sudo su - ci'"
echo "  2. Run bootstrap_ruby.sh: 'RUBY_VERSION=1.8.6-p287 ~/cinabox/bootstrap_ruby.sh'"
echo "  3. Run setup_ci: 'ruby ~/cinabox/setup_ci.rb'"
echo "  4. Run setup_rails_dependencies.rb: 'ruby ~/railsci/setup_rails_dependencies.rb'"