require "cases/helper"
require 'models/developer'
require 'models/project'
require 'models/company'
require 'models/topic'
require 'models/reply'
require 'models/computer'
require 'models/customer'
require 'models/order'
require 'models/post'
require 'models/author'
require 'models/tag'
require 'models/tagging'
require 'models/comment'
require 'models/sponsor'
require 'models/member'
require 'models/essay'
require 'models/subscriber'

class IdentityMapTest < ActiveRecord::TestCase
  fixtures :accounts, :companies, :developers, :projects, :topics,
           :developers_projects, :computers, :authors, :author_addresses,
           :posts, :tags, :taggings, :comments, :subscribers

  def setup
    ActiveRecord::Base.current_repository = :test
    ActiveRecord::Base.identity_map.clear
    #ActiveRecord::Base.repositories[:test] = Hash.new
  end

  def test_find_id
    assert_same(
      Client.find(3),
      Client.find(3)
    )
  end

  def test_find_pkey
    assert_same(
      Subscriber.find('swistak'),
      Subscriber.find('swistak')
    )
  end

  def test_find_by_id
    assert_same(
      Client.find_by_id(3),
      Client.find_by_id(3)
    )
  end

  def test_find_by_pkey
    assert_same(
      Subscriber.find_by_nick('swistak'),
      Subscriber.find_by_nick('swistak')
    )
  end
  
  def test_find_first_id
    assert_same(
      Client.find(:first, :conditions => {:id => 1}),
      Client.find(:first, :conditions => {:id => 1})
    )
  end

  def test_find_first_pkey
    assert_same(
      Subscriber.find(:first, :conditions => {:nick => 'swistak'}),
      Subscriber.find(:first, :conditions => {:nick => 'swistak'})
    )
  end
end
