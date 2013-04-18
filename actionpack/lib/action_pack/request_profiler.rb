require 'benchmark'

def test_output_profiler(uri = "/")
  #first mock request to cache, then test out links
  #env = Rack::MockRequest.env_for(uri)
  #status, header, body = Rails.application.call(env)
  num_tests = 1000
  Benchmark.bm(7) do |x|
    x.report("url_for:"){
			for i in 1..num_tests
      	env = Rack::MockRequest.env_for(uri)
      	status, header, body = Rails.application.call(env)
      	body.each {|chunk|}
      	body.close if body.respond_to?(:close)
    	end
    }
  end
end