require 'active_support/xml'
require 'active_support/time'
require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/hash/reverse_merge'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string/inflections'

class Hash
  # Returns a string containing an XML representation of its receiver:
  #
  #   {"foo" => 1, "bar" => 2}.to_xml
  #   # =>
  #   # <?xml version="1.0" encoding="UTF-8"?>
  #   # <hash>
  #   #   <foo type="integer">1</foo>
  #   #   <bar type="integer">2</bar>
  #   # </hash>
  #
  # To do so, the method loops over the pairs and builds nodes that depend on
  # the _values_. Given a pair +key+, +value+:
  #
  # * If +value+ is a hash there's a recursive call with +key+ as <tt>:root</tt>.
  #
  # * If +value+ is an array there's a recursive call with +key+ as <tt>:root</tt>,
  #   and +key+ singularized as <tt>:children</tt>.
  #
  # * If +value+ is a callable object it must expect one or two arguments. Depending
  #   on the arity, the callable is invoked with the +options+ hash as first argument
  #   with +key+ as <tt>:root</tt>, and +key+ singularized as second argument. The 
  #   callable can add nodes by using <tt>options[:builder]</tt>.
  #
  #     "foo".to_xml(lambda { |options, key| options[:builder].b(key) })
  #     # => "<b>foo</b>"
  #
  # * If +value+ responds to +to_xml+ the method is invoked with +key+ as <tt>:root</tt>.
  #     
  #     class Foo
  #       def to_xml(options)
  #         options[:builder].bar "fooing!"
  #       end
  #     end
  #          
  #     {:foo => Foo.new}.to_xml(:skip_instruct => true)
  #     # => "<hash><bar>fooing!</bar></hash>"
  #
  # * Otherwise, a node with +key+ as tag is created with a string representation of
  #   +value+ as text node. If +value+ is +nil+ an attribute "nil" set to "true" is added.
  #   Unless the option <tt>:skip_types</tt> exists and is true, an attribute "type" is
  #   added as well according to the following mapping:
  #
  #     XML_TYPE_NAMES = {
  #       "Symbol"     => "symbol",
  #       "Fixnum"     => "integer",
  #       "Bignum"     => "integer",
  #       "BigDecimal" => "decimal",
  #       "Float"      => "float",
  #       "TrueClass"  => "boolean",
  #       "FalseClass" => "boolean",
  #       "Date"       => "date",
  #       "DateTime"   => "datetime",
  #       "Time"       => "datetime"
  #     }
  #
  # By default the root node is "hash", but that's configurable via the <tt>:root</tt> option.
  #
  # The default XML builder is a fresh instance of <tt>Builder::XmlMarkup</tt>. You can
  # configure your own builder with the <tt>:builder</tt> option. The method also accepts
  # options like <tt>:dasherize</tt> and friends, they are forwarded to the builder.
  def to_xml(options = {})
    require 'active_support/builder' unless defined?(Builder)

    options = options.dup
    options[:indent]  ||= 2
    options[:root]    ||= "hash"
    options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])

    builder = options[:builder]
    builder.instruct! unless options.delete(:skip_instruct)

    root = ActiveSupport::Xml.rename_key(options[:root].to_s, options)

    builder.__send__(:method_missing, root) do
      each { |key, value| ActiveSupport::Xml.to_tag(key, value, options) }
      yield builder if block_given?
    end
  end

  class << self
    def from_xml(xml)
      ActiveSupport::Xml.decode(xml)
    end
  end
end
