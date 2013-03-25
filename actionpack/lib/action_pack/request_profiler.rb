require 'benchmark'

def test_output_profiler(uri = "/")
  Benchmark.bm(7) do |x|
    x.report("url_for:"){
      env = Rack::MockRequest.env_for(uri)
      status, header, body = Rails.application.call(env)
      body.each {|chunk|}
      body.close if body.respond_to?(:close)
    }
  end
end