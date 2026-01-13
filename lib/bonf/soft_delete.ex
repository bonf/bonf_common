defmodule Bonf.SoftDelete do
  defmacro __using__(opts) do
    repo = Keyword.fetch!(opts, :repo)

    quote do
      import Ecto.Query, only: [where: 3]

      def not_trashed(queryable \\ __MODULE__) do
        where(queryable, [r], is_nil(r.deleted_at))
      end

      def only_trashed(queryable \\ __MODULE__) do
        where(queryable, [r], not is_nil(r.deleted_at))
      end

      def recover(struct) do
        unquote(repo).get!(__MODULE__, struct.id)
        |> Ecto.Changeset.change(deleted_at: nil)
        |> unquote(repo).update()
      end
    end
  end
end
