require 'abstract_unit'
require 'action_controller/metal/strong_parameters'

class MultiParameterAttributesTest < ActiveSupport::TestCase
  test "multi-parameter DateTime attributes" do
    params = ActionController::Parameters.new({
      book: {
        "shipped_at(1i)"   => "2012",
        "shipped_at(2i)"   => "3",
        "shipped_at(3i)"   => "25",
        "shipped_at(4i)"   => "10",
        "shipped_at(5i)"   => "15",
        "shipped_at(type)" => "DateTime"
      }
    })

    assert_equal DateTime.new(2012, 3, 25, 10, 15),
                 params[:book][:shipped_at]
  end

  test "multi-parameter Date attributes" do
    params = ActionController::Parameters.new({
      book: {
        "published_at(1i)" => "1999",
        "published_at(2i)" => "2",
        "published_at(3i)" => "5",
        "published_at(type)" => "Date"
      }
    })

    assert_equal Date.new(1999, 2, 5),
                 params[:book][:published_at]
  end

  test "multi-parameter attributes for unregistered custom types" do
    params = ActionController::Parameters.new({
      book: {
        "price(1)"         => "R$",
        "price(2f)"        => "2.02",
        "price(type)"      => "Money"
      }
    })

    assert_nil params[:book][:price]
  end

  test "multi-parameter attributes for registered custom types" do
    ActionController::MultiParameterConverter.register_type('Money') do |c, p|
      {price: p, currency: c}
    end

    params = ActionController::Parameters.new({
      book: {
        "price(1)"         => "R$",
        "price(2f)"        => "2.02",
        "price(type)"      => "Money"
      }
    })

    assert_equal HashWithIndifferentAccess.new(price: 2.02, currency: 'R$'),
                 params[:book][:price]
  end

  test "multi-parameter attributes with invalid values" do
  end
end
