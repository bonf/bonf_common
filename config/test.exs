import Config

# Configure the test database
config :bonf_common, Bonf.TestRepo,
  username: System.get_env("POSTGRES_USER") || "postgres",
  password: System.get_env("POSTGRES_PASSWORD") || "postgres",
  hostname: System.get_env("POSTGRES_HOST") || "localhost",
  database: "bonf_common_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :bonf_common, ecto_repos: [Bonf.TestRepo]
