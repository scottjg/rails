require "cases/helper"
require 'models/artist'

class AttributeViewClassMethodTest < ActiveRecord::TestCase
  def test_should_take_a_name_for_the_view_and_define_a_reader_and_writer_method_for_it
    %w{ date_of_birth date_of_birth= }.each { |method| assert Artist.instance_methods.include?(method) }
  end

  def test_should_not_take_any_options_for_the_view_other_than_class_and_class_name_and_decorating
    assert_raise(ArgumentError) do
      Artist.class_eval do
        view :foo, :some_other_option => true
      end
    end
  end
end

class AttributeViewInGeneralTest < ActiveRecord::TestCase
  def setup
    @artist = Artist.create(:day => 31, :month => 12, :year => 1999)
  end

  def test_should_also_work_with_an_anonymous_wrapper_class
    Artist.class_eval do
      view :date_of_birth, :decorating => [:day, :month, :year], :as => (Class.new(AttributeViews::CompositeDate) do
        # Reversed implementation of the super class.
        def to_s
          "#{@year}-#{@month}-#{@day}"
        end
      end)
    end

    2.times { assert_equal "1999-12-31", @artist.date_of_birth.to_s }

    Artist.class_eval do
      view :date_of_birth, :as => AttributeViews::CompositeDate, :decorating => [:day, :month, :year]
    end
  end

  def test_should_reset_the_before_type_cast_values_on_reload
    @artist.date_of_birth = '01-01-1111'
    Artist.find(@artist.id).update_attribute(:day, 13)
    @artist.reload

    assert_equal "13-12-1999", @artist.date_of_birth_before_type_cast
  end
end

class AttributeViewForMultipleAttributesTest < ActiveRecord::TestCase
  def setup
    @artist = Artist.create(:day => 31, :month => 12, :year => 1999)
    @view = @artist.date_of_birth
  end

  def test_should_return_an_instance_of_the_view_class_specified_by_the_class_name_option
    assert_instance_of AttributeViews::CompositeDate, @artist.date_of_birth
  end

  def test_should_have_assigned_the_values_it_decorates_to_the_view_instance
    assert_equal 31,   @view.day
    assert_equal 12,   @view.month
    assert_equal 1999, @view.year
  end

  def test_should_return_the_value_before_type_cast_when_the_value_was_set_with_the_setter
    @artist.date_of_birth = '01-02-2000'
    assert_equal '01-02-2000', @artist.date_of_birth_before_type_cast
  end

  def test_should_return_the_value_before_type_cast_when_the_value_was_just_read_from_the_database
    date_of_birth_as_string = @artist.date_of_birth.to_s
    @artist.reload
    assert_equal date_of_birth_as_string, @artist.date_of_birth_before_type_cast
  end

  def test_should_parse_the_value_assigned_through_the_setter_method_and_assign_them_to_the_model_instance
    @artist.date_of_birth = '01-02-2000'
    assert_equal 1,    @artist.day
    assert_equal 2,    @artist.month
    assert_equal 2000, @artist.year
  end
end

class AttributeViewForOneAttributeTest < ActiveRecord::TestCase
  def setup
    @artist = Artist.create(:location => 'amsterdam')
  end

  def test_should_return_an_instance_of_the_view_class_specified_by_the_as_option
    assert_instance_of AttributeViews::GPSCoordinator, @artist.gps_location
  end

  def test_should_have_assigned_the_value_to_decorate_to_the_view_instance
    assert_equal 'amsterdam', @artist.gps_location.location
  end

  def test_should_return_the_value_before_type_cast_when_the_value_was_set_with_the_setter
    @artist.gps_location = 'rotterdam'
    assert_equal 'rotterdam', @artist.gps_location_before_type_cast
  end

  def test_should_return_the_value_before_type_cast_when_the_value_was_just_read_from_the_database
    gps_location_as_string = @artist.gps_location.to_s
    @artist.reload
    assert_equal gps_location_as_string, @artist.gps_location_before_type_cast
  end

  def test_should_parse_the_value_assigned_through_the_setter_method_and_assign_it_to_the_model_instance
    @artist.gps_location = 'amsterdam'
    assert_equal '+1, +1', @artist.location

    @artist.gps_location = 'rotterdam'
    assert_equal '-1, -1', @artist.location
  end
end

class AttributeViewForAnAlreadyExistingAttributeTest < ActiveRecord::TestCase
  def setup
    @artist = Artist.create(:start_year => 1999)
    @view = @artist.start_year
  end

  def test_should_return_an_instance_of_the_view_class_specified_by_the_as_option
    assert_instance_of AttributeViews::GPSCoordinator, @artist.gps_location
  end

  def test_should_have_assigned_the_value_to_decorate_to_the_view_instance
    assert_equal 1999, @view.start_year
  end

  def test_should_return_the_value_before_type_cast_when_the_value_was_set_with_the_setter
    @artist.start_year = '40 bc'
    assert_equal '40 bc', @artist.start_year_before_type_cast
  end

  def test_should_parse_and_write_the_value_assigned_through_the_setter_method_and_assign_it_to_the_model_instance
    @artist.start_year = '40 bc'
    assert_equal -41, @artist.read_attribute(:start_year)
  end
end

class AttributeViewValidatorTest < ActiveRecord::TestCase
  def teardown
    Artist.instance_variable_set(:@validate_callbacks, [])
    Artist.instance_variable_set(:@validate_on_update_callbacks, [])
  end

  def test_should_delegate_validation_to_the_view
    Artist.class_eval do
      validates_view :date_of_birth, :start_year
    end

    artist = Artist.create(:start_year => 1999)

    artist.start_year = 40
    assert artist.valid?

    artist.start_year = 'abcde'
    assert !artist.valid?
    assert_equal "is invalid", artist.errors.on(:start_year)
  end

  def test_should_take_an_options_hash_for_more_detailed_configuration
    Artist.class_eval do
      validates_view :start_year, :message => 'is not a valid date', :on => :update
    end

    artist = Artist.new(:start_year => 'abcde')
    assert artist.valid?

    artist.save!
    assert !artist.valid?
    assert_equal 'is not a valid date', artist.errors.on(:start_year)
  end

  def test_should_not_take_the_allow_nil_option
    assert_raise(ArgumentError) do
      Artist.class_eval do
        validates_view :start_year, :allow_nil => true
      end
    end
  end

  def test_should_not_take_the_allow_blank_option
    assert_raise(ArgumentError) do
      Artist.class_eval do
        validates_view :start_year, :allow_blank => true
      end
    end
  end
end