require "cases/helper"

class DirtyTest < ActiveModel::TestCase
  class DirtyModel
    include ActiveModel::Dirty
    define_attribute_methods [:name]

    def initialize
      @name = nil
    end

    def name
      @name
    end

    def name=(val)
      name_will_change!
      @name = val
    end
  end

  test "setting name will result in change" do
    model = DirtyModel.new
    assert !model.changed?
    assert !model.name_changed?
    model.name = "Ringo"
    assert model.changed?
    assert model.name_changed?
  end

  test "list of changed attributes" do
    model = DirtyModel.new
    assert_equal [], model.changed
    model.name = "Paul"
    assert_equal ['name'], model.changed
  end

  test "changes to attribute values" do
    model = DirtyModel.new
    assert !model.changes['name']
    model.name = "John"
    assert_equal [nil, "John"], model.changes['name']
  end

  test "changes accessible through both strings and symbols" do
    model = DirtyModel.new
    model.name = "David"
    assert_not_nil model.changes[:name]
    assert_not_nil model.changes['name']
  end

  test "attribute mutation" do
    model = DirtyModel.new
    model.instance_variable_set("@name", "Yam")
    assert !model.name_changed?
    model.name.replace("Hadad")
    assert !model.name_changed?
    model.name_will_change!
    model.name.replace("Baal")
    assert model.name_changed?
  end

  #test "resetting attribute" do
  #  model = DirtyModel.new
  #  model.name = "Bob"
  #  assert model.name_changed?
  #  model.reset_name!
  #  assert_nil model.name
  #  assert !model.changed?
  #end

end
