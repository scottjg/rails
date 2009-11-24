# encoding: utf-8
require 'cases/helper'
require 'models/topic'

class EncodingUTF8Test < ActiveRecord::TestCase
  fixtures :topics

  if '1.9'.respond_to?(:encoding)

    def setup
      @first = Topic.find(1)
      @utf8_encoding = Encoding.find('utf-8')
    end

    def test_attribute_value_is_utf8
      assert_equal @utf8_encoding, @first.title.encoding
    end

  end

end
