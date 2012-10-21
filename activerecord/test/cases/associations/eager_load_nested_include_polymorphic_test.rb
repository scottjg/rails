require 'cases/helper'

class Vehicule < ActiveRecord::Base
  belongs_to :pilot, :polymorphic => true
end

class Astronaut < ActiveRecord::Base
  has_one :rank
  belongs_to :vehicule
end

class Rank < ActiveRecord::Base
  belongs_to :astronaut
end

class Animal < ActiveRecord::Base
  belongs_to :vehicule
end

class EagerLoadNestedIncludePolymorphic < ActiveRecord::TestCase
  def setup
    ActiveRecord::Base.connection.create_table :vehicules, :force => true do |t|
      t.string  :name
      t.integer :pilot_id
      t.string  :pilot_type
    end
    assert ActiveRecord::Base.connection.table_exists?(:vehicules)

    ActiveRecord::Base.connection.create_table :astronauts, :force => true do |t|
      t.string :name
    end
    assert ActiveRecord::Base.connection.table_exists?(:astronauts)

    ActiveRecord::Base.connection.create_table :animals, :force => true do |t|
      t.string :name
    end
    assert ActiveRecord::Base.connection.table_exists?(:animals)

    ActiveRecord::Base.connection.create_table :ranks, :force => true do |t|
      t.string :name
      t.integer :astronaut_id
    end
    assert ActiveRecord::Base.connection.table_exists?(:ranks)

    generate_test_objects
  end

  def generate_test_objects
    buzz = Astronaut.create(:name => 'Buzz Aldrin')
    Rank.create(:name => 'Colonel', :astronaut => buzz)

    laika = Animal.create(:name => 'Laika')

    Vehicule.create(:name => 'Lunar module', :pilot => buzz)
    Vehicule.create(:name => 'Sputnik 2', :pilot => laika)
  end

  def teardown
    ActiveRecord::Base.connection.drop_table :vehicules
    ActiveRecord::Base.connection.drop_table :astronauts
    ActiveRecord::Base.connection.drop_table :ranks
    ActiveRecord::Base.connection.drop_table :animals
  end

  def test_eager_load_nested_include_polymorphic_relation_with_missing_association
    assert_nothing_raised do
      # dogs don't have rank
      includes = {:pilot => :rank}
      Vehicule.all :include => includes
    end
  end
end
