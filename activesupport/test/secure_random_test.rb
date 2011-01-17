require 'abstract_unit'

class SecureRandomTest < Test::Unit::TestCase
  def test_random_bytes
    b1 = ActiveSupport::SecureRandom.random_bytes(64)
    b2 = ActiveSupport::SecureRandom.random_bytes(64)
    assert_not_equal b1, b2
  end

  def test_hex
    b1 = ActiveSupport::SecureRandom.hex(64)
    b2 = ActiveSupport::SecureRandom.hex(64)
    assert_not_equal b1, b2
  end

  def test_random_number
    assert ActiveSupport::SecureRandom.random_number(5000) < 5000

    flip_buckets = Hash.new{ 0 }
    100.times do
      candidate = ActiveSupport::SecureRandom.random_number(2)
      flip_buckets[candidate] += 1
    end
    assert_equal 100, flip_buckets[0] + flip_buckets[1]

    100.times do
      assert ActiveSupport::SecureRandom.random_number(5) < 5
    end
  end
end
