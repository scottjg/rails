module ActiveRecord
  module Batches # :nodoc:
    extend ActiveSupport::Concern

    # When processing large numbers of records, it's often a good idea to do
    # so in batches to prevent memory ballooning.
    module ClassMethods
      # Yields each record that was found by the find +options+. The find is
      # performed by find_in_batches with a batch size of 1000 (or as
      # specified by the <tt>:batch_size</tt> option).
      #
      # Example:
      #
      #   Person.find_each(:conditions => "age > 21") do |person|
      #     person.party_all_night!
      #   end
      #
      # Note: This method is only intended to use for batch processing of
      # large amounts of records that wouldn't fit in memory all at once. If
      # you just need to loop over less than 1000 records, it's probably
      # better just to use the regular find methods.
      def find_each(options = {})
        find_in_batches(options) do |records|
          records.each { |record| yield record }
        end

        self
      end

      # Yields each batch of records that was found by the find +options+ as
      # an array. The size of each batch is set by the <tt>:batch_size</tt>
      # option; the default is 1000.
      #
      # You can control the starting point for the batch processing by
      # supplying the <tt>:start</tt> option. This is especially useful if you
      # want multiple workers dealing with the same processing queue. You can
      # make worker 1 handle all the records between id 0 and 10,000 and
      # worker 2 handle from 10,000, etc (by setting the <tt>:start</tt>
      # and <tt>:limit</tt> options on those workers).
      #
      # It's not possible to set the order. That is automatically set to
      # ascending on the primary key ("id ASC") to make the batch ordering
      # work. This also mean that this method only works with integer-based
      # primary keys.
      #
      # Example:
      #
      #   Person.find_in_batches(:conditions => "age > 21") do |group|
      #     sleep(50) # Make sure it doesn't get too crowded in there!
      #     group.each { |person| person.party_all_night! }
      #   end
      def find_in_batches(options = {})
        raise "You can't specify an order, it's forced to be #{batch_order}" if options[:order]

        start_id = options.delete(:start) || 1
        batch_size = options.delete(:batch_size) || 1000
        limit = options.delete(:limit)
        count = 0

        last_id = find(:first, options.merge(:order => batch_order('DESC'))).try(:id)
        return unless last_id

        with_scope(:find => options.merge(:order => batch_order)) do
          records = nil
          loop do
            records = find(:all, :conditions => [ "#{table_name}.#{primary_key} >= ? AND #{table_name}.#{primary_key} < ?",
                                                  start_id, start_id + batch_size])
            count += records.size
            if records.any?
              if limit && count >= limit
                yield records[0..(records.size - (count - limit) - 1)]
                break
              else
                yield records
              end
            end
            break if records.last.try(:id) == last_id
            start_id = start_id + batch_size
          end
        end
      end
      
      
      private
        def batch_order(order = 'ASC')
          "#{table_name}.#{primary_key} #{order}"
        end
    end
  end
end
