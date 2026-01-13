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

For counting function changes:

```elixir
  assert_difference(count_items(), -1, fn ->
    Admin.delete_item(item)
  end)

  assert_no_difference(count_items(), fn ->
    Admin.insert_item(invalid_attrs)
  end)
```

For schema count changes (requires `use Bonf.CustomAssertions, repo: YourRepo`):

```elixir
  # Assert that one User and one Profile are created
  assert_difference(%{User => 1, Profile => 1}, fn ->
    MyApp.create_user_with_profile(attrs)
  end)

  # Assert that no records are changed
  assert_no_difference([User, Profile], fn ->
    MyApp.invalid_operation()
  end)
```

#### assert_equal_dt

```elixir

  assert_equal_dt(
    res.expires_at,
    DateTime.utc_now() |> DateTime.add(30 * 60)
  )
```


Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/bonf_common>.

