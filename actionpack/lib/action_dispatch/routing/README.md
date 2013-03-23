URL\_FOR Optimization
=====================

Table of Contents
--------------------------
[Description](#description)

[Our Progress](#our_progress)
* [Getting Started](#getting_started)
 * [Setting up the Rails Environment](#setting_up_the_rails_environment)
* [Files Used for This Project](#files_used_for_this_project)
 * [formatter.rb](#formatter.rb)
 * [pattern.rb](#pattern.rb)
 * [route\_set.rb](#route_set.rb)
 * [routes.rb](#routes.rb)
 * [url\_for.rb](#url_for.rb)
 * [url\_for\_test.rb](#url_for_test.rb)
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
Below we will discuss the necessary files to get started, files of importance, and debugging tools that have helped us thus far in working on this project.

<a name="getting_started" />
### Getting Started
To get started, we needed to do 3 things:
set up our environment for rails,
create our own forked rails repository,
and create a test app to test out the routes in the repository




<a name="setting_up_the_rails_environment" />
#### Setting up the Rails Environment

This is a guide that helped us set up the Rails environment on our own computer: http://edgeguides.rubyonrails.org/contributing_to_ruby_on_rails.html




##### Our Forked Repository
This is the repository we forked from and our current repository
Rails Repository: https://github.com/rails/rails.git

Our Forked Repository: https://github.com/rhintz42/url_for_optimization.git

Clone our forked repository and put it in a location you can remember.




##### The other Rails App Used
The reason why we needed this extra rails app was because we needed to simulate the routes and get real results in our benchmark tests.

The app we are using can be found at this repository: https://github.com/nbenavi/url_for_test_app.git

To use this app to test the rails repository, follow these instructions:

1. Clone this test app repository
2. Copy the location of the forked repository
3. In the test app repository you just cloned, goto the Gemfile
4. In the Gemfile, find this line

		gem 'rails', '3.2.3'

5. Comment that line out by adding a '#' to the beginning of that line

		#gem 'rails', '3.2.3'

6. After that line, add this line (Replacing the '/location/of/repository' with the rails repository you cloned)
		
		gem 'rails', :path => '/location/of/repository/'
		


<a name="files_used_for_this_project" />
### Files Used for This Project

<a name="formatter.rb" />
#### formatter.rb
Path to File: actionpack/lib/action\_dispatch/journey/formatter.rb
##### Methods of Interest

<a name="pattern.rb" />
#### pattern.rb
Path To File: actionpack/lib/action\_dispatch/journey/path/pattern.rb
##### Methods of Interest

<a name="route_set.rb" />
#### route\_set.rb
Path To File: actionpack/lib/action\_dispatch/routing/route\_set.rb
##### Methods of Interest

<a name="routes.rb" />
#### routes.rb
Path to File: actionpack/lib/action\_dispatch/journey/routes.rb
##### Methods of Interest

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



<a name="debugging" />
Debugging
-------------------------

Presentation on general Rails Routing & Debugging Commands:
https://docs.google.com/a/stanford.edu/presentation/d/1veFgQ0gfrF6q3NvKCGR4bMBwwI1Jx-VjpXfJ0hRm1g8/edit#slide=id.p

https://gist.github.com/rhintz42/5044571

