$VERBOSE = nil

# Load Rails Rakefile extensions
%w(
  documentation
  framework
  log
  middleware
  misc
  routes
  statistics
  tmp
).each do |task|
  load "rails/tasks/#{task}.rake"
end
