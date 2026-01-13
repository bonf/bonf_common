defmodule Bonf.SoftDeleteTest do
  use Bonf.DataCase, async: true

  alias Bonf.Article
  alias Bonf.Tag

  describe "not_trashed/1" do
    test "returns only non-deleted records (deleted_at is nil)" do
      article1 = TestRepo.insert!(%Article{title: "Active Article", deleted_at: nil})

      _article2 =
        TestRepo.insert!(%Article{title: "Deleted Article", deleted_at: ~U[2024-01-15 10:00:00Z]})

      _article3 =
        TestRepo.insert!(%Article{title: "Another Deleted", deleted_at: ~U[2024-02-20 15:30:00Z]})

      results = Article.not_trashed(Article) |> TestRepo.all()

      assert length(results) == 1
      assert hd(results).id == article1.id
      assert hd(results).title == "Active Article"
      assert hd(results).deleted_at == nil
    end

    test "works without explicit queryable parameter (defaults to module)" do
      article1 = TestRepo.insert!(%Article{title: "Active Article", deleted_at: nil})

      _article2 =
        TestRepo.insert!(%Article{title: "Deleted Article", deleted_at: ~U[2024-01-15 10:00:00Z]})

      results = Article.not_trashed() |> TestRepo.all()

      assert length(results) == 1
      assert hd(results).id == article1.id
      assert hd(results).title == "Active Article"
    end

    test "works with custom queryable" do
      TestRepo.insert!(%Article{title: "Article A", deleted_at: nil})
      TestRepo.insert!(%Article{title: "Article B", deleted_at: ~U[2024-01-01 00:00:00Z]})

      import Ecto.Query

      query = from(a in Article, where: a.title == "Article B")
      results = Article.not_trashed(query) |> TestRepo.all()

      assert results == []
    end

    test "returns all records when all have nil deleted_at" do
      TestRepo.insert!(%Article{title: "Article 1", deleted_at: nil})
      TestRepo.insert!(%Article{title: "Article 2", deleted_at: nil})
      TestRepo.insert!(%Article{title: "Article 3", deleted_at: nil})

      results = Article.not_trashed(Article) |> TestRepo.all()

      assert length(results) == 3
    end

    test "returns empty list when all records are deleted" do
      TestRepo.insert!(%Article{title: "Deleted 1", deleted_at: ~U[2024-01-01 00:00:00Z]})
      TestRepo.insert!(%Article{title: "Deleted 2", deleted_at: ~U[2024-01-02 00:00:00Z]})

      results = Article.not_trashed(Article) |> TestRepo.all()

      assert results == []
    end

    test "treats records with deleted_at timestamps in the future as deleted" do
      future_time =
        DateTime.utc_now() |> DateTime.add(1000, :second) |> DateTime.truncate(:second)

      TestRepo.insert!(%Article{title: "Future Delete", deleted_at: future_time})
      TestRepo.insert!(%Article{title: "Active", deleted_at: nil})

      results = Article.not_trashed(Article) |> TestRepo.all()

      assert length(results) == 1
      assert hd(results).title == "Active"
    end
  end

  describe "only_trashed/1" do
    test "returns only deleted records (deleted_at is not nil)" do
      _article1 = TestRepo.insert!(%Article{title: "Active Article", deleted_at: nil})

      article2 =
        TestRepo.insert!(%Article{title: "Deleted Article", deleted_at: ~U[2024-01-15 10:00:00Z]})

      article3 =
        TestRepo.insert!(%Article{title: "Another Deleted", deleted_at: ~U[2024-02-20 15:30:00Z]})

      results = Article.only_trashed(Article) |> TestRepo.all()

      assert length(results) == 2

      assert Enum.map(results, & &1.id) |> Enum.sort() ==
               [article2.id, article3.id] |> Enum.sort()
    end

    test "works without explicit queryable parameter (defaults to module)" do
      _article1 = TestRepo.insert!(%Article{title: "Active Article", deleted_at: nil})

      article2 =
        TestRepo.insert!(%Article{title: "Deleted Article", deleted_at: ~U[2024-01-15 10:00:00Z]})

      article3 =
        TestRepo.insert!(%Article{title: "Another Deleted", deleted_at: ~U[2024-02-20 15:30:00Z]})

      results = Article.only_trashed() |> TestRepo.all()

      assert length(results) == 2

      assert Enum.map(results, & &1.id) |> Enum.sort() ==
               [article2.id, article3.id] |> Enum.sort()
    end

    test "works with custom queryable" do
      TestRepo.insert!(%Article{title: "Article A", deleted_at: nil})
      TestRepo.insert!(%Article{title: "Article B", deleted_at: ~U[2024-01-01 00:00:00Z]})

      import Ecto.Query

      query = from(a in Article, where: a.title == "Article A")
      results = Article.only_trashed(query) |> TestRepo.all()

      assert results == []
    end

    test "returns empty list when all records are active" do
      TestRepo.insert!(%Article{title: "Article 1", deleted_at: nil})
      TestRepo.insert!(%Article{title: "Article 2", deleted_at: nil})

      results = Article.only_trashed(Article) |> TestRepo.all()

      assert results == []
    end

    test "returns all records when all are deleted" do
      TestRepo.insert!(%Article{title: "Deleted 1", deleted_at: ~U[2024-01-01 00:00:00Z]})
      TestRepo.insert!(%Article{title: "Deleted 2", deleted_at: ~U[2024-02-01 00:00:00Z]})
      TestRepo.insert!(%Article{title: "Deleted 3", deleted_at: ~U[2024-03-01 00:00:00Z]})

      results = Article.only_trashed(Article) |> TestRepo.all()

      assert length(results) == 3
    end

    test "can order trashed records by deletion time" do
      article1 =
        TestRepo.insert!(%Article{title: "First Deleted", deleted_at: ~U[2024-01-01 00:00:00Z]})

      article2 =
        TestRepo.insert!(%Article{title: "Second Deleted", deleted_at: ~U[2024-02-01 00:00:00Z]})

      article3 =
        TestRepo.insert!(%Article{title: "Third Deleted", deleted_at: ~U[2024-03-01 00:00:00Z]})

      import Ecto.Query

      results =
        Article
        |> Article.only_trashed()
        |> order_by([a], a.deleted_at)
        |> TestRepo.all()

      assert Enum.map(results, & &1.id) == [article1.id, article2.id, article3.id]
    end
  end

  describe "recover/1" do
    test "recovers a deleted record by setting deleted_at to nil" do
      deleted_time = ~U[2024-01-15 10:00:00Z]
      article = TestRepo.insert!(%Article{title: "Deleted Article", deleted_at: deleted_time})

      assert article.deleted_at == deleted_time

      {:ok, recovered} = Article.recover(article)

      assert recovered.deleted_at == nil
      assert recovered.id == article.id
      assert recovered.title == "Deleted Article"

      # Verify it's updated in the database
      db_article = TestRepo.get!(Article, article.id)
      assert db_article.deleted_at == nil
    end

    test "can recover an already active record (idempotent)" do
      article = TestRepo.insert!(%Article{title: "Active Article", deleted_at: nil})

      {:ok, recovered} = Article.recover(article)

      assert recovered.deleted_at == nil
    end

    test "works with different schema (Tag)" do
      article = TestRepo.insert!(%Article{title: "Some Article", deleted_at: nil})
      deleted_time = ~U[2024-01-15 10:00:00Z]

      tag =
        TestRepo.insert!(%Tag{
          name: "Deleted tag",
          article_id: article.id,
          deleted_at: deleted_time
        })

      assert tag.deleted_at == deleted_time

      {:ok, recovered} = Tag.recover(tag)

      assert recovered.deleted_at == nil
      assert recovered.name == "Deleted tag"
    end

    test "raises when record doesn't exist" do
      fake_article = %Article{id: 999_999, title: "Fake", deleted_at: ~U[2024-01-15 10:00:00Z]}

      assert_raise Ecto.NoResultsError, fn ->
        Article.recover(fake_article)
      end
    end

    test "preserves all other fields when recovering" do
      article =
        TestRepo.insert!(%Article{
          title: "Important Article",
          body: "Some content",
          published: true,
          deleted_at: ~U[2024-01-15 10:00:00Z]
        })

      {:ok, recovered} = Article.recover(article)

      assert recovered.title == "Important Article"
      assert recovered.body == "Some content"
      assert recovered.published == true
      assert recovered.deleted_at == nil
    end
  end

  describe "integration tests" do
    test "filtering and recovering workflow" do
      # Create some articles
      article1 = TestRepo.insert!(%Article{title: "Keep this", deleted_at: nil})

      article2 =
        TestRepo.insert!(%Article{title: "Trash this", deleted_at: ~U[2024-01-15 10:00:00Z]})

      article3 =
        TestRepo.insert!(%Article{title: "Trash too", deleted_at: ~U[2024-02-20 15:30:00Z]})

      # Query only active articles
      active = Article.not_trashed(Article) |> TestRepo.all()
      assert length(active) == 1
      assert hd(active).id == article1.id

      # Query only trashed articles
      trashed = Article.only_trashed(Article) |> TestRepo.all()
      assert length(trashed) == 2

      # Recover one
      {:ok, _} = Article.recover(article2)

      # Now we should have 2 active
      active = Article.not_trashed(Article) |> TestRepo.all()
      assert length(active) == 2

      # And 1 trashed
      trashed = Article.only_trashed(Article) |> TestRepo.all()
      assert length(trashed) == 1
      assert hd(trashed).id == article3.id
    end

    test "works with associations" do
      article = TestRepo.insert!(%Article{title: "Article with tags", deleted_at: nil})

      tag1 = TestRepo.insert!(%Tag{name: "Active tag", article_id: article.id, deleted_at: nil})

      tag2 =
        TestRepo.insert!(%Tag{
          name: "Deleted tag",
          article_id: article.id,
          deleted_at: ~U[2024-01-15 10:00:00Z]
        })

      # Get only active tags
      import Ecto.Query

      active_tags =
        from(t in Tag, where: t.article_id == ^article.id)
        |> Tag.not_trashed()
        |> TestRepo.all()

      assert length(active_tags) == 1
      assert hd(active_tags).id == tag1.id

      # Get only deleted tags
      deleted_tags =
        from(t in Tag, where: t.article_id == ^article.id)
        |> Tag.only_trashed()
        |> TestRepo.all()

      assert length(deleted_tags) == 1
      assert hd(deleted_tags).id == tag2.id
    end

    test "soft delete with unique constraint (only active records)" do
      article = TestRepo.insert!(%Article{title: "Test Article", deleted_at: nil})

      # Insert a tag
      tag1 = TestRepo.insert!(%Tag{name: "elixir", article_id: article.id, deleted_at: nil})

      # Cannot insert duplicate active tag
      assert_raise Ecto.ConstraintError, fn ->
        TestRepo.insert!(%Tag{name: "elixir", article_id: article.id, deleted_at: nil})
      end

      # Soft delete the first tag
      tag1_deleted =
        tag1
        |> Ecto.Changeset.change(deleted_at: DateTime.utc_now() |> DateTime.truncate(:second))
        |> TestRepo.update!()

      assert tag1_deleted.deleted_at != nil

      # Now we can insert a new active tag with the same name
      tag2 = TestRepo.insert!(%Tag{name: "elixir", article_id: article.id, deleted_at: nil})

      assert tag2.id != tag1.id
      assert tag2.name == "elixir"
      assert tag2.deleted_at == nil

      # And we can have multiple deleted tags with the same name
      _tag2_deleted =
        tag2
        |> Ecto.Changeset.change(deleted_at: DateTime.utc_now() |> DateTime.truncate(:second))
        |> TestRepo.update!()

      # Both deleted tags exist
      deleted_tags = Tag.only_trashed(Tag) |> TestRepo.all()
      assert length(deleted_tags) == 2
    end

    test "mixed queries across both soft delete types" do
      # Create NaiveSoftDelete records (Posts with boolean)
      post = TestRepo.insert!(%Bonf.Post{title: "Post", deleted: false})
      TestRepo.insert!(%Bonf.Comment{body: "Comment", post_id: post.id, deleted: false})

      # Create SoftDelete records (Articles with deleted_at)
      article = TestRepo.insert!(%Article{title: "Article", deleted_at: nil})
      TestRepo.insert!(%Tag{name: "Tag", article_id: article.id, deleted_at: nil})

      # Both types work independently
      assert length(Bonf.Post.not_trashed() |> TestRepo.all()) == 1
      assert length(Article.not_trashed(Article) |> TestRepo.all()) == 1
    end

    test "recovering multiple records in a transaction" do
      article1 =
        TestRepo.insert!(%Article{title: "Article 1", deleted_at: ~U[2024-01-15 10:00:00Z]})

      article2 =
        TestRepo.insert!(%Article{title: "Article 2", deleted_at: ~U[2024-01-15 10:00:00Z]})

      article3 =
        TestRepo.insert!(%Article{title: "Article 3", deleted_at: ~U[2024-01-15 10:00:00Z]})

      TestRepo.transaction(fn ->
        Article.recover(article1)
        Article.recover(article2)
        Article.recover(article3)
      end)

      active = Article.not_trashed(Article) |> TestRepo.all()
      assert length(active) == 3
    end
  end

  describe "deleted_at timestamp behavior" do
    test "can query by deletion date range" do
      TestRepo.insert!(%Article{title: "Deleted Jan", deleted_at: ~U[2024-01-15 10:00:00Z]})
      TestRepo.insert!(%Article{title: "Deleted Feb", deleted_at: ~U[2024-02-15 10:00:00Z]})
      TestRepo.insert!(%Article{title: "Deleted Mar", deleted_at: ~U[2024-03-15 10:00:00Z]})

      import Ecto.Query

      results =
        Article
        |> Article.only_trashed()
        |> where([a], a.deleted_at >= ^~U[2024-02-01 00:00:00Z])
        |> where([a], a.deleted_at < ^~U[2024-03-01 00:00:00Z])
        |> TestRepo.all()

      assert length(results) == 1
      assert hd(results).title == "Deleted Feb"
    end

    test "preserves exact deletion timestamp" do
      deletion_time = ~U[2024-01-15 14:23:45Z]
      article = TestRepo.insert!(%Article{title: "Precise Time", deleted_at: deletion_time})

      db_article = TestRepo.get!(Article, article.id)
      assert DateTime.compare(db_article.deleted_at, deletion_time) == :eq
    end
  end
end
