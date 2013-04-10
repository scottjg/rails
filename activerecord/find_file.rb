errors = []
Dir["test/cases/**/*.rb"].each do |a|
  ENV['ARCONN'] = 'mysql'
  x = system("bundle exec ruby -Ilib:test #{a}")

  errors << a unless x
end

p errors
