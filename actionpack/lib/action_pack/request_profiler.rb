#require 'config/environment'

def test_output_profiler
	puts Rails.application.method(:call).source_location

	#This will use a realistic mock env and Rails.app
	env = Rack::MockRequest.env_for("/")
    puts "THIS IS THE ENV THING"
    puts env
    Rails.application.call(env)

    #This 
    app = -> env {[ 200, { 'Content-Type' => 'text/html' }, [ '<html><body><marquee>1999</marquee></body></html>' ]] }
   	env = {}
   	response = app.call(env)

   	puts response
end