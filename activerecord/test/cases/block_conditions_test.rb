require 'cases/helper'
require 'models/post'

class BlockConditionsTest < ActiveRecord::TestCase
  fixtures :posts

  test "equality" do
    expected = [posts(:welcome)]

    assert_equal expected, Post.where { id == 1 }
    assert_equal expected, Post.where { posts.id == 1 }
  end

  test "inequality" do
    expected = Post.order(:id).where('id != 1').to_a

    assert_equal expected, Post.order(:id).where { id != 1 }
    assert_equal expected, Post.order(:id).where { posts.id != 1 }
  end

  test "anding predicates" do
    assert_equal [], Post.where { (id == 1)       & (id == 2)       }
    assert_equal [], Post.where { (posts.id == 1) & (posts.id == 2) }
    assert_equal [], Post.where { (posts.id == 1) & (id == 2)       }

    expected = [posts(:thinking)]
    assert_equal expected, Post.where { (tags_count == 1) & (title =~ '%thinking%') }
    assert_equal expected, Post.where { (posts.tags_count == 1) & (posts.title =~ '%thinking%') }
  end

  test "oring predicates" do
    expected = [posts(:welcome), posts(:thinking)]

    assert_equal expected, Post.order(:id).where { (id == 1)       | (id == 2)       }
    assert_equal expected, Post.order(:id).where { (posts.id == 1) | (posts.id == 2) }
    assert_equal expected, Post.order(:id).where { (posts.id == 1) | (id == 2)       }
  end

  test "less than" do
    expected = [posts(:welcome), posts(:thinking)]

    assert_equal expected, Post.order(:id).where { id < 3 }
    assert_equal expected, Post.order(:id).where { posts.id < 3 }
  end

  test "greater than" do
    expected = Post.order(:id).where('id > 9').to_a

    assert_equal expected, Post.order(:id).where { id > 9 }
    assert_equal expected, Post.order(:id).where { posts.id > 9 }
  end

  test "less than or equal" do
    expected = [posts(:welcome), posts(:thinking)]

    assert_equal expected, Post.order(:id).where { id <= 2 }
    assert_equal expected, Post.order(:id).where { posts.id <= 2 }
  end

  test "greater than or equal" do
    expected = Post.order(:id).where('id >= 9').to_a

    assert_equal expected, Post.order(:id).where { id >= 9 }
    assert_equal expected, Post.order(:id).where { posts.id >= 9 }
  end

  test "matches" do
    expected = [posts(:misc_by_bob), posts(:misc_by_mary)]

    assert_equal expected, Post.order(:id).where { title =~ 'misc%' }
    assert_equal expected, Post.order(:id).where { posts.title =~ 'misc%' }
  end

  test "doesn't match" do
    expected = Post.order(:id).where("title NOT LIKE 'misc%'").to_a

    assert_equal expected, Post.order(:id).where { title !~ 'misc%' }
    assert_equal expected, Post.order(:id).where { posts.title !~ 'misc%' }
  end

  test "in" do
    expected = [posts(:welcome), posts(:thinking)]

    assert_equal expected, Post.order(:id).where { id =~ [1, 2] }
    assert_equal expected, Post.order(:id).where { posts.id =~ [1, 2] }
  end

  test "not in" do
    expected = Post.order(:id).where('id NOT IN (1, 2)').to_a

    assert_equal expected, Post.order(:id).where { id !~ [1, 2] }
    assert_equal expected, Post.order(:id).where { posts.id !~ [1, 2] }
  end
end
