version = ARGV.pop

%w( active_support active_model active_record active_resource action_pack action_mailer railties ).each do |framework|
  puts "Installing #{framework}..."
  `cd #{framework} && gem build #{framework}.gemspec && gem install #{framework}-#{version}.gem --no-ri --no-rdoc && rm #{framework}-#{version}.gem`
end

puts "Installing Rails..."
`gem build rails.gemspec`
`gem install rails-#{version}.gem --no-ri --no-rdoc `
`rm rails-#{version}.gem`
