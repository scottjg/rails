require 'rubygems'
require 'bundler'
Bundler.setup

require 'active_support'
require 'rack/file'
require 'benchmark'
require 'rack/test'
require 'action_dispatch/middleware/static'
require 'action_controller'
require 'action_dispatch_static_master'

app = lambda { |env| [200, {}, 'Hello'] }

def get(static, path)
  Rack::MockRequest.new(static).request("GET", path).body
end

roots = ActiveSupport::OrderedHash.new
roots['/'] = "public"
roots['/blog'] = "blog"
roots['/admin'] = "admin"

static = ActionDispatch::Static.new(app, roots)

old_static_public = ActionDispatch::OldStatic.new(app, 'public')
old_static_blog   = ActionDispatch::OldStatic.new(app, 'blog')
old_static_admin  = ActionDispatch::OldStatic.new(app, 'admin')

n = 10000

puts "Get default file"
Benchmark.bm(7) do |x|
  x.report("/         ") { n.times { get(static, '/') } }
  x.report("/blog     ") { n.times { get(static, '/blog') } }
  x.report("/admin    ") { n.times { get(static, '/admin') } }

  x.report("old public") { n.times { get(old_static_public, '/') } }
  x.report("old blog  ") { n.times { get(old_static_blog  , '/') } }
  x.report("old admin ") { n.times { get(old_static_admin , '/') } }
end

puts "Get existing html file"
Benchmark.bm(7) do |x|
  x.report("/foo.html      ") { n.times { get(static, '/foo.html') } }
  x.report("/blog/bar.html ") { n.times { get(static, '/blog/bar.html') } }
  x.report("/admin/baz.html") { n.times { get(static, '/admin/baz.html') } }

  x.report("old foo.html   ") { n.times { get(old_static_public, '/foo.html') } }
  x.report("old bar.html   ") { n.times { get(old_static_blog  , '/bar.html') } }
  x.report("old baz.html   ") { n.times { get(old_static_admin , '/baz.html') } }
end

puts "404"
Benchmark.bm(7) do |x|
  x.report("/non-existing.html      ") { n.times { get(static, '/non-existing.html') } }
  x.report("/blog/non-existing.html ") { n.times { get(static, '/blog/non-existing.html') } }
  x.report("/admin/non-existing.html") { n.times { get(static, '/admin/non-existing.html') } }

  x.report("old non-existing.html   ") { n.times { get(old_static_public, '/non-existing.html') } }
  x.report("old non-existing.html   ") { n.times { get(old_static_blog  , '/non-existing.html') } }
  x.report("old non-existing.html   ") { n.times { get(old_static_admin , '/non-existing.html') } }
end


