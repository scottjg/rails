module ActiveModel
  # Generic Active Model exception class.
  class ActiveModelError < StandardError
  end
  
  class RecordNotFound < ActiveModelError
  end

  class Base
    include Observing
    include Associations
    include Reflection    
    include Persistence
    include Validations
    include Callbacks
    include NamedScope
    # Determine whether to store the full constant name including namespace when using STI
    superclass_delegating_accessor :store_full_sti_class
    self.store_full_sti_class = false
    
    class << self
      # Returns the class type of the record using the current module as a prefix. So descendents of
      # MyApp::Business::Account would appear as MyApp::Business::AccountSubclass.
      def compute_type(type_name)
        modularized_name = type_name_with_module(type_name)
        silence_warnings do
          begin
            class_eval(modularized_name, __FILE__, __LINE__)
          rescue NameError
            class_eval(type_name, __FILE__, __LINE__)
          end
        end
      end
      
      # Nest the type name in the same module as this class.
      # Bar is "MyApp::Business::Bar" relative to MyApp::Business::Foo
      def type_name_with_module(type_name)
        if store_full_sti_class
          type_name
        else
          (/^::/ =~ type_name) ? type_name : "#{parent.name}::#{type_name}"
        end
      end
      # Scope parameters to method calls within the block.  Takes a hash of method_name => parameters hash.
      # method_name may be <tt>:find</tt> or <tt>:create</tt>. <tt>:find</tt> parameters may include the <tt>:conditions</tt>, <tt>:joins</tt>,
      # <tt>:include</tt>, <tt>:offset</tt>, <tt>:limit</tt>, and <tt>:readonly</tt> options. <tt>:create</tt> parameters are an attributes hash.
      #
      #   class Article < ActiveRecord::Base
      #     def self.create_with_scope
      #       with_scope(:find => { :conditions => "blog_id = 1" }, :create => { :blog_id => 1 }) do
      #         find(1) # => SELECT * from articles WHERE blog_id = 1 AND id = 1
      #         a = create(1)
      #         a.blog_id # => 1
      #       end
      #     end
      #   end
      #
      # In nested scopings, all previous parameters are overwritten by the innermost rule, with the exception of
      # <tt>:conditions</tt> and <tt>:include</tt> options in <tt>:find</tt>, which are merged.
      #
      #   class Article < ActiveRecord::Base
      #     def self.find_with_scope
      #       with_scope(:find => { :conditions => "blog_id = 1", :limit => 1 }, :create => { :blog_id => 1 }) do
      #         with_scope(:find => { :limit => 10 })
      #           find(:all) # => SELECT * from articles WHERE blog_id = 1 LIMIT 10
      #         end
      #         with_scope(:find => { :conditions => "author_id = 3" })
      #           find(:all) # => SELECT * from articles WHERE blog_id = 1 AND author_id = 3 LIMIT 1
      #         end
      #       end
      #     end
      #   end
      #
      # You can ignore any previous scopings by using the <tt>with_exclusive_scope</tt> method.
      #
      #   class Article < ActiveRecord::Base
      #     def self.find_with_exclusive_scope
      #       with_scope(:find => { :conditions => "blog_id = 1", :limit => 1 }) do
      #         with_exclusive_scope(:find => { :limit => 10 })
      #           find(:all) # => SELECT * from articles LIMIT 10
      #         end
      #       end
      #     end
      #   end
      def with_scope(method_scoping = {}, action = :merge, &block)
        method_scoping = method_scoping.method_scoping if method_scoping.respond_to?(:method_scoping)

        # Dup first and second level of hash (method and params).
        method_scoping = method_scoping.inject({}) do |hash, (method, params)|
          hash[method] = (params == true) ? params : params.dup
          hash
        end

        method_scoping.assert_valid_keys([ :find, :create ])

        if f = method_scoping[:find]
          f.assert_valid_keys(VALID_FIND_OPTIONS)
          set_readonly_option! f
        end

        # Merge scopings
        if action == :merge && current_scoped_methods
          method_scoping = current_scoped_methods.inject(method_scoping) do |hash, (method, params)|
            case hash[method]
              when Hash
                if method == :find
                  (hash[method].keys + params.keys).uniq.each do |key|
                    merge = hash[method][key] && params[key] # merge if both scopes have the same key
                    if key == :conditions && merge
                      hash[method][key] = merge_conditions(params[key], hash[method][key])
                    elsif key == :include && merge
                      hash[method][key] = merge_includes(hash[method][key], params[key]).uniq
                    elsif key == :joins && merge
                      hash[method][key] = merge_joins(params[key], hash[method][key])
                    else
                      hash[method][key] = hash[method][key] || params[key]
                    end
                  end
                else
                  hash[method] = params.merge(hash[method])
                end
              else
                hash[method] = params
            end
            hash
          end
        end

        self.scoped_methods << method_scoping

        begin
          yield
        ensure
          self.scoped_methods.pop
        end
      end
      
      def scoped_methods #:nodoc:
        scoped_methods = (Thread.current[:scoped_methods] ||= {})
        scoped_methods[self] ||= []
      end

      def current_scoped_methods #:nodoc:
        scoped_methods.last
      end

      
      
    end 
  end
end