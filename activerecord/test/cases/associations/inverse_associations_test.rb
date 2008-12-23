require "cases/helper"
require 'models/man'
require 'models/face'
require 'models/interest'
require 'models/zine'

class InverseAssociationTests < ActiveRecord::TestCase
  def test_should_allow_for_inverse_options_in_associations
    assert_nothing_raised(ArgumentError, 'ActiveRecord should allow the inverse options on has_many') do
      Class.new(ActiveRecord::Base).has_many(:wheels, :inverse => :car)
    end
    
    assert_nothing_raised(ArgumentError, 'ActiveRecord should allow the inverse options on has_one') do
      Class.new(ActiveRecord::Base).has_one(:engine, :inverse => :car)
    end
    
    assert_nothing_raised(ArgumentError, 'ActiveRecord should allow the inverse options on belongs_to') do
      Class.new(ActiveRecord::Base).belongs_to(:car, :inverse => :driver)
    end
  end
  
  def test_should_be_able_to_ask_a_reflection_for_its_inverse
    has_one_ref = Man.reflect_on_association(:face)
    assert has_one_ref.respond_to? :inverse
    assert_equal :man, has_one_ref.inverse

    has_many_ref = Man.reflect_on_association(:interests)
    assert has_many_ref.respond_to? :inverse
    assert_equal :man, has_many_ref.inverse

    belongs_to_ref = Face.reflect_on_association(:man)
    assert belongs_to_ref.respond_to? :inverse
    assert_equal :face, belongs_to_ref.inverse
  end
end

class InverseHasOneTests < ActiveRecord::TestCase
  fixtures :men, :faces
  
  def test_parent_instance_should_be_shared_with_child_on_find
    m = Man.find(:first)
    f = m.face
    assert_equal m.name, f.man.name, "Name of man should be the same before changes to parent instance"
    m.name = 'Bongo'
    assert_equal m.name, f.man.name, "Name of man should be the same after changes to parent instance"
    f.man.name = 'Mungo'
    assert_equal m.name, f.man.name, "Name of man should be the same after changes to child-owned instance"
  end
  
  def test_parent_instance_should_be_shared_with_newly_built_child
    m = Man.find(:first)
    f = m.build_face(:description => 'haunted')
    assert_not_nil f.man
    assert_equal m.name, f.man.name, "Name of man should be the same before changes to parent instance"
    m.name = 'Bongo'
    assert_equal m.name, f.man.name, "Name of man should be the same after changes to parent instance"
    f.man.name = 'Mungo'
    assert_equal m.name, f.man.name, "Name of man should be the same after changes to just-built-child-owned instance"
  end
  
  def test_parent_instance_should_be_shared_with_newly_created_child
    m = Man.find(:first)
    f = m.create_face(:description => 'haunted')
    assert_not_nil f.man
    assert_equal m.name, f.man.name, "Name of man should be the same before changes to parent instance"
    m.name = 'Bongo'
    assert_equal m.name, f.man.name, "Name of man should be the same after changes to parent instance"
    f.man.name = 'Mungo'
    assert_equal m.name, f.man.name, "Name of man should be the same after changes to newly-created-child-owned instance"
  end
  
end

class InverseHasManyTests < ActiveRecord::TestCase
  fixtures :men, :interests

  def test_parent_instance_should_be_shared_with_every_child_on_find
    m = Man.find(:first)
    is = m.interests
    is.each do |i|
      assert_equal m.name, i.man.name, "Name of man should be the same before changes to parent instance"
      m.name = 'Bongo'
      assert_equal m.name, i.man.name, "Name of man should be the same after changes to parent instance"
      i.man.name = 'Mungo'
      assert_equal m.name, i.man.name, "Name of man should be the same after changes to child-owned instance"
    end
  end
  
  def test_parent_instance_should_be_shared_with_newly_built_child
    m = Man.find(:first)
    i = m.interests.build(:topic => 'Industrial Revolution Re-enactment')
    assert_not_nil i.man
    assert_equal m.name, i.man.name, "Name of man should be the same before changes to parent instance"
    m.name = 'Bongo'
    assert_equal m.name, i.man.name, "Name of man should be the same after changes to parent instance"
    i.man.name = 'Mungo'
    assert_equal m.name, i.man.name, "Name of man should be the same after changes to just-built-child-owned instance"
  end
  
  def test_parent_instance_should_be_shared_with_newly_created_child
    m = Man.find(:first)
    i = m.interests.create(:topic => 'Industrial Revolution Re-enactment')
    assert_not_nil i.man
    assert_equal m.name, i.man.name, "Name of man should be the same before changes to parent instance"
    m.name = 'Bongo'
    assert_equal m.name, i.man.name, "Name of man should be the same after changes to parent instance"
    i.man.name = 'Mungo'
    assert_equal m.name, i.man.name, "Name of man should be the same after changes to newly-created-child-owned instance"
  end
  
  def test_parent_instance_should_be_shared_with_poked_in_child
    m = Man.find(:first)
    i = Interest.create(:topic => 'Industrial Revolution Re-enactment')
    m.interests << i
    assert_not_nil i.man
    assert_equal m.name, i.man.name, "Name of man should be the same before changes to parent instance"
    m.name = 'Bongo'
    assert_equal m.name, i.man.name, "Name of man should be the same after changes to parent instance"
    i.man.name = 'Mungo'
    assert_equal m.name, i.man.name, "Name of man should be the same after changes to newly-created-child-owned instance"
  end
end

class InverseBelongsToTests < ActiveRecord::TestCase
  fixtures :men, :faces, :interests

  def test_child_instance_should_be_shared_with_parent_on_find
    f = Face.find(:first)
    m = f.man
    assert_equal f.description, m.face.description, "Description of face should be the same before changes to child instance"
    f.description = 'gormless'
    assert_equal f.description, m.face.description, "Description of face should be the same after changes to child instance"
    m.face.description = 'pleasing'
    assert_equal f.description, m.face.description, "Description of face should be the same after changes to parent-owned instance"
  end
  
  def test_child_instance_should_be_shared_with_newly_built_parent
    f = Face.find(:first)
    m = f.build_man(:name => 'Charles')
    assert_not_nil m.face
    assert_equal f.description, m.face.description, "Description of face should be the same before changes to child instance"
    f.description = 'gormless'
    assert_equal f.description, m.face.description, "Description of face should be the same after changes to child instance"
    m.face.description = 'pleasing'
    assert_equal f.description, m.face.description, "Description of face should be the same after changes to just-built-parent-owned instance"
  end
  
  def test_child_instance_should_be_shared_with_newly_created_parent
    f = Face.find(:first)
    m = f.create_man(:name => 'Charles')
    assert_not_nil m.face
    assert_equal f.description, m.face.description, "Description of face should be the same before changes to child instance"
    f.description = 'gormless'
    assert_equal f.description, m.face.description, "Description of face should be the same after changes to child instance"
    m.face.description = 'pleasing'
    assert_equal f.description, m.face.description, "Description of face should be the same after changes to newly-created-parent-owned instance"
  end
  
  def test_should_not_try_to_set_inverse_instances_when_the_inverse_is_a_has_many
    i = Interest.find(:first)
    m = i.man
    assert_not_nil m.interests
    iz = m.interests.detect {|iz| iz.id == i.id}
    assert_not_nil iz
    assert_equal i.topic, iz.topic, "Interest topics should be the same before changes to child"
    i.topic = 'Eating cheese with a spoon'
    assert_not_equal i.topic, iz.topic, "Interest topics should not be the same after changes to child"
    iz.topic = 'Cow tipping'
    assert_not_equal i.topic, iz.topic, "Interest topics should not be the same after changes to parent-owned instance"
  end
end

# NOTE - these tests might not be meaningful, ripped as they were from the parental_control plugin
# which would guess the inverse rather than look for an explicit configuration option.
class InverseMultipleHasManyInversesForSameModel < ActiveRecord::TestCase
  fixtures :men, :interests, :zines
  
  def test_that_we_can_load_associations_that_have_the_same_reciprocal_name_from_different_models
    assert_nothing_raised(ActiveRecord::AssociationTypeMismatch) do
      i = Interest.find(:first)
      z = i.zine
      m = i.man
    end
  end
  
  def test_that_we_can_create_associations_that_have_the_same_reciprocal_name_from_different_models
    assert_nothing_raised(ActiveRecord::AssociationTypeMismatch) do
      i = Interest.find(:first)
      i.build_zine(:title => 'Get Some in Winter! 2008')
      i.build_man(:name => 'Gordon')
      i.save!
    end
  end
end
