require File.expand_path(File.join(File.dirname(__FILE__), 'validation_test_helper'))

class Computer < TestClassBase
  attr_accessor :monitor, :cpu, :hard_drive, :server
end

class TestErrors < ActiveModel::TestCase
  def setup
    @computer = Computer.new
    @server = Computer.new
    @computer.server = @server
    @errors = @computer.errors
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
  
  test "index accesors" do
    @errors.add "zero"
    @errors.add "one"
    @errors.add "two"
    @errors.add "three"
    @errors.on(:cpu).add "four"
    @errors.on(:cpu).add "five"
    assert_equal "zero",   @errors[0]
    assert_equal "three",  @errors[3]
    assert_equal "four",  @errors[4]
    assert_equal "four",  @errors.on(:cpu)[0]
    
    @errors[0] = "zzz"
    assert_equal "zzz",   @errors[0]
    
    # @errors[4] is part of errors.on(:cpu), so what actually happens
    # is the 'mixed in' errors get pushed forward to make room for the new error.
    # Not something you should actually do...
    @errors[4] = "hmm"
    assert_equal "hmm",  @errors[4]
    assert_equal "four",  @errors[5]
    assert_equal "four",  @errors.on(:cpu)[0]
    assert_nil @errors.on(:cpu).find{|e| e =="hmm"}
  end
  
  test "error clearing" do
    @errors.add "foo"
    @errors.on(:cpu).add "moo"
    @errors.clear
    assert_equal 0, @errors.size
    assert_equal 0, @errors.on(:cpu).size
  end
  
  test "error clearing with associates" do
    @computer.errors.on(:cpu).add "foo"
    @computer.errors.on(:server).add "moo"
    @server.errors.add "hi"
    @computer.errors.clear
    assert_equal 1, @computer.errors.size
    assert_equal 1, @computer.errors.on(:server).size
    assert_equal 1, @server.errors.size
    @server.errors.clear
    assert_equal 0, @computer.errors.size
    assert_equal 0, @computer.errors.on(:server).size
    assert_equal 0, @server.errors.size
  end
  
end