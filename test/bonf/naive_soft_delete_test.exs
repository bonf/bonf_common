defmodule Bonf.NaiveSoftDeleteTest do
  use Bonf.DataCase, async: true

  alias Bonf.Post
  alias Bonf.Comment

  describe "not_trashed/1" do
    test "returns only non-deleted records" do
      post1 = TestRepo.insert!(%Post{title: "Active Post", deleted: false})
      _post2 = TestRepo.insert!(%Post{title: "Deleted Post", deleted: true})
      _post3 = TestRepo.insert!(%Post{title: "Another Deleted", deleted: true})

      results = Post.not_trashed() |> TestRepo.all()

      assert length(results) == 1
      assert hd(results).id == post1.id
      assert hd(results).title == "Active Post"
    end

    test "works with custom queryable" do
      TestRepo.insert!(%Post{title: "Post A", deleted: false})
      TestRepo.insert!(%Post{title: "Post B", deleted: true})

      import Ecto.Query

      query = from(p in Post, where: p.title == "Post B")
      results = Post.not_trashed(query) |> TestRepo.all()

      assert results == []
    end

    test "returns all records when all are not deleted" do
      TestRepo.insert!(%Post{title: "Post 1", deleted: false})
      TestRepo.insert!(%Post{title: "Post 2", deleted: false})
      TestRepo.insert!(%Post{title: "Post 3", deleted: false})

      results = Post.not_trashed() |> TestRepo.all()

      assert length(results) == 3
    end

    test "returns empty list when all records are deleted" do
      TestRepo.insert!(%Post{title: "Deleted 1", deleted: true})
      TestRepo.insert!(%Post{title: "Deleted 2", deleted: true})

      results = Post.not_trashed() |> TestRepo.all()

      assert results == []
    end
  end

  describe "only_trashed/1" do
    test "returns only deleted records" do
      _post1 = TestRepo.insert!(%Post{title: "Active Post", deleted: false})
      post2 = TestRepo.insert!(%Post{title: "Deleted Post", deleted: true})
      post3 = TestRepo.insert!(%Post{title: "Another Deleted", deleted: true})

      results = Post.only_trashed() |> TestRepo.all()

      assert length(results) == 2
      assert Enum.map(results, & &1.id) |> Enum.sort() == [post2.id, post3.id] |> Enum.sort()
    end

    test "works with custom queryable" do
      TestRepo.insert!(%Post{title: "Post A", deleted: false})
      TestRepo.insert!(%Post{title: "Post B", deleted: true})

      import Ecto.Query

      query = from(p in Post, where: p.title == "Post A")
      results = Post.only_trashed(query) |> TestRepo.all()

      assert results == []
    end

    test "returns empty list when all records are active" do
      TestRepo.insert!(%Post{title: "Post 1", deleted: false})
      TestRepo.insert!(%Post{title: "Post 2", deleted: false})

      results = Post.only_trashed() |> TestRepo.all()

      assert results == []
    end

    test "returns all records when all are deleted" do
      TestRepo.insert!(%Post{title: "Deleted 1", deleted: true})
      TestRepo.insert!(%Post{title: "Deleted 2", deleted: true})
      TestRepo.insert!(%Post{title: "Deleted 3", deleted: true})

      results = Post.only_trashed() |> TestRepo.all()

      assert length(results) == 3
    end
  end

  describe "recover/1" do
    test "recovers a deleted record" do
      post = TestRepo.insert!(%Post{title: "Deleted Post", deleted: true})

      assert post.deleted == true

      {:ok, recovered} = Post.recover(post)

      assert recovered.deleted == false
      assert recovered.id == post.id
      assert recovered.title == "Deleted Post"

      # Verify it's updated in the database
      db_post = TestRepo.get!(Post, post.id)
      assert db_post.deleted == false
    end

    test "can recover an already active record (idempotent)" do
      post = TestRepo.insert!(%Post{title: "Active Post", deleted: false})

      {:ok, recovered} = Post.recover(post)

      assert recovered.deleted == false
    end

    test "works with different schema (Comment)" do
      post = TestRepo.insert!(%Post{title: "Some Post", deleted: false})

      comment =
        TestRepo.insert!(%Comment{body: "Deleted comment", post_id: post.id, deleted: true})

      assert comment.deleted == true

      {:ok, recovered} = Comment.recover(comment)

      assert recovered.deleted == false
      assert recovered.body == "Deleted comment"
    end

    test "raises when record doesn't exist" do
      fake_post = %Post{id: 999_999, title: "Fake", deleted: true}

      assert_raise Ecto.NoResultsError, fn ->
        Post.recover(fake_post)
      end
    end
  end

  describe "integration tests" do
    test "filtering and recovering workflow" do
      # Create some posts
      post1 = TestRepo.insert!(%Post{title: "Keep this", deleted: false})
      post2 = TestRepo.insert!(%Post{title: "Trash this", deleted: true})
      post3 = TestRepo.insert!(%Post{title: "Trash too", deleted: true})

      # Query only active posts
      active = Post.not_trashed() |> TestRepo.all()
      assert length(active) == 1
      assert hd(active).id == post1.id

      # Query only trashed posts
      trashed = Post.only_trashed() |> TestRepo.all()
      assert length(trashed) == 2

      # Recover one
      {:ok, _} = Post.recover(post2)

      # Now we should have 2 active
      active = Post.not_trashed() |> TestRepo.all()
      assert length(active) == 2

      # And 1 trashed
      trashed = Post.only_trashed() |> TestRepo.all()
      assert length(trashed) == 1
      assert hd(trashed).id == post3.id
    end

    test "works with associations" do
      post = TestRepo.insert!(%Post{title: "Post with comments", deleted: false})

      comment1 =
        TestRepo.insert!(%Comment{body: "Active comment", post_id: post.id, deleted: false})

      comment2 =
        TestRepo.insert!(%Comment{body: "Deleted comment", post_id: post.id, deleted: true})

      # Get only active comments
      import Ecto.Query

      active_comments =
        from(c in Comment, where: c.post_id == ^post.id)
        |> Comment.not_trashed()
        |> TestRepo.all()

      assert length(active_comments) == 1
      assert hd(active_comments).id == comment1.id

      # Get only deleted comments
      deleted_comments =
        from(c in Comment, where: c.post_id == ^post.id)
        |> Comment.only_trashed()
        |> TestRepo.all()

      assert length(deleted_comments) == 1
      assert hd(deleted_comments).id == comment2.id
    end
  end
end
