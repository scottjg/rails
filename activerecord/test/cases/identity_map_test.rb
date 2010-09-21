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
require 'models/category'
require 'models/author'
require 'models/tag'
require 'models/tagging'
require 'models/comment'
require 'models/sponsor'
require 'models/member'
require 'models/essay'
require 'models/subscriber'
require "models/pirate"
require "models/bird"
require "models/parrot"

class IdentityMapTest < ActiveRecord::TestCase
  fixtures :accounts, :companies, :developers, :projects, :topics,
    :developers_projects, :computers, :authors, :author_addresses,
    :posts, :tags, :taggings, :comments, :subscribers

  def test_find_id
    assert_same(Client.find(3), Client.find(3))
  end

  def test_find_id_without_identity_map
    ActiveRecord::IdentityMap.without do
      assert_not_same(Client.find(3), Client.find(3))
    end
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

  def test_creation
    t1 = Topic.create("title" => "t1")
    t2 = Topic.find(t1.id)
    assert_same(t1, t2)
  end

  def test_loading_new_instance_should_not_update_dirty_attributes
    swistak = Subscriber.find(:first, :conditions => {:nick => 'swistak'})
    swistak.name = "Swistak Sreberkowiec"
    assert_equal(["name"], swistak.changed)

    s = Subscriber.find('swistak')

    assert swistak.name_changed?
    assert_equal("Swistak Sreberkowiec", swistak.name)
  end

  def test_loading_new_instance_should_remove_dirt
    swistak = Subscriber.find(:first, :conditions => {:nick => 'swistak'})
    swistak.name = "Swistak Sreberkowiec"

    assert_equal({'name' => ["Marcin Raczkowski", "Swistak Sreberkowiec"]}, swistak.changes)
    assert_equal("Swistak Sreberkowiec", swistak.name)
  end

  def test_has_many_associations
    pirate = Pirate.create!(:catchphrase => "Don' botharrr talkin' like one, savvy?")
    pirate.birds.create!(:name => 'Posideons Killer')
    pirate.birds.create!(:name => 'Killer bandita Dionne')

    posideons, killer = pirate.birds

    pirate.reload

    pirate.birds_attributes = [{ :id => posideons.id, :name => 'Grace OMalley' }]
    assert_equal 'Grace OMalley', pirate.birds.send(:load_target).find { |r| r.id == posideons.id }.name
  end

# Currently AR is not allowing changing primary key (see Persistence#update)
# So we ignore it. If this changes, this test needs to be uncommented.
#  def test_updating_of_pkey
#    assert client = Client.find(3),
#    client.update_attribute(:id, 666)
#
#    assert Client.find(666)
#    assert_same(client, Client.find(666))
#
#    s = Subscriber.find_by_nick('swistak')
#    assert s.update_attribute(:nick, 'swistakTheJester')
#    assert_equal('swistakTheJester', s.nick)
#
#    assert stj = Subscriber.find_by_nick('swistakTheJester')
#    assert_same(s, stj)
#  end

  def test_changing_associations
    post1 = Post.create("title" => "One post", "body" => "Posting...")
    post2 = Post.create("title" => "Another post", "body" => "Posting... Again...")
    comment = Comment.new("body" => "comment")

    comment.post = post1
    assert comment.save

    assert_same(post1.comments.first, comment)

    comment.post = post2
    assert comment.save

    assert_same(post2.comments.first, comment)
    assert_equal(0, post1.comments.size)
  end

  def test_im_with_polymorphic_has_many_going_through_join_model_with_custom_select_and_joins
    tag = posts(:welcome).tags.first
    tag_with_joins_and_select = posts(:welcome).tags.add_joins_and_select.first
    assert_same(tag, tag_with_joins_and_select)
    assert_nothing_raised(NoMethodError, "Joins/select was not loaded") { tag.author_id }
  end

  def test_find_with_preloaded_associations
    assert_queries(2) do
      posts = Post.preload(:comments)
      assert posts.first.comments.first
    end

    # With IM we'll retrieve post object from previous query, it'll have comments
    # already preloaded from first call
    assert_queries(1) do
      posts = Post.preload(:comments).to_a
      assert posts.first.comments.first
    end

    assert_queries(2) do
      posts = Post.preload(:author)
      assert posts.first.author
    end

    # With IM we'll retrieve post object from previous query, it'll have comments
    # already preloaded from first call
    assert_queries(1) do
      posts = Post.preload(:author).to_a
      assert posts.first.author
    end

    assert_queries(1) do
      posts = Post.preload(:author, :comments).to_a
      assert posts.first.author
      assert posts.first.comments.first
    end
  end

  def test_find_with_included_associations
    assert_queries(2) do
      posts = Post.includes(:comments)
      assert posts.first.comments.first
    end

    assert_queries(1) do
      posts = Post.scoped.includes(:comments)
      assert posts.first.comments.first
    end

    assert_queries(2) do
      posts = Post.includes(:author)
      assert posts.first.author
    end

    assert_queries(1) do
      posts = Post.includes(:author, :comments).to_a
      assert posts.first.author
      assert posts.first.comments.first
    end
  end

  def test_eager_loading_with_conditions_on_joined_table_preloads
    posts = Post.find(:all, :select => 'distinct posts.*', :include => :author, :joins => [:comments], :conditions => "comments.body like 'Thank you%'", :order => 'posts.id')
    assert_equal [posts(:welcome)], posts
    assert_equal authors(:david), assert_no_queries { posts[0].author}
    assert_same posts.first.author.target, Author.first

    posts = Post.find(:all, :select => 'distinct posts.*', :include => :author, :joins => [:comments], :conditions => "comments.body like 'Thank you%'", :order => 'posts.id')
    assert_equal [posts(:welcome)], posts
    assert_equal authors(:david), assert_no_queries { posts[0].author}
    assert_same posts.first.author.target, Author.first

    posts = Post.find(:all, :include => :author, :joins => {:taggings => :tag}, :conditions => "tags.name = 'General'", :order => 'posts.id')
    assert_equal posts(:welcome, :thinking), posts
    assert_same posts.first.author.target, Author.first

    posts = Post.find(:all, :include => :author, :joins => {:taggings => {:tag => :taggings}}, :conditions => "taggings_tags.super_tag_id=2", :order => 'posts.id')
    assert_equal posts(:welcome, :thinking), posts
    assert_same posts.first.author.target, Author.first
  end

  def test_eager_loading_with_conditions_on_string_joined_table_preloads
    posts = assert_queries(2) do
      Post.find(:all, :select => 'distinct posts.*', :include => :author, :joins => "INNER JOIN comments on comments.post_id = posts.id", :conditions => "comments.body like 'Thank you%'", :order => 'posts.id')
    end
    assert_equal [posts(:welcome)], posts
    assert_equal authors(:david), assert_no_queries { posts[0].author}

    posts = assert_queries(1) do
      Post.find(:all, :select => 'distinct posts.*', :include => :author, :joins => ["INNER JOIN comments on comments.post_id = posts.id"], :conditions => "comments.body like 'Thank you%'", :order => 'posts.id')
    end
    assert_equal [posts(:welcome)], posts
    assert_equal authors(:david), assert_no_queries { posts[0].author}
  end

  def test_reload_object_if_save_failed
    developer = Developer.first
    developer.salary = 0

    assert !developer.save

    same_developer = Developer.first

    assert_not_same  developer, same_developer
    assert_not_equal 0, same_developer.salary
    assert_not_equal developer.salary, same_developer.salary
  end

  def test_reload_object_if_forced_save_failed
    developer = Developer.first
    developer.salary = 0

    assert_raise(ActiveRecord::RecordInvalid) { developer.save! }

    same_developer = Developer.first

    assert_not_same  developer, same_developer
    assert_not_equal 0, same_developer.salary
    assert_not_equal developer.salary, same_developer.salary
  end

  def test_reload_object_if_update_attributes_fails
    developer = Developer.first
    developer.salary = 0

    assert !developer.update_attributes(:salary => 0)

    same_developer = Developer.first

    assert_not_same  developer, same_developer
    assert_not_equal 0, same_developer.salary
    assert_not_equal developer.salary, same_developer.salary
  end

  def test_owner_object_is_associated_from_identity_map
    post = Post.find(1)
    comment = post.comments.first

    assert_no_queries do
      comment.post
    end
    assert_same post, comment.post
  end

  def test_associated_object_are_assigned_from_identity_map
    post = Post.find(1)

    post.comments.each do |comment|
      assert_same post, comment.post
      assert_equal post.object_id, comment.post.target.object_id
    end
  end

  def test_find_using_identity_map_respects_readonly_when_loading_associated_object_first
    author  = Author.first
    readonly_comment = author.readonly_comments.first

    comment = Comment.first
    assert !comment.readonly?

    assert readonly_comment.readonly?

    assert_raise(ActiveRecord::ReadOnlyRecord) {readonly_comment.save}
    assert comment.save
  end

  def test_find_using_identity_map_respects_readonly
    comment = Comment.first
    assert !comment.readonly?

    author  = Author.first
    readonly_comment = author.readonly_comments.first

    assert readonly_comment.readonly?

    assert_raise(ActiveRecord::ReadOnlyRecord) {readonly_comment.save}
    assert comment.save
  end
end
