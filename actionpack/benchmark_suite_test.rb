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

      def test_exception_is_thrown_without_host
        teardown
        assert_raise ArgumentError do
          W.new.url_for :controller => 'c', :action => 'a', :id => 'i'
        end
      end

      def test_anchor
        teardown
        assert_equal('/c/a#anchor',
                     W.new.url_for(:only_path => true, :controller => 'c', :action => 'a', :anchor => 'anchor')
                    )
      end

      def test_anchor_should_call_to_param
        teardown
        assert_equal('/c/a#anchor',
                     W.new.url_for(:only_path => true, :controller => 'c', :action => 'a', :anchor => Struct.new(:to_param).new('anchor'))
                    )
      end

      def test_anchor_should_escape_unsafe_pchar
        teardown
        assert_equal('/c/a#%23anchor',
                     W.new.url_for(:only_path => true, :controller => 'c', :action => 'a', :anchor => Struct.new(:to_param).new('#anchor'))
                    )
      end

      def test_anchor_should_not_escape_safe_pchar
        teardown
        assert_equal('/c/a#name=user&email=user@domain.com',
                     W.new.url_for(:only_path => true, :controller => 'c', :action => 'a', :anchor => Struct.new(:to_param).new('name=user&email=user@domain.com'))
                    )
      end

      def test_default_host
        teardown
        add_host!
        assert_equal('http://www.basecamphq.com/c/a/i',
                     W.new.url_for(:controller => 'c', :action => 'a', :id => 'i')
                    )
      end

      def test_host_may_be_overridden
        teardown
        add_host!
        assert_equal('http://37signals.basecamphq.com/c/a/i',
                     W.new.url_for(:host => '37signals.basecamphq.com', :controller => 'c', :action => 'a', :id => 'i')
                    )
      end

      def test_subdomain_may_be_changed
        teardown
        add_host!
        assert_equal('http://api.basecamphq.com/c/a/i',
                     W.new.url_for(:subdomain => 'api', :controller => 'c', :action => 'a', :id => 'i')
                    )
      end

      def test_subdomain_may_be_object
        teardown
        model = mock(:to_param => 'api')
        add_host!
        assert_equal('http://api.basecamphq.com/c/a/i',
                     W.new.url_for(:subdomain => model, :controller => 'c', :action => 'a', :id => 'i')
                    )
      end

      def test_subdomain_may_be_removed
        teardown
        add_host!
        assert_equal('http://basecamphq.com/c/a/i',
                     W.new.url_for(:subdomain => false, :controller => 'c', :action => 'a', :id => 'i')
                    )
      end

      def test_multiple_subdomains_may_be_removed
        teardown
        W.default_url_options[:host] = 'mobile.www.api.basecamphq.com'
        assert_equal('http://basecamphq.com/c/a/i',
                     W.new.url_for(:subdomain => false, :controller => 'c', :action => 'a', :id => 'i')
                    )
      end

      def test_subdomain_may_be_accepted_with_numeric_host
        teardown
        add_numeric_host!
        assert_equal('http://127.0.0.1/c/a/i',
                     W.new.url_for(:subdomain => 'api', :controller => 'c', :action => 'a', :id => 'i')
                    )
      end

      def test_domain_may_be_changed
        teardown
        add_host!
        assert_equal('http://www.37signals.com/c/a/i',
                     W.new.url_for(:domain => '37signals.com', :controller => 'c', :action => 'a', :id => 'i')
                    )
      end

      def test_tld_length_may_be_changed
        teardown
        add_host!
        assert_equal('http://mobile.www.basecamphq.com/c/a/i',
                     W.new.url_for(:subdomain => 'mobile', :tld_length => 2, :controller => 'c', :action => 'a', :id => 'i')
                    )
      end

      def test_port
        teardown
        add_host!
        assert_equal('http://www.basecamphq.com:3000/c/a/i',
                     W.new.url_for(:controller => 'c', :action => 'a', :id => 'i', :port => 3000)
                    )
      end

      def test_default_port
        teardown
        add_host!
        add_port!
        assert_equal('http://www.basecamphq.com:3000/c/a/i',
                     W.new.url_for(:controller => 'c', :action => 'a', :id => 'i')
                    )
      end

      def test_protocol
        teardown
        add_host!
        assert_equal('https://www.basecamphq.com/c/a/i',
                     W.new.url_for(:controller => 'c', :action => 'a', :id => 'i', :protocol => 'https')
                    )
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

      def test_without_protocol
        teardown
        add_host!
        assert_equal('//www.basecamphq.com/c/a/i',
                     W.new.url_for(:controller => 'c', :action => 'a', :id => 'i', :protocol => '//')
                    )
        assert_equal('//www.basecamphq.com/c/a/i',
                     W.new.url_for(:controller => 'c', :action => 'a', :id => 'i', :protocol => false)
                    )
      end

      def test_trailing_slash
        teardown
        add_host!
        options = {:controller => 'foo', :trailing_slash => true, :action => 'bar', :id => '33'}
        assert_equal('http://www.basecamphq.com/foo/bar/33/', W.new.url_for(options) )
      end

      def test_trailing_slash_with_protocol
        teardown
        add_host!
        options = { :trailing_slash => true,:protocol => 'https', :controller => 'foo', :action => 'bar', :id => '33'}
        assert_equal('https://www.basecamphq.com/foo/bar/33/', W.new.url_for(options) )
        assert_equal 'https://www.basecamphq.com/foo/bar/33/?query=string', W.new.url_for(options.merge({:query => 'string'}))
      end

      def test_trailing_slash_with_only_path
        teardown
        options = {:controller => 'foo', :trailing_slash => true}
        assert_equal '/foo/', W.new.url_for(options.merge({:only_path => true}))
        options.update({:action => 'bar', :id => '33'})
        assert_equal '/foo/bar/33/', W.new.url_for(options.merge({:only_path => true}))
        assert_equal '/foo/bar/33/?query=string', W.new.url_for(options.merge({:query => 'string',:only_path => true}))
      end

      def test_trailing_slash_with_anchor
        teardown
        options = {:trailing_slash => true, :controller => 'foo', :action => 'bar', :id => '33', :only_path => true, :anchor=> 'chapter7'}
        assert_equal '/foo/bar/33/#chapter7', W.new.url_for(options)
        assert_equal '/foo/bar/33/?query=string#chapter7', W.new.url_for(options.merge({:query => 'string'}))
      end

      def test_trailing_slash_with_params
        teardown
        url = W.new.url_for(:trailing_slash => true, :only_path => true, :controller => 'cont', :action => 'act', :p1 => 'cafe', :p2 => 'link')
        params = extract_params(url)
        assert_equal params[0], { :p1 => 'cafe' }.to_query
        assert_equal params[1], { :p2 => 'link' }.to_query
      end

      def test_relative_url_root_is_respected
        teardown
        # ROUTES TODO: Tests should not have to pass :relative_url_root directly. This
        # should probably come from routes.

        add_host!
        assert_equal('https://www.basecamphq.com/subdir/c/a/i',
                     W.new.url_for(:controller => 'c', :action => 'a', :id => 'i', :protocol => 'https', :script_name => '/subdir')
                    )
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

      def test_one_parameter
        teardown
        assert_equal('/c/a?param=val',
                     W.new.url_for(:only_path => true, :controller => 'c', :action => 'a', :param => 'val')
                    )
      end

      def test_two_parameters
        teardown
        url = W.new.url_for(:only_path => true, :controller => 'c', :action => 'a', :p1 => 'X1', :p2 => 'Y2')
        params = extract_params(url)
        assert_equal params[0], { :p1 => 'X1' }.to_query
        assert_equal params[1], { :p2 => 'Y2' }.to_query
      end

      def test_hash_parameter
        teardown
        url = W.new.url_for(:only_path => true, :controller => 'c', :action => 'a', :query => {:name => 'Bob', :category => 'prof'})
        params = extract_params(url)
        assert_equal params[0], { 'query[category]' => 'prof' }.to_query
        assert_equal params[1], { 'query[name]'     => 'Bob'  }.to_query
      end

      def test_array_parameter
        teardown
        url = W.new.url_for(:only_path => true, :controller => 'c', :action => 'a', :query => ['Bob', 'prof'])
        params = extract_params(url)
        assert_equal params[0], { 'query[]' => 'Bob'  }.to_query
        assert_equal params[1], { 'query[]' => 'prof' }.to_query
      end

      def test_hash_recursive_parameters
        teardown
        url = W.new.url_for(:only_path => true, :controller => 'c', :action => 'a', :query => {:person => {:name => 'Bob', :position => 'prof'}, :hobby => 'piercing'})
        params = extract_params(url)
        assert_equal params[0], { 'query[hobby]'            => 'piercing' }.to_query
        assert_equal params[1], { 'query[person][name]'     => 'Bob'      }.to_query
        assert_equal params[2], { 'query[person][position]' => 'prof'     }.to_query
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

      def test_path_generation_for_symbol_parameter_keys
        teardown
        assert_generates("/image", :controller=> :image)
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

      def test_with_stringified_keys
        teardown
        assert_equal("/c", W.new.url_for('controller' => 'c', 'only_path' => true))
        assert_equal("/c/a", W.new.url_for('controller' => 'c', 'action' => 'a', 'only_path' => true))
      end

      def test_with_hash_with_indifferent_access
        teardown
        W.default_url_options[:controller] = 'd'
        W.default_url_options[:only_path]  = false
        assert_equal("/c", W.new.url_for(ActiveSupport::HashWithIndifferentAccess.new('controller' => 'c', 'only_path' => true)))

        W.default_url_options[:action] = 'b'
        assert_equal("/c/a", W.new.url_for(ActiveSupport::HashWithIndifferentAccess.new('controller' => 'c', 'action' => 'a', 'only_path' => true)))
      end

      def test_url_params_with_nil_to_param_are_not_in_url
        teardown
        assert_equal("/c/a", W.new.url_for(:only_path => true, :controller => 'c', :action => 'a', :id => Struct.new(:to_param).new(nil)))
      end

      def test_false_url_params_are_included_in_query
        teardown
        assert_equal("/c/a?show=false", W.new.url_for(:only_path => true, :controller => 'c', :action => 'a', :show => false))
      end

      def test_benchmark
        Benchmark.ips do |x|
           x.report("test_anchor") { test_anchor }
           x.report("test_exception_is_thrown_without_host") { test_exception_is_thrown_without_host }
           x.report("test_anchor_should_call_to_param") { test_anchor_should_call_to_param }
           x.report("test_anchor_should_escape_unsafe_pchar") { test_anchor_should_escape_unsafe_pchar }
           x.report("test_anchor_should_not_escape_safe_pchar") { test_anchor_should_not_escape_safe_pchar }
           x.report("test_default_host") { test_default_host }
           x.report("test_host_may_be_overridden") { test_host_may_be_overridden }
           x.report("test_subdomain_may_be_changed") { test_subdomain_may_be_changed }
           x.report("test_subdomain_may_be_object") { test_subdomain_may_be_object }
           x.report("test_subdomain_may_be_removed") { test_subdomain_may_be_removed }
           x.report("test_multiple_subdomains_may_be_removed") { test_multiple_subdomains_may_be_removed }
           x.report("test_subdomain_may_be_accepted_with_numeric_host") { test_subdomain_may_be_accepted_with_numeric_host }
           x.report("test_domain_may_be_changed") { test_domain_may_be_changed }
           x.report("test_tld_length_may_be_changed") { test_tld_length_may_be_changed }
           x.report("test_port") { test_port }
           x.report("test_default_port") { test_default_port }
           x.report("test_protocol") { test_protocol }
           x.report("test_protocol_with_and_without_separators") { test_protocol_with_and_without_separators }
           x.report("test_without_protocol") { test_without_protocol }
           x.report("test_trailing_slash") { test_trailing_slash }
           x.report("test_trailing_slash_with_protocol") { test_trailing_slash_with_protocol }
           x.report("test_trailing_slash_with_only_path") { test_trailing_slash_with_only_path }
           x.report("test_trailing_slash_with_anchor") { test_trailing_slash_with_anchor }
           x.report("test_trailing_slash_with_params") { test_trailing_slash_with_params }
           x.report("test_relative_url_root_is_respected") { test_relative_url_root_is_respected }
           x.report("test_named_routes") { test_named_routes }
           x.report("test_relative_url_root_is_respected_for_named_routes") { test_relative_url_root_is_respected_for_named_routes }
           x.report("test_only_path") { test_only_path }
           x.report("test_one_parameter") { test_one_parameter }
           x.report("test_two_parameters") { test_two_parameters }
           x.report("test_hash_parameter") { test_hash_parameter }
           x.report("test_array_parameter") { test_array_parameter }
           x.report("test_hash_recursive_parameters") { test_hash_recursive_parameters }
           x.report("test_hash_recursive_and_array_parameters") { test_hash_recursive_and_array_parameters }
           x.report("test_path_generation_for_symbol_parameter_keys") { test_path_generation_for_symbol_parameter_keys }
           x.report("test_named_routes_with_nil_keys") { test_named_routes_with_nil_keys }
           x.report("test_multiple_includes_maintain_distinct_options") { test_multiple_includes_maintain_distinct_options }
           x.report("test_with_stringified_keys") { test_with_stringified_keys }
           x.report("test_with_hash_with_indifferent_access") { test_with_hash_with_indifferent_access }
           x.report("test_url_params_with_nil_to_param_are_not_in_url") { test_url_params_with_nil_to_param_are_not_in_url }
           x.report("test_false_url_params_are_included_in_query") { test_false_url_params_are_included_in_query }
         end
      end

      private
        def extract_params(url)
          url.split('?', 2).last.split('&').sort
        end
    end
  end
end
