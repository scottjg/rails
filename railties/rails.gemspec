Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = 'rails'
  s.version = '2.3.15'
  s.summary = "Customised Rails for REMS3." 
  s.description = <<-EOF
    Rails is a framework for building web-application using CGI, FCGI, mod_ruby, or WEBrick
    on top of either MySQL, PostgreSQL, SQLite, DB2, SQL Server, or Oracle with eRuby- or Builder-based templates.
  EOF
 
  s.add_dependency('rake', '>= 0.8.3')
  # s.add_dependency('active_support',    '= 2.3.9')
  # s.add_dependency('active_record',     '= 2.3.9')
  # s.add_dependency('action_pack',       '= 2.3.9')
  # s.add_dependency('action_mailer',     '= 2.3.9')
  # s.add_dependency('active_resource',   '= 2.3.9')
 
  s.rdoc_options << '--exclude' << '.'
  s.has_rdoc = false
 
  s.files = Dir['CHANGELOG', 'README', 'bin/**/*', 'builtin/**/*', 'guides/**/*', 'lib/**/{*,.[a-z]*}']
  s.require_path = 'lib'
  s.bindir = "bin"
  s.executables = ["rails"]
  s.default_executable = "rails"

  s.author = "David Heinemeier Hansson"
  s.email = "david@loudthinking.com"
  s.homepage = "http://www.rubyonrails.org"
  s.rubyforge_project = "rails"
end
