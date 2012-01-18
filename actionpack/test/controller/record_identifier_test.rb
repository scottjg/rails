require 'abstract_unit'
require 'controller/fake_models'

class RecordIdentifierTest < ActiveSupport::TestCase
  include ActionController::RecordIdentifier

  def setup
    @klass  = Comment
    @record = @klass.new
    @singular = 'comment'
    @plural = 'comments'
    @uncountable = Sheep
  end

  def test_dom_id_with_new_record
    assert_equal "new_#{@singular}", dom_id(@record)
  end

  def test_dom_id_with_new_record_and_prefix
    assert_equal "custom_prefix_#{@singular}", dom_id(@record, :custom_prefix)
  end

  def test_dom_id_with_saved_record
    @record.save
    assert_equal "#{@singular}_1", dom_id(@record)
  end

  def test_dom_id_with_prefix
    @record.save
    assert_equal "edit_#{@singular}_1", dom_id(@record, :edit)
  end

  def test_dom_class
    assert_equal @singular, dom_class(@record)
  end

  def test_dom_class_with_prefix
    assert_equal "custom_prefix_#{@singular}", dom_class(@record, :custom_prefix)
  end
end

class RecordIdentifierWithDelimiterTest < ActiveSupport::TestCase
  include ActionController::RecordIdentifier

  def setup
    @record = Comment.new
    @record.save
    ActionController::RecordIdentifier.delimiter = '-'
  end

  def teardown
    ActionController::RecordIdentifier.delimiter = '-'
  end

  def test_dom_id
    assert_equal "foo-comment-1", dom_id(@record, 'foo')
  end

  def test_dom_class
    assert_equal "foo-comment", dom_class(@record, 'foo')
  end
end


