class Person < ActiveResource::Base
  self.site = "http://37s.sunrise.i:3000"
  schema do
    attribute 'name', :string
    string 'eye_color', 'hair_color'
    integer 'age'
    float 'height', 'weight'
    attribute 'created_at', 'string'
  end
end
