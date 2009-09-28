Instructions for setting up a Rails CI Server
=============================================

These are the instructions for setting up an environment to run a [Continuous Integration](http://martinfowler.com/articles/continuousIntegration.html) environment for Rails.  If you want to hack on the Rails source code, you can use these instructions to reliably set up an environment which will automatically run all of the Rails unit tests on your branch, and let you know if you have broken anything.

NOTE: We'd like to rewrite these scripts use Chef, but that will take some work.  Please contact 
thewoolleyman+railsci@gmail.com if you'd like to help.


Start with a clean server
-------------------------

These instructions and scripts are designed and tested to be run on a minimal Ubuntu server installation (currently at release 8.10).  You can purchase a hosted server, or run a virtual machine.  You CAN use an existing machine, but it automatically installs many packages, so be warned that it may not work and may render your machine unusable.

Here are virtual machine solutions you can try:

* Hosted
  * [EngineYard Cloud](http://www.engineyard.com/cloud-services) donates EC2 instances for the [official Rails CI servers](http://ci.rubyonrails.org)
  * Any Ubuntu 9 AMI on Amazon EC2.  Search for 'ubuntu.*9.*base' in the ElasticFox 'Images' tab.
* Local Virtual Machine Setup.  The current boxes are using `ami-0d729464 - alestic/ubuntu-9.04-jaunty-base-20090614.manifest.xml`
  * [VMWare Player (win)](http://www.vmware.com/products/player/)
  * [VMWare Fusion (mac)](http://www.vmware.com/download/fusion/)
  * [VMWare Ubuntu base image](http://www.vmware.com/appliances/directory/)
    * [7-Zip archiver to extract images](http://www.7-zip.org/) ('7za x <file>' to extract)


Step 1: Download and run the 'bootstrap\_rails\_ci.sh' script
-------------------------------------------------------------

* Log on to your server (you can use the root user or a local user)
* Download the bootstrap\_rails\_ci.sh script and run it:

        wget -O /tmp/bootstrap_rails_ci.sh http://github.com/rails/rails/raw/master/ci/bootstrap_rails_ci.sh

* Run the script, this will also create a 'ci' user and prompt you for a password for the new user.  If you are 
  not running as root, you may need to type your sudo password.  You can optionally specify a ruby interpreter,
  which rails branches to build, an override url for the git repo, and which ci sub-projects to set up (e.g.
  'activesupport,actionpack,rails', 'rails' means all):

        RUBY_VERSION=1.8.6-p287 RAILS_GIT_REPO_URL=git://github.com/rails/rails.git RAILS_GIT_BRANCHES=master,2-3-stable RAILS_CI_PROJECTS=rails sh /tmp/bootstrap_rails_ci.sh

Step 2: 
------------------------------------------------------

* Browse to the server at port 3333, and the builds should be running!

Known Problems:
---------------

* Aptitude pops up a prompt during mysql-server-5.0 installation and hangs install.  Even though a workaround is in `setup_rails_dependencies.rb`, it doesn't work when run as part of the script.  You may have to install this manually
* `bootstrap_rails_ci.sh` doesn't properly fail and exit if a sub-script fails.
* Hostname is not set