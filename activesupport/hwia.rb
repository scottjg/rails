require 'benchmark'

$:.unshift "#{File.dirname(__FILE__)}/lib"
require 'active_support/hash_with_indifferent_access'

begin
  require 'hwia'
rescue LoadError
  $stderr.puts 'Skipping hwia extension tests: http://github.com/methodmissing/hwia'
end

class HwiaBench
  def initialize
    @n = 100_000
    @hash = { :a  => 1, 'b' => 2, 1 => 1, [1] => 1 }
    @fixtures = {}
    @fixtures[:naude] = @hash.strhash if @hash.respond_to?(:strhash)
    @fixtures[:'nobu '] = ActiveSupport::Hwia::Nobu.new.update(@hash) if Hash.method_defined?(:customize)
    @fixtures[:rails] = ActiveSupport::Hwia::Ruby.new.update(@hash)
  end

  def run
    Benchmark.bmbm do |r|
      bench(r, '#[:abc]') { |h| h[:a];  h[:b];  h[:'1'] }
      bench(r, '#["ab"]') { |h| h['a']; h['b']; h['1'] }
      bench(r, '#[1234]') { |h| h[1] }
      bench(r, '#[[12]]') { |h| h[[1]] }
      bench(r, '#[:abc]=') { |h| h[:a] = 1; h[:b] = 1; h[:'1'] = 1 }
      bench(r, '#["ab"]=') { |h| h['a'] = 1; h['b'] = 1; h['1'] = 1 }
      bench(r, '#[1234]=') { |h| h[1] = 1 }
      bench(r, '#[[12]]=') { |h| h[[1]] = 1 }
      bench(r, '#key?(:abc)') { |h| h.key?(:a); h.key?(:b); h.key?(:'1') }
      bench(r, '#key?("ab")') { |h| h.key?('a'); h.key?('b'); h.key?('1') }
      bench(r, '#fetch(:abc)') { |h| h.fetch(:a); h.fetch(:b); h.fetch(:'1') }
      bench(r, '#fetch("ab")') { |h| h.fetch('a'); h.fetch('b'); h.fetch('1') }
      bench(r, '#values_at(:abc)') { |h| h.values_at(:a); h.values_at(:b); h.values_at(:'1') }
      bench(r, '#values_at("ab")') { |h| h.values_at('a'); h.values_at('b'); h.values_at('1') }
      bench(r, '#update') { |h| h.update(@hash) }
      bench(r, '#merge') { |h| h.merge(@hash) }
      bench(r, '#to_hash') { |h| h.to_hash }
      bench(r, '#keys') { |h| h.keys }
      bench(r, '#values') { |h| h.values}
      bench(r, '#dup') { |h| h.dup }
    end
  end

  def bench(results, name)
    @fixtures.each do |fixture_name, fixture|
      results.report("#{fixture_name} #{name}") { @n.times { yield fixture } }
    end
  end
end

HwiaBench.new.run
