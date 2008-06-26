require File.join(File.dirname(__FILE__), "helper")

class Computer < TestClassBase
  attr_accessor :monitor, :cpu, :hard_drive, :server
end

class TestErrors < ActiveSupport::TestCase
  def setup
    @errors = Computer.new
  end
  
  test "errors are empty to begin with" do
    assert @errors.empty?
    assert @errors.on(:monitor).empty?
    assert @errors.on(:cpu).empty?
    assert @errors.on(:hard_drive).empty?
    assert @errors.on(:base).empty?
  end
  
  test "adding an error to base implicitly" do
    @errors.add "Computer is on fire."
    assert_equal 1, @errors.size
  end
  
  test "adding an error to base explicitly" do
    @errors.on(:base).add "Computer is overheating."
    @errors.on_base.add "Computer is actually an angry polar bear."
    assert_equal 2, @errors.size
    assert_equal 2, @errors.on(:base).size
    assert_equal 2, @errors.on_base.size
  end
  
  test "adding an error to an attribute" do
    @errors.on(:hard_drive).add "Hard-drive is full of viruses."
    assert_equal 1, @errors.on(:hard_drive).size
    assert_equal 1, @errors.size
  end
  
  test "counts for adding several errors on both base and attributes" do
    @errors.add "Computer is experiencing existential angst."
    @errors.on(:base).add "Computer doesn't understand why."
    @errors.on(:hard_drive).add "Hard has ran off to the big city."
    @errors.on(:hard_drive).add "Hard has stolen your wallet ."
    @errors.on(:monitor).add "Monitor just doesn't care any more."
    
    assert_equal 5, @errors.size
    
    assert_equal 2, @errors.on(:base).size
    assert_equal 2, @errors.on_base.size
    
    assert_equal 2, @errors.on(:hard_drive).size
    assert_equal 1, @errors.on(:monitor).size
  end
end