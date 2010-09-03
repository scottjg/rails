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
require 'action_dispatch_multi_static'

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

new_static_public = ActionDispatch::Static.new(app, "public")
new_static_blog   = ActionDispatch::Static.new(app, "blog")
new_static_admin  = ActionDispatch::Static.new(app, "admin")

n = 10000

puts "Get default file"
Benchmark.bm(20) do |x|
  x.report("new     /         ") { n.times { get(static, '/') } }
  x.report("new     /blog     ") { n.times { get(static, '/blog') } }
  x.report("new     /admin    ") { n.times { get(static, '/admin') } }

  x.report("new (1) /         ") { n.times { get(new_static_public, '/') } }
  x.report("new (1) /blog     ") { n.times { get(new_static_blog  , '/') } }
  x.report("new (1) /admin    ") { n.times { get(new_static_admin , '/') } }

  x.report("old public        ") { n.times { get(old_static_public, '/') } }
  x.report("old blog          ") { n.times { get(old_static_blog  , '/') } }
  x.report("old admin         ") { n.times { get(old_static_admin , '/') } }
end

puts "Get existing html file"
Benchmark.bm(30) do |x|
  x.report("new     /foo.html      ") { n.times { get(static, '/foo.html') } }
  x.report("new     /blog/bar.html ") { n.times { get(static, '/blog/bar.html') } }
  x.report("new     /admin/baz.html") { n.times { get(static, '/admin/baz.html') } }

  x.report("new (1) /foo.html      ") { n.times { get(new_static_public, '/foo.html') } }
  x.report("new (1) /bar.html ") { n.times { get(new_static_blog  , '/bar.html') } }
  x.report("new (1) /baz.html") { n.times { get(new_static_admin , '/baz.html') } }

  x.report("old foo.html           ") { n.times { get(old_static_public, '/foo.html') } }
  x.report("old bar.html           ") { n.times { get(old_static_blog  , '/bar.html') } }
  x.report("old baz.html           ") { n.times { get(old_static_admin , '/baz.html') } }
end

puts "404"
Benchmark.bm(35) do |x|
  x.report("new     /non-existing.html      ") { n.times { get(static, '/non-existing.html') } }
  x.report("new     /blog/non-existing.html ") { n.times { get(static, '/blog/non-existing.html') } }
  x.report("new     /admin/non-existing.html") { n.times { get(static, '/admin/non-existing.html') } }

  x.report("new (1) /non-existing.html      ") { n.times { get(new_static_public, '/non-existing.html') } }
  x.report("new (1) /non-existing.html ") { n.times { get(new_static_blog  , '/non-existing.html') } }
  x.report("new (1) /non-existing.html") { n.times { get(new_static_admin , '/non-existing.html') } }

  x.report("old non-existing.html           ") { n.times { get(old_static_public, '/non-existing.html') } }
  x.report("old non-existing.html           ") { n.times { get(old_static_blog  , '/non-existing.html') } }
  x.report("old non-existing.html           ") { n.times { get(old_static_admin , '/non-existing.html') } }
end


