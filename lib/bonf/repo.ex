defmodule Bonf.Repo do
  defmacro __using__(_opts) do
    quote do
      import Ecto.Query

      def count(query), do: aggregate(query, :count, :id)
      def sum(query, field), do: aggregate(query, :sum, field)

      def last(query) do
        query |> order_by([r], {:desc, r.id}) |> limit(1) |> one()
      end

      def trash(schema) do
        schema
        |> Ecto.Changeset.change(deleted_at: DateTime.truncate(DateTime.utc_now(), :second))
        |> update()
      end

      def reset_pkey(table_name) when is_binary(table_name) do
        query(
          "SELECT setval('#{table_name}_id_seq', COALESCE((SELECT MAX(id)+1 FROM #{table_name}), 1), false);"
        )
      end

      def truncate(table_name) when is_binary(table_name) do
        Ecto.Adapters.SQL.query(__MODULE__, "TRUNCATE #{table_name} RESTART IDENTITY")
      end
    end
  end
end
