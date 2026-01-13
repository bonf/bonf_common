defmodule Bonf.NaiveSoftDelete do
  defmacro __using__(opts) do
    repo = Keyword.fetch!(opts, :repo)

    quote do
      import Ecto.Query, only: [where: 3]

      def not_trashed(queryable \\ __MODULE__) do
        where(queryable, [r], r.deleted == false)
      end

      def only_trashed(queryable \\ __MODULE__) do
        where(queryable, [r], r.deleted == true)
      end

      def recover(struct) do
        unquote(repo).get!(__MODULE__, struct.id)
        |> Ecto.Changeset.change(deleted: false)
        |> unquote(repo).update()
      end
    end
  end
end
