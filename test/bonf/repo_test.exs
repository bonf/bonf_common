defmodule Bonf.RepoTest do
  use ExUnit.Case
  # doctest Bonf.Repo

  test "use" do
    defmodule MyRepo do
      use Ecto.Repo,
        otp_app: :bonf,
        adapter: Ecto.Adapters.Postgres

      use Bonf.Repo
    end

    assert function_exported?(MyRepo, :count, 1)
    assert function_exported?(MyRepo, :sum, 2)
    assert function_exported?(MyRepo, :last, 1)
    assert function_exported?(MyRepo, :trash, 1)
    assert function_exported?(MyRepo, :reset_pkey, 1)
    assert function_exported?(MyRepo, :truncate, 1)
  end
end
