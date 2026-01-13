# Bonf Common utilities


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `bonf_common` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bonf_common, "~> 0.1", git: "https://github.com/bonf/bonf_common", branch: "master"}
  ]
end
```


## Bonf.Repo

utilities for Repo module

```elixir
defmodule MyRepo do
  use Ecto.Repo,
    otp_app: :myapp,
    adapter: Ecto.Adapters.Postgres

  use Bonf.Repo
end
```

This will add the following functions to MyRepo:

```elixir
  alias MyApp.Accounts.User

  # returns the last inserted record
  MyRepo.last(User)

  # returns a count of available records
  MyRepo.count(User)

  # returns a sum of the specified field
  MyRepo.sum(User, :score)

  # sets deleted_at field to current time
  MyRepo.trash(%User{})

  # truncate table and restart identity
  MyRepo.truncate("users")

  # set primary key sequence to max value + 1
  MyRepo.reset_pkey("users")

  # reset primary key on all tables (ONLY TO USE IN DEV/TEST SEEDS!)
  MyRepo.reset_all_pkeys()
```


## Bonf.Enum

Rails like enum types for Ecto

```elixir
defmodule MyEctoTypes.UserRole do
  use Bonf.Enum, %{
    admin: 0,
    editor: 1,
    guest: 2
  }
end
```

exported functions:

```elixir
    MyEctoTypes.UserRole.all() # [:admin, :editor, :guest]

    MyEctoTypes.UserRole.all_map() # %{
                                   #   admin: 0,
                                   #   editor: 1,
                                   #   guest: 2
                                   # }


    MyEctoTypes.UserRole.find_by_value(1) # :editor

```


usage:

```elixir
  schema "users" do
    ...
    field :role, MyEctoTypes.UserRole
    ...
  end

  %User.create(role: :admin ...)
```


## Custom Assertions

Custom assertions for tests

```elixir
defmodule MyApp.DataCase do
  use ExUnit.CaseTemplate
  use Bonf.CustomAssertions, repo: MyApp.Repo

  # ... rest of your DataCase setup
end
```

Or in individual test files:

```elixir
defmodule MyApp.SomeTest do
  use ExUnit.Case
  use Bonf.CustomAssertions, repo: MyApp.Repo

  # ... your tests
end
```

#### assert_difference

For schema count changes (recommended - cleaner syntax):

```elixir
  # Assert that one User and one Profile are created
  assert_difference(%{User => 1, Profile => 1}, fn ->
    MyApp.create_user_with_profile(attrs)
  end)

  # Assert that records are deleted
  assert_difference(%{Item => -1}, fn ->
    Admin.delete_item(item)
  end)

  # Assert that no records are changed
  assert_no_difference([User, Profile], fn ->
    MyApp.invalid_operation()
  end)
```

For custom counting logic (when you need more control):

```elixir
  # Define a helper function for clean syntax
  defp count_items, do: Repo.aggregate(Item, :count)
  defp count_active_users, do: Repo.aggregate(from(u in User, where: u.active), :count)

  # Then use it with the capture operator
  assert_difference(&count_items/0, 1, fn ->
    Admin.create_item(attrs)
  end)

  assert_difference(&count_active_users/0, -1, fn ->
    Users.deactivate_user(user)
  end)

  assert_no_difference(&count_items/0, fn ->
    Admin.insert_item(invalid_attrs)
  end)
```

#### assert_equal_dt

```elixir

  assert_equal_dt(
    res.expires_at,
    DateTime.utc_now() |> DateTime.add(30 * 60)
  )
```


## Soft Delete

Two soft delete implementations are available depending on your needs.

### Bonf.NaiveSoftDelete

Simple boolean-based soft delete using a `deleted` field.

**Setup:**

Add a `deleted` boolean field to your schema:

```elixir
defmodule MyApp.Post do
  use Ecto.Schema
  use Bonf.NaiveSoftDelete, repo: MyApp.Repo

  schema "posts" do
    field :title, :string
    field :deleted, :boolean, default: false
    
    timestamps()
  end
end
```

**Migration:**

```elixir
create table(:posts) do
  add :title, :string
  add :deleted, :boolean, default: false, null: false
  
  timestamps()
end
```

**Usage:**

```elixir
# Query only active (not deleted) records
active_posts = Post.not_trashed() |> Repo.all()

# Query only deleted records
deleted_posts = Post.only_trashed() |> Repo.all()

# Works with custom queries
import Ecto.Query

recent_active = 
  from(p in Post, where: p.inserted_at > ^days_ago(7))
  |> Post.not_trashed()
  |> Repo.all()

# Recover a soft-deleted record
{:ok, recovered_post} = Post.recover(deleted_post)
```

### Buzz.SoftDelete

Timestamp-based soft delete using a `deleted_at` field. Provides more flexibility for audit trails and date-based queries.

**Setup:**

Add a `deleted_at` timestamp field to your schema:

```elixir
defmodule MyApp.Article do
  use Ecto.Schema
  use Buzz.SoftDelete, repo: MyApp.Repo

  schema "articles" do
    field :title, :string
    field :deleted_at, :utc_datetime
    
    timestamps()
  end
end
```

**Migration:**

```elixir
create table(:articles) do
  add :title, :string
  add :deleted_at, :utc_datetime
  
  timestamps()
end

# Optional: Create partial unique index (only active records)
create unique_index(:articles, [:slug], where: "deleted_at IS NULL")
```

**Usage:**

```elixir
# Query only active (not deleted) records
active_articles = Article.not_trashed(Article) |> Repo.all()

# Query only deleted records
deleted_articles = Article.only_trashed(Article) |> Repo.all()

# Query deleted within a date range
import Ecto.Query

last_month_deletions =
  Article
  |> Article.only_trashed()
  |> where([a], a.deleted_at >= ^days_ago(30))
  |> order_by([a], desc: a.deleted_at)
  |> Repo.all()

# Recover a soft-deleted record
{:ok, recovered_article} = Article.recover(deleted_article)
```

**Which one to use?**

- Use `Bonf.NaiveSoftDelete` for simple cases where you just need to mark records as deleted
- Use `Buzz.SoftDelete` when you need:
  - Audit trails showing when records were deleted
  - Date-based queries on deletion time
  - Partial unique indexes (unique only for active records)
  - More flexibility for compliance and data retention requirements


