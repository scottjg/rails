require 'abstract_unit'

class PersistenceTest < Test::Unit::TestCase
  def setup
    setup_response # find me in abstract_unit
    @original_person_site = Person.site
  end

  def teardown
    Person.site = @original_person_site
  end

  def test_save
    rick = Person.new
    assert rick.save
    assert_equal '5', rick.id
  end

  def test_save!
    rick = Person.new
    assert rick.save!
    assert_equal '5', rick.id
  end

  def test_id_from_response
    p = Person.new
    resp = {'Location' => '/foo/bar/1'}
    assert_equal '1', p.__send__(:id_from_response, resp)

    resp['Location'] << '.xml'
    assert_equal '1', p.__send__(:id_from_response, resp)
  end

  def test_id_from_response_without_location
    p = Person.new
    resp = {}
    assert_nil p.__send__(:id_from_response, resp)
  end

  def test_load_attributes_from_response
    p = Person.new
    resp = ActiveResource::Response.new(nil)
    resp['Content-Length'] = "100"
    assert_nil p.__send__(:load_attributes_from_response, resp)
  end

  def test_create
    rick = Person.create(:name => 'Rick')
    assert rick.valid?
    assert !rick.new?
    assert_equal '5', rick.id

    # test additional attribute returned on create
    assert_equal 25, rick.age

    # Test that save exceptions get bubbled up too
    ActiveResource::HttpMock.respond_to do |mock|
      mock.post   "/people.xml", {}, nil, 409
    end
    assert_raise(ActiveResource::ResourceConflict) { Person.create(:name => 'Rick') }
  end

  def test_create_without_location
    ActiveResource::HttpMock.respond_to do |mock|
      mock.post   "/people.xml", {}, nil, 201
    end
    person = Person.create(:name => 'Rick')
    assert_nil person.id
  end

  def test_update_with_custom_prefix_with_specific_id
    addy = StreetAddress.find(1, :params => { :person_id => 1 })
    addy.street = "54321 Street"
    assert_kind_of StreetAddress, addy
    assert_equal "54321 Street", addy.street
    addy.save
  end

  def test_update_with_custom_prefix_without_specific_id
    addy = StreetAddress.find(:first, :params => { :person_id => 1 })
    addy.street = "54321 Lane"
    assert_kind_of StreetAddress, addy
    assert_equal "54321 Lane", addy.street
    addy.save
  end

  def test_update_conflict
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/people/2.xml", {}, @david
      mock.put "/people/2.xml", @default_request_headers, nil, 409
    end
    assert_raise(ActiveResource::ResourceConflict) { Person.find(2).save }
  end


  ######
  # update_attribute(s)(!)

  def test_update_attribute_as_symbol
    matz = Person.first
    matz.expects(:save).returns(true)

    assert_equal "Matz", matz.name
    assert matz.update_attribute(:name, "David")
    assert_equal "David", matz.name
  end

  def test_update_attribute_as_string
    matz = Person.first
    matz.expects(:save).returns(true)

    assert_equal "Matz", matz.name
    assert matz.update_attribute('name', "David")
    assert_equal "David", matz.name
  end


  def test_update_attributes_as_symbols
    addy = StreetAddress.first(:params => {:person_id => 1})
    addy.expects(:save).returns(true)

    assert_equal "12345 Street", addy.street
    assert_equal "Australia", addy.country
    assert addy.update_attributes(:street => '54321 Street', :country => 'USA')
    assert_equal "54321 Street", addy.street
    assert_equal "USA", addy.country
  end

  def test_update_attributes_as_strings
    addy = StreetAddress.first(:params => {:person_id => 1})
    addy.expects(:save).returns(true)

    assert_equal "12345 Street", addy.street
    assert_equal "Australia", addy.country
    assert addy.update_attributes('street' => '54321 Street', 'country' => 'USA')
    assert_equal "54321 Street", addy.street
    assert_equal "USA", addy.country
  end


  #####
  # Mayhem and destruction

  def test_destroy
    assert Person.find(1).destroy
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/people/1.xml", {}, nil, 404
    end
    assert_raise(ActiveResource::ResourceNotFound) { Person.find(1).destroy }
  end

  def test_destroy_with_custom_prefix
    assert StreetAddress.find(1, :params => { :person_id => 1 }).destroy
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/people/1/addresses/1.xml", {}, nil, 404
    end
    assert_raise(ActiveResource::ResourceNotFound) { StreetAddress.find(1, :params => { :person_id => 1 }) }
  end

  def test_destroy_with_410_gone
    assert Person.find(1).destroy
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/people/1.xml", {}, nil, 410
    end
    assert_raise(ActiveResource::ResourceGone) { Person.find(1).destroy }
  end

  def test_delete
    assert Person.delete(1)
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/people/1.xml", {}, nil, 404
    end
    assert_raise(ActiveResource::ResourceNotFound) { Person.find(1) }
  end

  def test_delete_with_custom_prefix
    assert StreetAddress.delete(1, :person_id => 1)
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/people/1/addresses/1.xml", {}, nil, 404
    end
    assert_raise(ActiveResource::ResourceNotFound) { StreetAddress.find(1, :params => { :person_id => 1 }) }
  end

  def test_delete_with_410_gone
    assert Person.delete(1)
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/people/1.xml", {}, nil, 410
    end
    assert_raise(ActiveResource::ResourceGone) { Person.find(1) }
  end

end