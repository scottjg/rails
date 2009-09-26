#!/bin/bash

echo "Setting up Rails Continuous Integration server..."

if [ ! `whoami` = 'ci' ]; then
  wget -O /tmp/create_ci_user.sh http://github.com/thewoolleyman/cinabox/raw/master/create_ci_user.sh
  sh /tmp/create_ci_user.sh
  if [ ! $? = 0 ]; then echo "Unable to create ci user" && exit; fi
fi

wget -O /tmp/ci_user_nopasswd_sudo.sh http://github.com/thewoolleyman/cinabox/raw/master/ci_user_nopasswd_sudo.sh
sh /tmp/ci_user_nopasswd_sudo.sh
if [ ! $? = 0 ]; then echo "Unable to grant ci user no-password sudo authority" && exit; fi

if [ -z $RAILS_GIT_DOWNLOAD_URL ]; then RAILS_GIT_DOWNLOAD_URL='http://github.com/rails/rails/raw/master'; fi
if [ -z $RAILS_GIT_REPO_URL ]; then RAILS_GIT_REPO_URL='git://github.com/rails/rails.git'; fi
if [ -z $RAILS_GIT_BRANCHES ]; then RAILS_GIT_BRANCHES='master,2-3-stable'; fi
if [ -z $CINABOX_GIT_DOWNLOAD_URL ]; then CINABOX_GIT_DOWNLOAD_URL='http://github.com/thewoolleyman/cinabox/tarball/master'; fi

echo "  Downloading cinabox.tar.gz to /home/ci/cinabox..."
sudo su -l -c "mkdir ~/cinabox" ci
sudo su -l -c "wget -O ~/cinabox/cinabox.tar.gz $CINABOX_GIT_DOWNLOAD_URL" ci
echo "  Unzipping cinabox.tar.gz to /home/ci/cinabox..."
sudo su -l -c "tar --directory=/home/ci/cinabox --overwrite --strip-components=1 -zxvf ~/cinabox/cinabox.tar.gz" ci
# FIXME: this abort-on-error-and-exit checking isn't working...
if [ ! $? = 0 ]; then echo "Unable to download and unzip cinabox" && exit; fi

echo "  Running cinabox to bootstrap ruby..."
DEFAULT_RUBY_VERSION=1.8.6-p287
if [ -z $RUBY_VERSION ]; then RUBY_VERSION=$DEFAULT_RUBY_VERSION; fi
sudo su -l -c "RUBY_VERSION=$RUBY_VERSION FORCE_RUBY_UNINSTALL=true ~/cinabox/bootstrap_ruby.sh" ci
if [ ! $? = 0 ]; then echo "Unable to bootstrap ruby" && exit; fi

echo "  Running cinabox to setup ci..."
sudo su -l -c "CRUISE_USER=ci NO_DAEMON_START=true ruby ~/cinabox/setup_ci.rb --force" ci
if [ ! $? = 0 ]; then echo "Unable to setup ci" && exit; fi

echo "  Downloading setup_rails_dependencies to /home/ci/railsci..."
sudo su -l -c "mkdir ~/railsci" ci

sudo su -l -c "wget -O ~/railsci/setup_rails_dependencies.rb $RAILS_GIT_DOWNLOAD_URL/ci/setup_rails_dependencies.rb" ci
sudo su -l -c "ruby ~/railsci/setup_rails_dependencies.rb" ci
if [ ! $? = 0 ]; then echo "Unable to setup rails dependencies" && exit; fi

sudo su -l -c "wget -O ~/railsci/setup_rails_ci_project.rb $RAILS_GIT_DOWNLOAD_URL/ci/setup_rails_ci_project.rb" ci
sudo su -l -c "RAILS_GIT_REPO_URL=$RAILS_GIT_REPO_URL RAILS_GIT_BRANCHES=$RAILS_GIT_BRANCHES RAILS_CI_PROJECTS=$RAILS_CI_PROJECTS ruby ~/railsci/setup_rails_ci_project.rb" ci
if [ ! $? = 0 ]; then echo "Unable to setup rails ci project" && exit; fi

echo "  Rails Continuous Integration server setup complete!"
