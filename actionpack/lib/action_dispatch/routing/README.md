URL\_FOR Optimization
=====================

Table of Contents
--------------------------
[Description](#description)

[Our Progress](#our_progress)
* [Getting Started](#getting_started)
 * [Setting up the Rails Environment](#setting_up_the_rails_environment)
* [Files Used for This Project](#files_used_for_this_project)
 * [url\_for.rb](#url_for.rb)
 * [url\_for\_test.rb](#url_for_test.rb)
 * [pattern.rb](#pattern.rb)
 * [route\_set.rb](#route_set.rb)
 * [formatter.rb](#formatter.rb)
 * [routes.rb](#routes.rb)
* [Debugging](#debugging)

<a name="description" />
Description
--------------------------

Currently, url\_for is a huge bottleneck for rails apps.
We are currently in the process of updating url\_for to use the cached routes efficiently.

<a name="progress" />
Our Progress
--------------------------

Through exploration and testing, we have started to make progress on making the method url\_for run faster.
Below we will discus the necessary files to get started, files of importance, and debugging tools that have helped us thus far.

<a name="getting_started" />
### Getting Started
To get started, we needed to do 3 things:
set up our environment for rails,
create our own forked rails repository,
and create a test app to test out the routes in the repository




<a name="setting_up_the_rails_environment" />
#### Setting up the Rails Environment

This is how we set up the Rails environment on our own computer




##### Our Forked Repository
This is how we forked the repository and our current repository
Rails Repository: https://github.com/rails/rails.git
Our Forked Repository: https://github.com/rhintz42/url\_for\_optimization.git




##### The other Rails App Used
This is the reason for needing another rails app and this is the rails app




<a name="files_used_for_this_project" />
### Files Used for This Project

<a name="url_for.rb" />
#### url\_for.rb
Path To File: actionpack/lib/action\_dispatch/routing/url\_for.rb
##### Methods of Interest
###### url\_for
###### url\_for\_improved

<a name="url_for_test.rb" />
#### url\_for\_test.rb
Path To File: actionpack/test/controller/url\_for\_test.rb
##### Methods of Interest

<a name="pattern.rb" />
#### pattern.rb
Path To File: actionpack/lib/action\_dispatch/journey/path/pattern.rb
##### Methods of Interest

<a name="route_set.rb" />
#### route\_set.rb
Path To File: actionpack/lib/action\_dispatch/routing/route\_set.rb
##### Methods of Interest

<a name="formatter.rb" />
#### formatter.rb
Path to File: actionpack/lib/action\_dispatch/journey/formatter.rb
##### Methods of Interest

<a name="routes.rb" />
#### routes.rb
Path to File: actionpack/lib/action\_dispatch/journey/routes.rb
##### Methods of Interest



<a name="debugging" />
Debugging
-------------------------

Presentation on general Rails Routing & Debugging Commands:
https://docs.google.com/a/stanford.edu/presentation/d/1veFgQ0gfrF6q3NvKCGR4bMBwwI1Jx-VjpXfJ0hRm1g8/edit#slide=id.p

https://gist.github.com/rhintz42/5044571

