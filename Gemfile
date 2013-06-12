source 'http://rubygems.org'

gem "rails", :path => File.dirname(__FILE__)

gem "rake",  "0.8.7"
gem "mocha", "0.9.8"
gem "rdoc",  "2.5.10"
gem "horo",  "1.0.2"
gem "linecache", "0.43"
gem "rack", "1.2.1"

# for perf tests
gem "faker", "0.3.1"
gem "rbench", "0.2.3"
gem "addressable", "2.2.2"

# AS
gem "memcache-client", "1.8.5"

# AM
gem "text-format", "1.0.0"

platforms :mri_18 do
  gem "system_timer", "1.0"
  gem "ruby-debug", "0.10.3"
  gem 'ruby-prof', "0.9.2"
end

platforms :mri_19 do
  # TODO: Remove the conditional when ruby-debug19 supports Ruby >= 1.9.3
  gem "ruby-debug19", "0.11.6" if RUBY_VERSION < "1.9.3"
end

platforms :ruby do
  gem 'json', "1.4.6"
  gem 'yajl-ruby', "0.7.8"
  gem "nokogiri", "1.4.3.1"

  # AR
  gem "sqlite3-ruby", "1.3.1", :require => 'sqlite3'

  group :db do
    gem "pg", "0.9.0"
    gem "mysql", "2.8.1"
    gem "mysql2", "0.2.6"
  end
end

platforms :jruby do
  gem "ruby-debug", "0.10.3"

  gem "activerecord-jdbcsqlite3-adapter"

  # This is needed by now to let tests work on JRuby
  # TODO: When the JRuby guys merge jruby-openssl in
  # jruby this will be removed
  gem "jruby-openssl"

  group :db do
    gem "activerecord-jdbcmysql-adapter"
    gem "activerecord-jdbcpostgresql-adapter"
  end
end

env :AREL do
  gem "arel", :path => ENV['AREL']
end

# gems that are necessary for ActiveRecord tests with Oracle database
if ENV['ORACLE_ENHANCED_PATH'] || ENV['ORACLE_ENHANCED']
  platforms :ruby do
    gem 'ruby-oci8', ">= 2.0.4"
  end
  if ENV['ORACLE_ENHANCED_PATH']
    gem 'activerecord-oracle_enhanced-adapter', :path => ENV['ORACLE_ENHANCED_PATH']
  else
    gem "activerecord-oracle_enhanced-adapter", :git => "git://github.com/rsim/oracle-enhanced.git"
  end
end
