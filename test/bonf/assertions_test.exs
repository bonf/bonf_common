defmodule Bonf.AssertionsTest do
  use Bonf.DataCase
  use Bonf.CustomAssertions, repo: Bonf.TestRepo

  alias Bonf.TestRepo, as: Repo
  alias Bonf.Post
  alias Bonf.Comment

  describe "assert_equal_dt" do
    test "works with second precision" do
      a = ~U[2023-05-23 20:37:21Z]
      b = ~U[2023-05-23 20:37:22Z]

      refute a == b
      assert_equal_dt(a, b)
    end

    test "works with microsecond precision" do
      a = ~U[2023-09-01 08:46:08.501961Z]
      b = ~U[2023-09-01 08:46:08.341961Z]

      refute a == b
      assert_equal_dt(a, b)
    end
  end

  describe "assert_difference/3 (function-based)" do
    test "passes when counter increases by expected amount" do
      assert_difference(fn -> Repo.aggregate(Post, :count) end, 1, fn ->
        Repo.insert!(%Post{title: "New Post"})
      end)
    end

    test "passes when counter decreases by expected amount" do
      # Create 10 posts
      for i <- 1..10 do
        Repo.insert!(%Post{title: "Post #{i}"})
      end

      assert_difference(fn -> Repo.aggregate(Post, :count) end, -5, fn ->
        posts_to_delete = Repo.all(from(p in Post, limit: 5))
        Enum.each(posts_to_delete, &Repo.delete!/1)
      end)
    end

    test "passes when counter doesn't change and delta is 0" do
      Repo.insert!(%Post{title: "Existing Post"})

      assert_difference(fn -> Repo.aggregate(Post, :count) end, 0, fn ->
        :ok
      end)
    end

    test "fails when counter changes by different amount" do
      assert_raise ExUnit.AssertionError,
                   ~r/expected count to change by 3 but changed by 1/,
                   fn ->
                     assert_difference(fn -> Repo.aggregate(Post, :count) end, 3, fn ->
                       Repo.insert!(%Post{title: "Single Post"})
                     end)
                   end
    end

    test "works with complex expressions" do
      # Insert initial data
      Repo.insert!(%Post{title: "Post 1"})
      Repo.insert!(%Post{title: "Post 2"})
      Repo.insert!(%Comment{body: "Comment 1"})

      assert_difference(
        fn -> Repo.aggregate(Post, :count) + Repo.aggregate(Comment, :count) end,
        7,
        fn ->
          for i <- 3..5, do: Repo.insert!(%Post{title: "Post #{i}"})
          for i <- 2..5, do: Repo.insert!(%Comment{body: "Comment #{i}"})
        end
      )
    end
  end

  describe "assert_no_difference/2 (function-based)" do
    test "passes when counter doesn't change" do
      Repo.insert!(%Post{title: "Existing Post"})

      assert_no_difference(fn -> Repo.aggregate(Post, :count) end, fn ->
        :ok
      end)
    end

    test "fails when counter changes" do
      assert_raise ExUnit.AssertionError,
                   ~r/expected count to change by 0 but changed by 1/,
                   fn ->
                     assert_no_difference(fn -> Repo.aggregate(Post, :count) end, fn ->
                       Repo.insert!(%Post{title: "New Post"})
                     end)
                   end
    end
  end

  describe "assert_difference/2 (schema-based)" do
    test "passes when single schema count increases" do
      assert_difference(%{Post => 1}, fn ->
        Repo.insert!(%Post{title: "New Post"})
      end)
    end

    test "passes when single schema count decreases" do
      # Create 10 posts
      for i <- 1..10 do
        Repo.insert!(%Post{title: "Post #{i}"})
      end

      assert_difference(%{Post => -3}, fn ->
        posts_to_delete = Repo.all(from(p in Post, limit: 3))
        Enum.each(posts_to_delete, &Repo.delete!/1)
      end)
    end

    test "passes when multiple schemas change by different amounts" do
      assert_difference(%{Post => 2, Comment => 3}, fn ->
        Repo.insert!(%Post{title: "Post 1"})
        Repo.insert!(%Post{title: "Post 2"})
        Repo.insert!(%Comment{body: "Comment 1"})
        Repo.insert!(%Comment{body: "Comment 2"})
        Repo.insert!(%Comment{body: "Comment 3"})
      end)
    end

    test "passes when schema count doesn't change (delta = 0)" do
      Repo.insert!(%Post{title: "Existing Post"})

      assert_difference(%{Post => 0}, fn ->
        :ok
      end)
    end

    test "fails when schema count changes by wrong amount" do
      assert_raise ExUnit.AssertionError,
                   ~r/expected Bonf.Post count to change by 5, but changed by 2/,
                   fn ->
                     assert_difference(%{Post => 5}, fn ->
                       Repo.insert!(%Post{title: "Post 1"})
                       Repo.insert!(%Post{title: "Post 2"})
                     end)
                   end
    end

    test "works with multiple schemas where some don't change" do
      Repo.insert!(%Comment{body: "Existing Comment"})

      assert_difference(%{Post => 1, Comment => 0}, fn ->
        Repo.insert!(%Post{title: "New Post"})
      end)
    end
  end

  describe "assert_no_difference/2 (schema-based)" do
    test "passes when single schema count doesn't change" do
      Repo.insert!(%Post{title: "Existing Post"})

      assert_no_difference([Post], fn ->
        :ok
      end)
    end

    test "passes when multiple schema counts don't change" do
      Repo.insert!(%Post{title: "Existing Post"})
      Repo.insert!(%Comment{body: "Existing Comment"})

      assert_no_difference([Post, Comment], fn ->
        :ok
      end)
    end

    test "fails when any schema count changes" do
      assert_raise ExUnit.AssertionError,
                   ~r/expected Bonf.Post count to change by 0, but changed by 1/,
                   fn ->
                     assert_no_difference([Post, Comment], fn ->
                       Repo.insert!(%Post{title: "New Post"})
                     end)
                   end
    end
  end
end
