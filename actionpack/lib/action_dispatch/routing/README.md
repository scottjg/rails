URL\_FOR Optimization
=====================

Table of Contents
--------------------------
[Description](#description)

[Our Progress](#our_progress)
* [Getting Started](#getting_started)
 * [Setting up the Rails Environment](#setting_up_the_rails_environment)
   *  [Our Forked Repository](#our_forked_repository)
   *  [The Other Rails App Used](#other_rails_app_used)

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




<a name="our_forked_repository" />
##### Our Forked Repository
This is how we forked the repository and our current repository
Rails Repository: https://github.com/rails/rails.git
Our Forked Repository: https://github.com/rhintz42/url\_for\_optimization.git




<a name="other_rails_app_used" />
##### The other Rails App Used
This is the reason for needing another rails app and this is the rails app





### Files Used for This Project
#### url\_for.rb
Path To File: actionpack/lib/action\_dispatch/routing/url\_for.rb
##### Methods of Interest
###### url\_for
###### url\_for\_improved

#### url\_for\_test.rb
Path To File: actionpack/test/controller/url\_for\_test.rb
##### Methods of Interest

#### pattern.rb
Path To File: actionpack/lib/action\_dispatch/journey/path/pattern.rb
##### Methods of Interest

#### route\_set.rb
Path To File: actionpack/lib/action\_dispatch/routing/route\_set.rb
##### Methods of Interest

#### formatter.rb
Path to File: actionpack/lib/action\_dispatch/journey/formatter.rb
##### Methods of Interest

#### routes.rb
Path to File: actionpack/lib/action\_dispatch/journey/routes.rb
##### Methods of Interest




Debugging
-------------------------

Presentation on general Rails Routing & Debugging Commands:
https://docs.google.com/a/stanford.edu/presentation/d/1veFgQ0gfrF6q3NvKCGR4bMBwwI1Jx-VjpXfJ0hRm1g8/edit#slide=id.p

https://gist.github.com/rhintz42/5044571

