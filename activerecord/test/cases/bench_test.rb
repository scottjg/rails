#require 'models/developer'
require 'models/contact'

require 'benchmark'
 class AttributeMethodsTest < ActiveRecord::TestCase
 
  10000.times {|i| Developer.create!(:name=>"name#{i}")}
  Benchmark.benchmark do 
    x.report(:chaching__) do
      Developer.all.each_with_index do |item, index| 
      d.name = "name#{index}"
      a.save
   end
  end
end
end