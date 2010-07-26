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

    def clear!
      clear_changes!
    end

    def archive!
      archive_changes!
    end

    def archive_and_clear!
      archive_and_clear_changes!
    end
  end

  setup do
    @model = DirtyModel.new
  end

  test "setting name will result in change" do
    assert !@model.changed?
    assert !@model.name_changed?
    @model.name = "Ringo"
    assert @model.changed?
    assert @model.name_changed?
  end

  test "list of changed attributes" do
    assert_equal [], @model.changed
    @model.name = "Paul"
    assert_equal ['name'], @model.changed
  end

  test "changes to attribute values" do
    assert !@model.changes['name']
    @model.name = "John"
    assert_equal [nil, "John"], @model.changes['name']
  end

  test "changes accessible through both strings and symbols" do
    @model.name = "David"
    assert_not_nil @model.changes[:name]
    assert_not_nil @model.changes['name']
  end

  test "attribute mutation" do
    @model.instance_variable_set("@name", "Yam")
    assert !@model.name_changed?
    @model.name.replace("Hadad")
    assert !@model.name_changed?
    @model.name_will_change!
    @model.name.replace("Baal")
    assert @model.name_changed?
  end

  test "resetting attribute" do
    @model.name = "Bob"
    assert @model.name_changed?
    @model.reset_name!
    assert_nil @model.name
    assert !@model.name_changed?
    assert !@model.changed?
  end

  test "clearing changes" do
    @model.name = "Bob"
    assert @model.changed?
    @model.clear!
    assert !@model.changed?
  end

  test "archiving changes" do
    @model.name = "Bob"
    @model.archive!
    assert_equal [nil, "Bob"], @model.previous_changes['name']
  end

  test "archiving and clearing" do
    @model.name = "Bob"
    @model.archive_and_clear!
    assert !@model.changed?
    assert_equal [nil, "Bob"], @model.previous_changes['name']
  end

end
