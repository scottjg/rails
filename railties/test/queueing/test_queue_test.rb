require 'abstract_unit'
require 'rails/queueing'

class TestQueueTest < ActiveSupport::TestCase
  class Job
    def initialize(&block)
      @block = block
    end

    def run
      @block.call if @block
    end
  end

  def setup
    @queue = Rails::Queueing::TestQueue.new
  end
  # 
  # def test_drain_raises
  #   @queue.push Job.new { raise }
  #   assert_raises(RuntimeError) { @queue.drain }
  # end
  
  def test_jobs
    @queue.push 1
    @queue.push 2
    assert_equal [1,2], @queue.jobs
  end

  def test_contents
    assert_equal [], @queue.jobs
    job = Job.new
    @queue.push job
    assert_equal job, @queue.pop
  end
  # 
  # def test_drain
  #   t = nil
  #   ran = false
  # 
  #   job = Job.new(1) do
  #     ran = true
  #     t = Thread.current
  #   end
  # 
  #   @queue.push job
  #   @queue.drain
  # 
  #   assert_equal [], @queue.contents
  #   assert ran, "The job runs synchronously when the queue is drained"
  #   assert_not_equal t, Thread.current
  # end
end
