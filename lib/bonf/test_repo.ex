defmodule Bonf.TestRepo do
  use Ecto.Repo,
    otp_app: :bonf_common,
    adapter: Ecto.Adapters.Postgres

  use Bonf.Repo
end
