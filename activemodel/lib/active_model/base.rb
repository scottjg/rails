module ActiveModel
  # Generic Active Model exception class.
  class ActiveModelError < StandardError
  end
  
  class RecordNotFound < ActiveModelError
  end
  
  # These are the methods which must be implemented by concrete extensions to ActiveModel
  module ExternalInterface
    def self.included(base)
      base.extend ClassMethods
    end
    module ClassMethods
      def find(*args)
        warn "Must implement find in extensions"
        []        
      end
      
      def columns
        warn "Must implement columns in extensions"
        []
      end
    end
  end

  class Base
    include Observing
    include Associations
    include Reflection    
    include Persistence
    include Validations
    include Callbacks
    include NamedScope
    include AttributeMethods
    include ExternalInterface
    include SchemaDefinitions
    
    # Determine whether to store the full constant name including namespace when using STI
    superclass_delegating_accessor :store_full_sti_class
    self.store_full_sti_class = false

    # Returns the value of the attribute identified by <tt>attr_name</tt> after it has been typecast (for example,
    # "2004-12-12" in a data column is cast to a date object, like Date.new(2004, 12, 12)).
    # (Alias for the protected read_attribute method).
    def [](attr_name)
      read_attribute(attr_name)
    end

    # Updates the attribute identified by <tt>attr_name</tt> with the specified +value+.
    # (Alias for the protected write_attribute method).
    def []=(attr_name, value)
      write_attribute(attr_name, value)
    end

    # New objects can be instantiated as either empty (pass no construction parameter) or pre-set with
    # attributes but not yet saved (pass a hash with key names matching the associated table column names).
    # In both instances, valid attribute keys are determined by the column names of the associated table --
    # hence you can't have attributes that aren't part of the table columns.
    def initialize(attributes = nil)
      @attributes = attributes_from_column_definition
      @attributes_cache = {}
      @new_record = true
      ensure_proper_type
      self.attributes = attributes unless attributes.nil?
      self.class.send(:scope, :create).each { |att,value| self.send("#{att}=", value) } if self.class.send(:scoped?, :create)
      result = yield self if block_given?
      callback(:after_initialize) if respond_to_without_attributes?(:after_initialize)
      result
    end

    # Sets the attribute used for single table inheritance to this class name if this is not the ActiveModel::Base descendent.
    # Considering the hierarchy Reply < Message < ActiveModel::Base, this makes it possible to do Reply.new without having to
    # set <tt>Reply[Reply.inheritance_column] = "Reply"</tt> yourself. No such attribute would be set for objects of the
    # Message class in that example.
    def ensure_proper_type
      unless self.class.descends_from_active_model?
        write_attribute(self.class.inheritance_column, self.class.sti_name)
      end
    end
    
    

    
    # Initializes the attributes array with keys matching the columns from the linked table and
    # the values matching the corresponding default value of that column, so
    # that a new instance, or one populated from a passed-in Hash, still has all the attributes
    # that instances loaded from the database would.
    def attributes_from_column_definition
      self.class.columns.inject({}) do |attributes, column|
        attributes[column.name] = column.default unless column.name == self.class.primary_key
        attributes
      end
    end

    # Returns the column object for the named attribute.
    def column_for_attribute(name)
      self.class.columns_hash[name.to_s]
    end

    # Returns true if the +comparison_object+ is the same object, or is of the same type and has the same id.
    def ==(comparison_object)
      comparison_object.equal?(self) ||
        (comparison_object.instance_of?(self.class) &&
          comparison_object.id == id &&
          !comparison_object.new_record?)
    end

    # Delegates to ==
    def eql?(comparison_object)
      self == (comparison_object)
    end

    # Delegates to id in order to allow two records of the same type and id to work with something like:
    #   [ Person.find(1), Person.find(2), Person.find(3) ] & [ Person.find(1), Person.find(4) ] # => [ Person.find(1) ]
    def hash
      id.hash
    end

    

    class << self
      def primary_key
        raise NotImplementedError
      end

      # Test whether the given method and optional key are scoped.
      def scoped?(method, key = nil) #:nodoc:
        if current_scoped_methods && (scope = current_scoped_methods[method])
          !key || scope.has_key?(key)
        end
      end

      # Defines the column name for use with single table inheritance
      # -- can be set in subclasses like so: self.inheritance_column = "type_id"
      def inheritance_column
        @inheritance_column ||= "type".freeze
      end

      # Returns whether this class is a base AM class.  If A is a base class and
      # B descends from A, then B.base_class will return B.
      def abstract_class?
        defined?(@abstract_class) && @abstract_class == true
      end

      # True if this isn't a concrete subclass needing a STI type condition.
      def descends_from_active_model?
        if superclass.abstract_class?
          superclass.descends_from_active_model?
        else
          superclass == Base || !columns_hash.include?(inheritance_column)
        end
      end
      
      # Returns a hash of column objects for the table associated with this class.
       def columns_hash
         @columns_hash ||= columns.inject({}) { |hash, column| hash[column.name] = column; hash }
       end

   
      
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
      #   class Article < ActiveModel::Base
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
      
      # Returns a hash of all the attributes that have been specified for serialization as keys and their class restriction as values.
      def serialized_attributes
        read_inheritable_attribute(:attr_serialized) or write_inheritable_attribute(:attr_serialized, {})
      end


      #
      
      
    end 
  end
end