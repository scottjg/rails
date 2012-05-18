# Rails 2 (progress)

This fork aims to renew Rails 2 enough to help some application to get out of migration panic.
This does mean that we want you to migrate your app to Rails 3 and Ruby 1.9, and in order to do so we'll soften up the process a bit more.

## Features:

- **Bundler** integration (and deprecation for `config.gem`)
- **Rubygems** revamp (v1.7 already supported)
- **Upgraded requirements** (old rack, rake, etc.)
- **Sass/Coffee** to be ready for 3.1
- **RSpec2** (we're already working on a rails2/rspec2 rspec-rails fork)



## Development setup

### Setup RVM (optional)

```bash
echo 'rvm 1.8.7-p334@rails-2-3-stable' > .rvmrc
```

### OSX tips

```bash
brew install fcgi
```

### Gems

```bash
gem install geminstaller -v '>= 0.4.3'
gem install fcgi -v '= 0.8.7' -- --with-fcgi-dir=/usr/local/Cellar/fcgi/2.4.0
gem install i18n -v '= 0.4.1'
gem install memcache-client -v '= 1.5.0'
gem install mocha -v '= 0.9.8'
gem install mysql -v '= 2.8.1' -- --with-mysql-config=`which mysql_config`
gem install nokogiri -v '= 1.3.3'
gem install pg -v '= 0.8.0'
gem install rack -v '~> 1.1.0' # WAS: gem install rack -v '> 1.1.0'
gem install rake -v '= 0.8.1'
gem install sqlite-ruby -v '= 2.2.3' # failing...
gem install sqlite3-ruby -v '= 1.2.5'
gem install tzinfo -v '= 0.3.18'

# railties
gem install rdoc
```
