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

  # set primary key sequence to max value + 1
  MyRepo.reset_pkey("users")

  # truncate table and restart identity
  MyRepo.truncate("users")

  

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
Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/bonf_common>.

