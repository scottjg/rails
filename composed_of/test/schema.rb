ActiveRecord::Schema.define do
  create_table :customers, :force => true do |t|
    t.string  :name
    t.integer :balance, :default => 0
    t.string  :address_street
    t.string  :address_city
    t.string  :address_country
    t.string  :gps_location
  end

  create_table :developers, :force => true do |t|
    t.string   :name
    t.integer  :salary, :default => 70000
    t.datetime :created_at
    t.datetime :updated_at
  end
end
