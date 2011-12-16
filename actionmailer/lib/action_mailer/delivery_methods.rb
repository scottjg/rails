require 'tmpdir'

module ActionMailer
  # This module handles everything related to mail delivery, from registering new
  # delivery methods to configuring the mail object to be sent.
  module DeliveryMethods
    extend ActiveSupport::Concern

    included do
      class_attribute :delivery_methods, :delivery_method

      # Do not make this inheritable, because we always want it to propagate
      cattr_accessor :raise_delivery_errors
      self.raise_delivery_errors = true

      cattr_accessor :perform_deliveries
      self.perform_deliveries = true

      cattr_accessor :connection_debug_logger
      self.connection_debug_logger = nil

      self.delivery_methods = {}.freeze
      self.delivery_method  = :smtp

      add_delivery_method :smtp, Mail::SMTP,
        :address              => "localhost",
        :port                 => 25,
        :domain               => 'localhost.localdomain',
        :user_name            => nil,
        :password             => nil,
        :authentication       => nil,
        :enable_starttls_auto => true,
        :enable_debug_logging => nil

      set_debug_logger Mail, :connection_debug_logger

      add_delivery_method :file, Mail::FileDelivery,
        :location => defined?(Rails.root) ? "#{Rails.root}/tmp/mails" : "#{Dir.tmpdir}/mails"

      add_delivery_method :sendmail, Mail::Sendmail,
        :location   => '/usr/sbin/sendmail',
        :arguments  => '-i -t'

      add_delivery_method :test, Mail::TestMailer
    end

    module ClassMethods
      # Provides a list of emails that have been delivered by Mail::TestMailer
      delegate :deliveries, :deliveries=, :to => Mail::TestMailer

      # Adds a new delivery method through the given class using the given symbol
      # as alias and the default options supplied:
      #
      # Example:
      #
      #   add_delivery_method :sendmail, Mail::Sendmail,
      #     :location   => '/usr/sbin/sendmail',
      #     :arguments  => '-i -t'
      #
      def add_delivery_method(symbol, klass, default_options={})
        class_attribute(:"#{symbol}_settings") unless respond_to?(:"#{symbol}_settings")
        send(:"#{symbol}_settings=", default_options)
        self.delivery_methods = delivery_methods.merge(symbol.to_sym => klass).freeze
      end

      # Adds a debug logger for the supplied delivery method. The parameters
      # passed will define which class and reciever is called to set the logger
      # on the receiving delivery method. Accepts the delivery method symbol,
      # the class to send the set method to, and the method name to send to
      # that class. It then passes ActionMailer::Base.connection_debug_logger
      # to that method.
      #
      # Example:
      #
      #   set_debug_logger :smtp, Mail, :connection_debug_logger
      #
      # Which will then call:
      #
      #   Mail.connection_debug_logger = connection_debug_logger
      #
      # The Mail class has a connection_debug_logger method defined and writes
      # to it appropriately if the :enable_debug_logging setting is true.
      def set_debug_logger(klass, receiver)
        if klass.respond_to?(:"#{receiver}=")
          klass.send(:"#{receiver}=", connection_debug_logger)
        else
          raise "#{klass} does not respond to '#{receiver}='!"
        end
      end

      def wrap_delivery_behavior(mail, method=nil) #:nodoc:
        method ||= self.delivery_method
        mail.delivery_handler = self

        case method
        when NilClass
          raise "Delivery method cannot be nil"
        when Symbol
          if klass = delivery_methods[method.to_sym]
            mail.delivery_method(klass, send(:"#{method}_settings"))
          else
            raise "Invalid delivery method #{method.inspect}"
          end
        else
          mail.delivery_method(method)
        end

        mail.perform_deliveries    = perform_deliveries
        mail.raise_delivery_errors = raise_delivery_errors
      end
    end

    def wrap_delivery_behavior!(*args) #:nodoc:
      self.class.wrap_delivery_behavior(message, *args)
    end
  end
end
