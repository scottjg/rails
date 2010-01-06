require "cases/helper"
require "models/pirate"
require "models/ship"
require "models/bird"
require "models/parrot"
require "models/treasure"
require "models/man"
require "models/interest"

module NestedAttributesTestHelper
  def assert_raise_with_message(expected_exception, expected_message)
    begin
      error_raised = false
      yield
    rescue expected_exception => error
      error_raised = true
      actual_message = error.message
    end
    assert error_raised
    assert_equal expected_message, actual_message
  end

  def repair_nested_attributes(model, name)
    before = model.nested_attributes_options[name]
    model.nested_attributes_options[name] = nil
    yield
  ensure
    model.nested_attributes_options[name] = before
  end
end

class TestNestedAttributesInGeneral < ActiveRecord::TestCase
  include NestedAttributesTestHelper

  def test_base_should_have_an_empty_nested_attributes_options
    assert_equal Hash.new, ActiveRecord::Base.nested_attributes_options
  end

  def test_should_add_a_proc_to_nested_attributes_options
    assert_equal ActiveRecord::NestedAttributes::ClassMethods::REJECT_ALL_BLANK_PROC,
                 Pirate.nested_attributes_options[:birds_with_reject_all_blank][:reject_if]
    
    [:parrots, :birds].each do |name|
      assert_instance_of Proc, Pirate.nested_attributes_options[name][:reject_if]
    end
  end

  def test_should_not_build_a_new_record_if_reject_all_blank_returns_false
    pirate = Pirate.create!(:catchphrase => "Don' botharrr talkin' like one, savvy?")
    pirate.birds_with_reject_all_blank_attributes = [{:name => '', :color => ''}]
    pirate.save!

    assert pirate.birds_with_reject_all_blank.empty?
  end

  def test_should_build_a_new_record_if_reject_all_blank_does_not_return_false
    pirate = Pirate.create!(:catchphrase => "Don' botharrr talkin' like one, savvy?")
    pirate.birds_with_reject_all_blank_attributes = [{:name => 'Tweetie', :color => ''}]
    pirate.save!

    assert_equal 1, pirate.birds_with_reject_all_blank.count
  end

  def test_should_raise_an_ArgumentError_for_non_existing_associations
    assert_raise_with_message ArgumentError, "No association found for name `honesty'. Has it been defined yet?" do
      Pirate.accepts_nested_attributes_for :honesty
    end
  end

  def test_allow_destroy_is_deprecated_in_favor_of_allow
    repair_nested_attributes Pirate, :ship do
      assert_deprecated ":allow_destroy is deprecated for accepts_nested_attributes_for. Use `:allow => :destroy' instead." do
        Pirate.accepts_nested_attributes_for :ship, :allow_destroy => true
        options = Pirate.nested_attributes_options[:ship]
        assert_nil options[:allow_destroy]
        assert_equal :destroy, options[:allow]
      end
    end
  end

  def test_underscore_destroy_is_deprecated_in_favor_of_mark_for_removal
    pirate = Pirate.create!(:catchphrase => "Don' botharrr talkin' like one, savvy?")

    assert_deprecated '#_destroy is deprecated in nested attributes. Use #mark_for_removal instead.' do
      assert !pirate._destroy
      pirate.mark_for_removal!
      assert pirate._destroy
    end
  end

  def test_should_disable_allow_by_default
    repair_nested_attributes Pirate, :ship do
      Pirate.accepts_nested_attributes_for :ship

      pirate = Pirate.create!(:catchphrase => "Don' botharrr talkin' like one, savvy?")
      ship = pirate.create_ship(:name => 'Nights Dirty Lightning')

      assert_no_difference('Ship.count') do
        pirate.update_attributes(:ship_attributes => { :mark_for_removal => true })
      end
    end
  end

  def test_a_model_should_respond_to_mark_for_removal_and_return_if_it_is_marked_for_removal
    ship = Ship.create!(:name => 'Nights Dirty Lightning')
    assert !ship.mark_for_removal
    ship.mark_for_removal!
    assert ship.mark_for_removal
  end

  def test_reject_if_method_without_arguments
    repair_nested_attributes Pirate, :ship do
      Pirate.accepts_nested_attributes_for :ship, :reject_if => :new_record?

      pirate = Pirate.new(:catchphrase => "Stop wastin' me time")
      pirate.ship_attributes = { :name => 'Black Pearl' }
      assert_no_difference('Ship.count') { pirate.save! }
    end
  end

  def test_reject_if_method_with_arguments
    repair_nested_attributes Pirate, :ship do
      Pirate.accepts_nested_attributes_for :ship, :reject_if => :reject_empty_ships_on_create

      pirate = Pirate.new(:catchphrase => "Stop wastin' me time")
      pirate.ship_attributes = { :name => 'Red Pearl', :_reject_me_if_new => true }
      assert_no_difference('Ship.count') { pirate.save! }

      # pirate.reject_empty_ships_on_create returns false for saved records
      pirate.ship_attributes = { :name => 'Red Pearl', :_reject_me_if_new => true }
      assert_difference('Ship.count') { pirate.save! }
    end
  end

  def test_reject_if_with_indifferent_keys
    repair_nested_attributes Pirate, :ship do
      Pirate.accepts_nested_attributes_for :ship, :reject_if => proc {|attributes| attributes[:name].blank? }

      pirate = Pirate.new(:catchphrase => "Stop wastin' me time")
      pirate.ship_attributes = { :name => 'Hello Pearl' }
      assert_difference('Ship.count') { pirate.save! }
    end
  end

  def test_validate_presence_of_parent_works_with_inverse_of
    Man.accepts_nested_attributes_for(:interests)
    assert_equal :man, Man.reflect_on_association(:interests).options[:inverse_of]
    assert_equal :interests, Interest.reflect_on_association(:man).options[:inverse_of]

    repair_validations(Interest) do
      Interest.validates_presence_of(:man)
      assert_difference 'Man.count' do
        assert_difference 'Interest.count', 2 do
          man = Man.create!(:name => 'John',
                            :interests_attributes => [{:topic=>'Cars'}, {:topic=>'Sports'}])
          assert_equal 2, man.interests.count
        end
      end
    end
  end

  def test_validate_presence_of_parent_fails_without_inverse_of
    Man.accepts_nested_attributes_for(:interests)
    Man.reflect_on_association(:interests).options.delete(:inverse_of)
    Interest.reflect_on_association(:man).options.delete(:inverse_of)

    repair_validations(Interest) do
      Interest.validates_presence_of(:man)
      assert_no_difference ['Man.count', 'Interest.count'] do
        man = Man.create(:name => 'John',
                         :interests_attributes => [{:topic=>'Cars'}, {:topic=>'Sports'}])
        assert !man.errors[:'interests.man'].empty?
      end
    end
    # restore :inverse_of
    Man.reflect_on_association(:interests).options[:inverse_of] = :man
    Interest.reflect_on_association(:man).options[:inverse_of] = :interests
  end
end

class TestNestedAttributesOnAHasOneAssociation < ActiveRecord::TestCase
  include NestedAttributesTestHelper

  def setup
    @pirate = Pirate.create!(:catchphrase => "Don' botharrr talkin' like one, savvy?")
    @ship = @pirate.create_ship(:name => 'Nights Dirty Lightning')
  end

  def test_should_raise_argument_error_if_trying_to_build_polymorphic_belongs_to
    assert_raise_with_message ArgumentError, "Cannot build association looter. Are you trying to build a polymorphic one-to-one association?" do
      Treasure.new(:name => 'pearl', :looter_attributes => { :catchphrase => "Arrr" })
    end
  end

  def test_should_define_an_attribute_writer_method_for_the_association
    assert_respond_to @pirate, :ship_attributes=
  end

  def test_should_build_a_new_record_if_there_is_no_id
    @ship.destroy
    @pirate.reload.ship_attributes = { :name => 'Davy Jones Gold Dagger' }

    assert @pirate.ship.new_record?
    assert_equal 'Davy Jones Gold Dagger', @pirate.ship.name
  end

  def test_underscore_destroy_is_deprecated_in_favor_of_mark_for_removal
    assert_deprecated '#_destroy is deprecated in nested attributes. Use #mark_for_removal instead.' do
      @pirate.ship_attributes = { :id => @ship.id, :_destroy => '1' }
      assert @pirate.ship.marked_for_removal?
    end
  end

  def test_should_not_build_a_new_record_if_there_is_no_id_and_mark_for_removal_is_truthy
    @ship.destroy
    @pirate.reload.ship_attributes = { :name => 'Davy Jones Gold Dagger', :mark_for_removal => '1' }

    assert_nil @pirate.ship
  end

  def test_should_not_build_a_new_record_if_a_reject_if_proc_returns_false
    @ship.destroy
    @pirate.reload.ship_attributes = {}

    assert_nil @pirate.ship
  end

  def test_should_replace_an_existing_record_if_there_is_no_id_but_leave_the_existing_record_in_tact
    @pirate.reload.ship_attributes = { :name => 'Davy Jones Gold Dagger' }

    assert @pirate.ship.new_record?
    assert_equal 'Davy Jones Gold Dagger', @pirate.ship.name
    assert_equal 'Nights Dirty Lightning', @ship.name
    assert_difference("Ship.count", +1) { @pirate.save! }
  end

  [:destroy, :delete, :nullify].each do |type|
    test "replaces an existing record if there is no ID and marks the existing for removal with `#{type}'" do
      repair_nested_attributes Pirate, :ship do
        Pirate.accepts_nested_attributes_for :ship, :missing => type
        @pirate.ship_attributes = { :name => 'Davy Jones Gold Dagger' }

        assert @pirate.ship.new_record?
        assert_equal 'Davy Jones Gold Dagger', @pirate.ship.name
        assert_equal 'Nights Dirty Lightning', @ship.name

        assert @ship.marked_for_removal?
        assert_equal type, @ship.mark_for_removal_type
      end
    end
  end

  def test_should_not_replace_an_existing_record_if_there_is_no_id_and_mark_for_removal_is_truthy
    @pirate.reload.ship_attributes = { :name => 'Davy Jones Gold Dagger', :mark_for_removal => '1' }

    assert_equal @ship, @pirate.ship
    assert_equal 'Nights Dirty Lightning', @pirate.ship.name
  end

  def test_should_modify_an_existing_record_if_there_is_a_matching_id
    @pirate.reload.ship_attributes = { :id => @ship.id, :name => 'Davy Jones Gold Dagger' }

    assert_equal @ship, @pirate.ship
    assert_equal 'Davy Jones Gold Dagger', @pirate.ship.name
  end

  def test_should_raise_RecordNotFound_if_an_id_is_given_but_doesnt_return_a_record
    assert_raise_with_message ActiveRecord::RecordNotFound, "Couldn't find Ship with ID=1234567890 for Pirate with ID=#{@pirate.id}" do
      @pirate.ship_attributes = { :id => 1234567890 }
    end
  end

  def test_should_take_a_hash_with_string_keys_and_update_the_associated_model
    @pirate.reload.ship_attributes = { 'id' => @ship.id, 'name' => 'Davy Jones Gold Dagger' }

    assert_equal @ship, @pirate.ship
    assert_equal 'Davy Jones Gold Dagger', @pirate.ship.name
  end

  def test_should_modify_an_existing_record_if_there_is_a_matching_composite_id
    @ship.stubs(:id).returns('ABC1X')
    @pirate.ship_attributes = { :id => @ship.id, :name => 'Davy Jones Gold Dagger' }

    assert_equal 'Davy Jones Gold Dagger', @pirate.ship.name
  end

  [:destroy, :delete, :nullify].each do |type|
    test "marks an existing record for removal with `#{type}', if there is a matching id and mark_for_removal is truthy" do
      @pirate.ship.destroy

      repair_nested_attributes Pirate, :ship do
        Pirate.accepts_nested_attributes_for :ship, :allow => type

        [1, '1', true, 'true'].each do |truth|
          @pirate.reload.create_ship(:name => 'Mister Pablo')
          @pirate.ship_attributes = { :id => @pirate.ship.id, :mark_for_removal => truth }

          assert @pirate.ship.marked_for_removal?
          assert_equal type, @pirate.ship.mark_for_removal_type
        end
      end
    end
  end

  test "does not mark an existing record for removal if mark_for_removal is not truthy" do
    [nil, '0', 0, 'false', false].each do |not_truth|
      @pirate.ship_attributes = { :id => @pirate.ship.id, :mark_for_removal => not_truth }
      assert !@pirate.ship.marked_for_removal?
    end
  end

  def test_should_not_remove_an_existing_record_if_allow_is_nil
    repair_nested_attributes Pirate, :ship do
      Pirate.accepts_nested_attributes_for :ship, :allow => nil

      assert_no_difference('Ship.count') do
        @pirate.update_attribute(:ship_attributes, { :id => @pirate.ship.id, :mark_for_removal => true })
      end
    end
  end

  def test_should_also_work_with_a_HashWithIndifferentAccess
    @pirate.ship_attributes = HashWithIndifferentAccess.new(:id => @ship.id, :name => 'Davy Jones Gold Dagger')

    assert !@pirate.ship.new_record?
    assert_equal 'Davy Jones Gold Dagger', @pirate.ship.name
  end

  def test_should_work_with_update_attributes_as_well
    @pirate.update_attributes({ :catchphrase => 'Arr', :ship_attributes => { :id => @ship.id, :name => 'Mister Pablo' } })
    @pirate.reload

    assert_equal 'Arr', @pirate.catchphrase
    assert_equal 'Mister Pablo', @pirate.ship.name
  end

  def test_should_not_remove_the_associated_model_until_the_parent_is_saved
    assert_no_difference('Ship.count') do
      @pirate.attributes = { :ship_attributes => { :id => @ship.id, :mark_for_removal => true } }
    end
    assert_difference('Ship.count', -1) do
      @pirate.save
    end
  end

  def test_should_automatically_enable_autosave_on_the_association
    assert Pirate.reflect_on_association(:ship).options[:autosave]
  end

  def test_should_accept_update_only_option
    @pirate.update_attribute(:update_only_ship_attributes, { :id => @pirate.ship.id, :name => 'Mayflower' })
  end

  def test_should_create_new_model_when_nothing_is_there_and_update_only_is_true
    @ship.delete
    assert_difference('Ship.count', 1) do
      @pirate.reload.update_attribute(:update_only_ship_attributes, { :name => 'Mayflower' })
    end
  end

  def test_should_update_existing_when_update_only_is_true_and_no_id_is_given
    @ship.delete
    @ship = @pirate.create_update_only_ship(:name => 'Nights Dirty Lightning')

    assert_no_difference('Ship.count') do
      @pirate.update_attributes(:update_only_ship_attributes => { :name => 'Mayflower' })
    end
    assert_equal 'Mayflower', @ship.reload.name
  end
end

class TestNestedAttributesOnABelongsToAssociation < ActiveRecord::TestCase
  include NestedAttributesTestHelper

  def setup
    @ship = Ship.new(:name => 'Nights Dirty Lightning')
    @pirate = @ship.build_pirate(:catchphrase => 'Aye')
    @ship.save!
  end

  def test_should_define_an_attribute_writer_method_for_the_association
    assert_respond_to @ship, :pirate_attributes=
  end

  def test_should_build_a_new_record_if_there_is_no_id
    @pirate.destroy
    @ship.reload.pirate_attributes = { :catchphrase => 'Arr' }

    assert @ship.pirate.new_record?
    assert_equal 'Arr', @ship.pirate.catchphrase
  end

  def test_underscore_destroy_is_deprecated_in_favor_of_mark_for_removal
    assert_deprecated '#_destroy is deprecated in nested attributes. Use #mark_for_removal instead.' do
      @ship.pirate_attributes = { :id => @pirate.id, :_destroy => '1' }
      assert @ship.pirate.marked_for_removal?
    end
  end

  def test_should_not_build_a_new_record_if_there_is_no_id_and_mark_for_removal_is_truthy
    @pirate.destroy
    @ship.reload.pirate_attributes = { :catchphrase => 'Arr', :mark_for_removal => '1' }

    assert_nil @ship.pirate
  end

  def test_should_not_build_a_new_record_if_a_reject_if_proc_returns_false
    @pirate.destroy
    @ship.reload.pirate_attributes = {}

    assert_nil @ship.pirate
  end

  def test_should_replace_an_existing_record_if_there_is_no_id_but_leave_the_existing_record_in_tact
    @ship.reload.pirate_attributes = { :catchphrase => 'Arr' }

    assert @ship.pirate.new_record?
    assert_equal 'Arr', @ship.pirate.catchphrase
    assert_equal 'Aye', @pirate.catchphrase
    assert_difference("Pirate.count", +1) { @ship.save! }
  end

  [:destroy, :delete, :nullify].each do |type|
    test "replaces an existing record if there is no ID and marks the existing for removal with `#{type}'" do
      repair_nested_attributes Ship, :pirate do
        Ship.accepts_nested_attributes_for :pirate, :missing => type
        @ship.pirate_attributes = { :catchphrase => 'Arr' }

        assert @ship.pirate.new_record?
        assert_equal 'Arr', @ship.pirate.catchphrase
        assert_equal 'Aye', @pirate.catchphrase

        assert @pirate.marked_for_removal?
        assert_equal type, @pirate.mark_for_removal_type
      end
    end
  end

  def test_should_not_replace_an_existing_record_if_there_is_no_id_and_mark_for_removal_is_truthy
    @ship.reload.pirate_attributes = { :catchphrase => 'Arr', :mark_for_removal => '1' }

    assert_equal @pirate, @ship.pirate
    assert_equal 'Aye', @ship.pirate.catchphrase
  end

  def test_should_modify_an_existing_record_if_there_is_a_matching_id
    @ship.reload.pirate_attributes = { :id => @pirate.id, :catchphrase => 'Arr' }

    assert_equal @pirate, @ship.pirate
    assert_equal 'Arr', @ship.pirate.catchphrase
  end

  def test_should_raise_RecordNotFound_if_an_id_is_given_but_doesnt_return_a_record
    assert_raise_with_message ActiveRecord::RecordNotFound, "Couldn't find Pirate with ID=1234567890 for Ship with ID=#{@ship.id}" do
      @ship.pirate_attributes = { :id => 1234567890 }
    end
  end

  def test_should_take_a_hash_with_string_keys_and_update_the_associated_model
    @ship.reload.pirate_attributes = { 'id' => @pirate.id, 'catchphrase' => 'Arr' }

    assert_equal @pirate, @ship.pirate
    assert_equal 'Arr', @ship.pirate.catchphrase
  end

  def test_should_modify_an_existing_record_if_there_is_a_matching_composite_id
    @pirate.stubs(:id).returns('ABC1X')
    @ship.pirate_attributes = { :id => @pirate.id, :catchphrase => 'Arr' }

    assert_equal 'Arr', @ship.pirate.catchphrase
  end

  [:destroy, :delete, :nullify].each do |type|
    test "marks an existing record for removal with `#{type}', if there is a matching id and mark_for_removal is truthy" do
      @ship.pirate.destroy

      repair_nested_attributes Ship, :pirate do
        Ship.accepts_nested_attributes_for :pirate, :allow => type

        [1, '1', true, 'true'].each do |truth|
          @ship.reload.create_pirate(:catchphrase => 'Arr')
          @ship.pirate_attributes = { :id => @ship.pirate.id, :mark_for_removal => truth }

          assert @ship.pirate.marked_for_removal?
          assert_equal type, @ship.pirate.mark_for_removal_type
        end
      end
    end
  end

  test "does not mark an existing record for removal if mark_for_removal is not truthy" do
    [nil, '0', 0, 'false', false].each do |not_truth|
      @ship.pirate_attributes = { :id => @ship.pirate.id, :mark_for_removal => not_truth }
      assert !@ship.pirate.marked_for_removal?
    end
  end

  def test_should_not_remove_an_existing_record_if_allow_is_nil
    repair_nested_attributes Ship, :pirate do
      Ship.accepts_nested_attributes_for :pirate, :allow => nil

      assert_no_difference('Pirate.count') do
        @ship.update_attribute(:pirate_attributes, { :id => @ship.pirate.id, :mark_for_removal => true })
      end
    end
  end

  def test_should_work_with_update_attributes_as_well
    @ship.update_attributes({ :name => 'Mister Pablo', :pirate_attributes => { :catchphrase => 'Arr' } })
    @ship.reload

    assert_equal 'Mister Pablo', @ship.name
    assert_equal 'Arr', @ship.pirate.catchphrase
  end

  def test_should_not_remove_the_associated_model_until_the_parent_is_saved
    assert_no_difference('Pirate.count') do
      @ship.attributes = { :pirate_attributes => { :id => @ship.pirate.id, :mark_for_removal => true } }
    end
    assert_difference('Pirate.count', -1) { @ship.save }
  end

  def test_should_automatically_enable_autosave_on_the_association
    assert Ship.reflect_on_association(:pirate).options[:autosave]
  end

  def test_should_create_new_model_when_nothing_is_there_and_update_only_is_true
    @pirate.delete
    assert_difference('Pirate.count', 1) do
      @ship.reload.update_attribute(:update_only_pirate_attributes, { :catchphrase => 'Arr' })
    end
  end

  def test_should_update_existing_when_update_only_is_true_and_no_id_is_given
    @pirate.delete
    @pirate = @ship.create_update_only_pirate(:catchphrase => 'Aye')

    assert_no_difference('Pirate.count') do
      @ship.update_attributes(:update_only_pirate_attributes => { :catchphrase => 'Arr' })
    end
    assert_equal 'Arr', @pirate.reload.catchphrase
  end
end

module NestedAttributesOnACollectionAssociationTests
  include NestedAttributesTestHelper

  def test_should_define_an_attribute_writer_method_for_the_association
    assert_respond_to @pirate, association_setter
  end

  def test_should_save_only_one_association_on_create
    pirate = Pirate.create!({
      :catchphrase => 'Arr',
      association_getter => { 'foo' => { :name => 'Grace OMalley' } }
    })

    assert_equal 1, pirate.reload.send(@association_name).count
  end

  def test_should_take_a_hash_with_string_keys_and_assign_the_attributes_to_the_associated_models
    @alternate_params[association_getter].stringify_keys!
    @pirate.update_attributes @alternate_params
    assert_equal ['Grace OMalley', 'Privateers Greed'], [@child_1.reload.name, @child_2.reload.name]
  end

  def test_should_take_an_array_and_assign_the_attributes_to_the_associated_models
    @pirate.send(association_setter, @alternate_params[association_getter].values)
    @pirate.save
    assert_equal ['Grace OMalley', 'Privateers Greed'], [@child_1.reload.name, @child_2.reload.name]
  end

  def test_should_also_work_with_a_HashWithIndifferentAccess
    @pirate.send(association_setter, HashWithIndifferentAccess.new('foo' => HashWithIndifferentAccess.new(:id => @child_1.id, :name => 'Grace OMalley')))
    @pirate.save
    assert_equal 'Grace OMalley', @child_1.reload.name
  end

  def test_should_take_a_hash_and_assign_the_attributes_to_the_associated_models
    @pirate.attributes = @alternate_params
    assert_equal 'Grace OMalley', @pirate.send(@association_name).first.name
    assert_equal 'Privateers Greed', @pirate.send(@association_name).last.name
  end

  def test_should_take_a_hash_with_composite_id_keys_and_assign_the_attributes_to_the_associated_models
    @child_1.stubs(:id).returns('ABC1X')
    @child_2.stubs(:id).returns('ABC2X')

    @pirate.attributes = {
      association_getter => [
        { :id => @child_1.id, :name => 'Grace OMalley' },
        { :id => @child_2.id, :name => 'Privateers Greed' }
      ]
    }

    assert_equal ['Grace OMalley', 'Privateers Greed'], [@child_1.name, @child_2.name]
  end

  def test_should_raise_RecordNotFound_if_an_id_is_given_but_doesnt_return_a_record
    assert_raise_with_message ActiveRecord::RecordNotFound, "Couldn't find #{@child_1.class.name} with ID=1234567890 for Pirate with ID=#{@pirate.id}" do
      @pirate.attributes = { association_getter => [{ :id => 1234567890 }] }
    end
  end

  def test_should_automatically_build_new_associated_models_for_each_entry_in_a_hash_where_the_id_is_missing
    @pirate.send(@association_name).destroy_all
    @pirate.reload.attributes = {
      association_getter => { 'foo' => { :name => 'Grace OMalley' }, 'bar' => { :name => 'Privateers Greed' }}
    }

    assert @pirate.send(@association_name).first.new_record?
    assert_equal 'Grace OMalley', @pirate.send(@association_name).first.name

    assert @pirate.send(@association_name).last.new_record?
    assert_equal 'Privateers Greed', @pirate.send(@association_name).last.name
  end

  def test_should_not_assign_mark_for_removal_key_to_a_record
    assert_nothing_raised ActiveRecord::UnknownAttributeError do
      @pirate.send(association_setter, { 'foo' => { 'mark_for_removal' => '0' }})
    end
  end

  def test_should_ignore_new_associated_records_with_truthy_mark_for_removal_attribute
    @pirate.send(@association_name).destroy_all
    @pirate.reload.attributes = {
      association_getter => {
        'foo' => { :name => 'Grace OMalley' },
        'bar' => { :name => 'Privateers Greed', 'mark_for_removal' => '1' }
      }
    }

    assert_equal 1, @pirate.send(@association_name).length
    assert_equal 'Grace OMalley', @pirate.send(@association_name).first.name
  end

  def test_should_ignore_new_associated_records_if_a_reject_if_proc_returns_false
    @alternate_params[association_getter]['baz'] = {}
    assert_no_difference("@pirate.send(@association_name).length") do
      @pirate.attributes = @alternate_params
    end
  end

  def test_should_sort_the_hash_by_the_keys_before_building_new_associated_models
    attributes = ActiveSupport::OrderedHash.new
    attributes['123726353'] = { :name => 'Grace OMalley' }
    attributes['2'] = { :name => 'Privateers Greed' } # 2 is lower then 123726353
    @pirate.send(association_setter, attributes)

    assert_equal ['Posideons Killer', 'Killer bandita Dionne', 'Privateers Greed', 'Grace OMalley'].to_set, @pirate.send(@association_name).map(&:name).to_set
  end

  def test_should_raise_an_argument_error_if_something_else_than_a_hash_is_passed
    assert_nothing_raised(ArgumentError) { @pirate.send(association_setter, {}) }
    assert_nothing_raised(ArgumentError) { @pirate.send(association_setter, ActiveSupport::OrderedHash.new) }

    assert_raise_with_message ArgumentError, 'Hash or Array expected, got String ("foo")' do
      @pirate.send(association_setter, "foo")
    end
  end

  def test_should_work_with_update_attributes_as_well
    @pirate.update_attributes(:catchphrase => 'Arr',
      association_getter => { 'foo' => { :id => @child_1.id, :name => 'Grace OMalley' }})

    assert_equal 'Grace OMalley', @child_1.reload.name
  end

  def test_should_update_existing_records_and_add_new_ones_that_have_no_id
    @alternate_params[association_getter]['baz'] = { :name => 'Buccaneers Servant' }
    assert_difference('@pirate.send(@association_name).count', +1) do
      @pirate.update_attributes @alternate_params
    end
    assert_equal ['Grace OMalley', 'Privateers Greed', 'Buccaneers Servant'].to_set, @pirate.reload.send(@association_name).map(&:name).to_set
  end

  [:destroy, :delete, :nullify].each do |type|
    define_method "test_marks_an_existing_record_for_removal_with_#{type}_if_there_is_a_matching_id_and_mark_for_removal_is_truthy" do
      repair_nested_attributes Pirate, @association_name do
        Pirate.accepts_nested_attributes_for @association_name, :allow => type

        [1, '1', true, 'true'].each do |truth|
          record = @pirate.reload.send(@association_name)[0]
          @pirate.send(association_setter,
            @alternate_params[association_getter].merge('baz' => { :id => record.id, :mark_for_removal => truth })
          )

          assert record.marked_for_removal?
          assert_equal type, record.mark_for_removal_type
        end
      end
    end

    define_method "test_marks_an_existing_record_for_removal_with_#{type}_if_the_record_is_missing_from_the_attributes_hash" do
      repair_nested_attributes Pirate, @association_name do
        Pirate.accepts_nested_attributes_for @association_name, :missing => type
        @pirate.send(association_setter, 'foo' => { :id => @child_1.id, :name => 'Changed' })

        assert @child_2.marked_for_removal?
        assert_equal type, @child_2.mark_for_removal_type
      end
    end
  end

  def test_should_not_remove_the_associated_model_with_a_non_truthy_mark_for_removal_argument
    [nil, '', '0', 0, 'false', false].each do |false_variable|
      @alternate_params[association_getter]['foo'][:mark_for_removal] = false_variable
      @pirate.attributes = @alternate_params
      assert !@child_1.marked_for_removal?
    end
  end

  def test_should_not_remove_the_associated_model_until_the_parent_is_saved
    assert_no_difference('@pirate.send(@association_name).count') do
      @pirate.send(association_setter, @alternate_params[association_getter].merge('baz' => { :id => @child_1.id, :mark_for_removal => true }))
    end
    assert_difference('@pirate.send(@association_name).count', -1) { @pirate.save }
  end

  def test_should_not_remove_missing_records_by_default
    assert_no_difference('@pirate.send(@association_name).count') do
      @pirate.update_attribute(association_getter, 'foo' => { :id => @child_1.id, :name => 'Changed' })
    end
  end

  def test_should_automatically_enable_autosave_on_the_association
    assert Pirate.reflect_on_association(@association_name).options[:autosave]
  end

  private

  def association_setter
    @association_setter ||= "#{@association_name}_attributes=".to_sym
  end

  def association_getter
    @association_getter ||= "#{@association_name}_attributes".to_sym
  end
end

class TestNestedAttributesOnAHasManyAssociation < ActiveRecord::TestCase
  def setup
    @association_type = :has_many
    @association_name = :birds

    @pirate = Pirate.create!(:catchphrase => "Don' botharrr talkin' like one, savvy?")
    @pirate.birds.create!(:name => 'Posideons Killer')
    @pirate.birds.create!(:name => 'Killer bandita Dionne')

    @child_1, @child_2 = @pirate.birds

    @alternate_params = {
      :birds_attributes => {
        'foo' => { :id => @child_1.id, :name => 'Grace OMalley' },
        'bar' => { :id => @child_2.id, :name => 'Privateers Greed' }
      }
    }
  end

  include NestedAttributesOnACollectionAssociationTests
end

class TestNestedAttributesOnAHasAndBelongsToManyAssociation < ActiveRecord::TestCase
  def setup
    @association_type = :has_and_belongs_to_many
    @association_name = :parrots

    @pirate = Pirate.create!(:catchphrase => "Don' botharrr talkin' like one, savvy?")
    @pirate.parrots.create!(:name => 'Posideons Killer')
    @pirate.parrots.create!(:name => 'Killer bandita Dionne')

    @child_1, @child_2 = @pirate.parrots

    @alternate_params = {
      :parrots_attributes => {
        'foo' => { :id => @child_1.id, :name => 'Grace OMalley' },
        'bar' => { :id => @child_2.id, :name => 'Privateers Greed' }
      }
    }
  end

  include NestedAttributesOnACollectionAssociationTests
end

class TestNestedAttributesLimit < ActiveRecord::TestCase
  include NestedAttributesTestHelper

  def with_setup
    @pirate = Pirate.create!(:catchphrase => "Don' botharrr talkin' like one, savvy?")

    repair_nested_attributes Pirate, :parrots do
      Pirate.accepts_nested_attributes_for :parrots, :limit => 2
      yield
    end
  end

  def test_limit_with_less_records
    with_setup do
      @pirate.attributes = { :parrots_attributes => { 'foo' => { :name => 'Big Big Love' } } }
      assert_difference('Parrot.count') { @pirate.save! }
    end
  end

  def test_limit_with_number_exact_records
    with_setup do
      @pirate.attributes = { :parrots_attributes => { 'foo' => { :name => 'Lovely Day' }, 'bar' => { :name => 'Blown Away' } } }
      assert_difference('Parrot.count', 2) { @pirate.save! }
    end
  end

  def test_limit_with_exceeding_records
    with_setup do
      assert_raises(ActiveRecord::NestedAttributes::TooManyRecords) do
        @pirate.attributes = { :parrots_attributes => { 'foo' => { :name => 'Lovely Day' },
                                                        'bar' => { :name => 'Blown Away' },
                                                        'car' => { :name => 'The Happening' }} }
      end
    end
  end
end
