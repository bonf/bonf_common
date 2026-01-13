# Start the test repo
{:ok, _} = Bonf.TestRepo.start_link()

# Set up the sandbox mode for concurrent tests
Ecto.Adapters.SQL.Sandbox.mode(Bonf.TestRepo, :manual)

ExUnit.start()
