require "cases/helper"
require 'models/unique_item'

class UniquenessValidationTest < ActiveRecord::TestCase

  def test_validate_uniqueness_on_create
    valid_item = UniqueItem.create!(:uniq => 'abc')
    invalid_item = UniqueItem.create(:uniq => 'abc')
    assert_equal ["has already been taken"], invalid_item.errors[:uniq]
  end

  def test_validate_uniqueness_on_save
    item_1 = UniqueItem.create!(:uniq => 'abc')
    item_2 = UniqueItem.create!(:uniq => 'xyz')
    item_2.uniq = item_1.uniq
    item_2.save
    assert_equal ["has already been taken"], item_2.errors[:uniq]
  end

  def test_validate_uniqueness_on_update
    item_1 = UniqueItem.create!(:uniq => 'abc')
    item_2 = UniqueItem.create!(:uniq => 'xyz')
    item_2.update_attributes(:uniq => item_1.uniq)
    assert_equal ["has already been taken"], item_2.errors[:uniq]
  end

  def test_validate_uniqueness_multiple
    valid_item = UniqueItem.create!(:uniq_1 => 'a', :uniq_2 => 'b', :uniq_3 => 'c')
    invalid_item = UniqueItem.create(:uniq_1 => 'a', :uniq_2 => 'b', :uniq_3 => 'c')
    assert_equal ["has already been taken for uniq_2/uniq_3"], invalid_item.errors[:uniq_1]
  end

  def test_validate_uniqueness_generic
    ActiveRecord::Base.connection.expects(:index_for_record_not_unique).returns(nil)
    valid_item = UniqueItem.create!(:uniq_1 => 'a', :uniq_2 => 'b', :uniq_3 => 'c')
    invalid_item = UniqueItem.create(:uniq_1 => 'a', :uniq_2 => 'b', :uniq_3 => 'c')
    assert_equal ["Unique requirement not met"], invalid_item.errors[:base]
  end

end
