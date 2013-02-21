require 'abstract_unit'
require 'perftools'
require 'benchmark/ips'

module AbstractController
  module Testing
    class UrlForTest < ActionController::TestCase
      class W
        include ActionDispatch::Routing::RouteSet.new.tap { |r| r.draw { get ':controller(/:action(/:id(.:format)))' } }.url_helpers
      end

      def teardown
        W.default_url_options.clear
      end

      def add_host!
        W.default_url_options[:host] = 'www.basecamphq.com'
      end

      def add_port!
        W.default_url_options[:port] = 3000
      end

      def add_numeric_host!
        W.default_url_options[:host] = '127.0.0.1'
      end

      def test_protocol_with_and_without_separators
        teardown
        add_host!
        assert_equal('https://www.basecamphq.com/c/a/i',
                     W.new.url_for(:controller => 'c', :action => 'a', :id => 'i', :protocol => 'https')
                    )
        assert_equal('https://www.basecamphq.com/c/a/i',
                     W.new.url_for(:controller => 'c', :action => 'a', :id => 'i', :protocol => 'https:')
                    )
        assert_equal('https://www.basecamphq.com/c/a/i',
                     W.new.url_for(:controller => 'c', :action => 'a', :id => 'i', :protocol => 'https://')
                    )
      end

      def test_trailing_slash_with_only_path
        teardown
        options = {:controller => 'foo', :trailing_slash => true}
        assert_equal '/foo/', W.new.url_for(options.merge({:only_path => true}))
        options.update({:action => 'bar', :id => '33'})
        assert_equal '/foo/bar/33/', W.new.url_for(options.merge({:only_path => true}))
        assert_equal '/foo/bar/33/?query=string', W.new.url_for(options.merge({:query => 'string',:only_path => true}))
      end

      def test_named_routes
        teardown
        with_routing do |set|
          set.draw do
            get 'this/is/verbose', :to => 'home#index', :as => :no_args
            get 'home/sweet/home/:user', :to => 'home#index', :as => :home
          end

          # We need to create a new class in order to install the new named route.
          kls = Class.new { include set.url_helpers }

          controller = kls.new
          assert controller.respond_to?(:home_url)
          assert_equal 'http://www.basecamphq.com/home/sweet/home/again',
            controller.send(:home_url, :host => 'www.basecamphq.com', :user => 'again')

          assert_equal("/home/sweet/home/alabama", controller.send(:home_path, :user => 'alabama', :host => 'unused'))
          assert_equal("http://www.basecamphq.com/home/sweet/home/alabama", controller.send(:home_url, :user => 'alabama', :host => 'www.basecamphq.com'))
          assert_equal("http://www.basecamphq.com/this/is/verbose", controller.send(:no_args_url, :host=>'www.basecamphq.com'))
        end
      end

      def test_relative_url_root_is_respected_for_named_routes
        teardown
        with_routing do |set|
          set.draw do
            get '/home/sweet/home/:user', :to => 'home#index', :as => :home
          end

          kls = Class.new { include set.url_helpers }
          controller = kls.new

          assert_equal 'http://www.basecamphq.com/subdir/home/sweet/home/again',
            controller.send(:home_url, :host => 'www.basecamphq.com', :user => 'again', :script_name => "/subdir")
        end
      end

      def test_only_path
        teardown
        with_routing do |set|
          set.draw do
            get 'home/sweet/home/:user', :to => 'home#index', :as => :home
            get ':controller/:action/:id'
          end

          # We need to create a new class in order to install the new named route.
          kls = Class.new { include set.url_helpers }
          controller = kls.new
          assert controller.respond_to?(:home_url)
          assert_equal '/brave/new/world',
            controller.send(:url_for, :controller => 'brave', :action => 'new', :id => 'world', :only_path => true)

          assert_equal("/home/sweet/home/alabama", controller.send(:home_url, :user => 'alabama', :host => 'unused', :only_path => true))
          assert_equal("/home/sweet/home/alabama", controller.send(:home_path, 'alabama'))
        end
      end

      def test_hash_recursive_and_array_parameters
        teardown
        url = W.new.url_for(:only_path => true, :controller => 'c', :action => 'a', :id => 101, :query => {:person => {:name => 'Bob', :position => ['prof', 'art director']}, :hobby => 'piercing'})
        assert_match(%r(^/c/a/101), url)
        params = extract_params(url)
        assert_equal params[0], { 'query[hobby]'              => 'piercing'     }.to_query
        assert_equal params[1], { 'query[person][name]'       => 'Bob'          }.to_query
        assert_equal params[2], { 'query[person][position][]' => 'art director' }.to_query
        assert_equal params[3], { 'query[person][position][]' => 'prof'         }.to_query
      end

      def test_named_routes_with_nil_keys
        teardown
        with_routing do |set|
          set.draw do
            get 'posts.:format', :to => 'posts#index', :as => :posts
            get '/', :to => 'posts#index', :as => :main
          end

          # We need to create a new class in order to install the new named route.
          kls = Class.new { include set.url_helpers }
          kls.default_url_options[:host] = 'www.basecamphq.com'

          controller = kls.new
          params = {:action => :index, :controller => :posts, :format => :xml}
          assert_equal("http://www.basecamphq.com/posts.xml", controller.send(:url_for, params))
          params[:format] = nil
          assert_equal("http://www.basecamphq.com/", controller.send(:url_for, params))
        end
      end

      def test_multiple_includes_maintain_distinct_options
        teardown
        first_class = Class.new { include ActionController::UrlFor }
        second_class = Class.new { include ActionController::UrlFor }

        first_host, second_host = 'firsthost.com', 'secondhost.com'

        first_class.default_url_options[:host] = first_host
        second_class.default_url_options[:host] = second_host

        assert_equal  first_host, first_class.default_url_options[:host]
        assert_equal second_host, second_class.default_url_options[:host]
      end

      def test_preftools
        require 'perftools'
        PerfTools::CpuProfiler.start("/tmp/preftools_profile") do
          50_000.times{ test_named_routes }
        end
        `pprof.rb --text /tmp/preftools_profile`
        `pprof.rb --pdf /tmp/preftools_profile > /tmp/preftools_profile.pdf`
        `pprof.rb --gif /tmp/preftools_profile > /tmp/preftools_profile.gif`
        `pprof.rb --callgrind /tmp/preftools_profile > /tmp/preftools_profile.grind`
        `qcachegrind /tmp/preftools_profile.grind`
        `pprof.rb --gif --focus=Integer /tmp/preftools_profile > /tmp/add_numbers_custom.gif`
        `pprof.rb --text --ignore=Gem /tmp/url_for_profile`
      end
      private
      def extract_params(url)
        url.split('?', 2).last.split('&').sort
      end
    end
  end
end
