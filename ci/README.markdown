Instructions for setting up a Rails CI Server
=============================================

Many thanks to [RimuHosting.com](http://rimuhosting.com) for hosting the Official Rails CI Server Farm!

These are the instructions for setting up an environment to run a [Continuous Integration](http://martinfowler.com/articles/continuousIntegration.html) environment for Rails.  If you want to hack on the Rails source code, you can use these instructions to reliably set up an environment which will automatically run all of the Rails unit tests on your branch, and let you know if you have broken anything.


Start with a clean server
-------------------------

These instructions and scripts are designed and tested to be run on a minimal Ubuntu server installation (currently at release 8.10).  You can purchase a hosted server, or run a virtual machine.  You CAN use an existing machine, but it automatically installs many packages, so be warned that it may not work and may render your machine unusable.

Here are virtual machine solutions you can try:

* Hosted VPS
  * [RimuHosting.com](http://rimuhosting.com) has affordable Virtual Private Servers (VPSs)
* Virtual Machine Setup
  * [VMWare Player (win)](http://www.vmware.com/products/player/)
  * [VMWare Fusion (mac)](http://www.vmware.com/download/fusion/)
  * [VMWare image](http://www.vmware.com/appliances/directory/cat/45)
    * [7-Zip archiver to extract images](http://www.7-zip.org/) ('7za x <file>' to extract)


Download and run the 'setup\_rails\_ci.sh' script
-------------------------------------------------

* Log on to your server (you can use the root user or a local user)
* Download the setup\_rails\_ci.sh script:

    wget -O /tmp/setup\_rails\_ci.sh http://github.com/rails/rails/raw/master/ci/setup\_rails\_ci.sh