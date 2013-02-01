version = File.read(File.expand_path("../RAILS_VERSION", __FILE__)).strip
source 'http://rubygems.org'

gemspec :path => "./actionmailer"

gem "activesupport", version, :require => false
gem "rake",  ">= 0.8.7"
gem 'mocha', '>= 0.13.0', :require => false

platforms :mri_18 do
  gem "system_timer"
end

platforms :ruby do
  gem 'json'
  gem 'yajl-ruby'
  gem "nokogiri", ">= 1.4.4"
end

platforms :jruby do
  gem "ruby-debug", ">= 0.10.3"

  # This is needed by now to let tests work on JRuby
  # TODO: When the JRuby guys merge jruby-openssl in
  # jruby this will be removed
  gem "jruby-openssl"
end
