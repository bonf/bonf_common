defmodule Bonf.Post do
  use Ecto.Schema
  use Bonf.NaiveSoftDelete, repo: Bonf.TestRepo

  schema "posts" do
    field(:title, :string)
    field(:content, :string)
    field(:deleted, :boolean, default: false)

    has_many(:comments, Bonf.Comment)

    timestamps()
  end
end

defmodule Bonf.Comment do
  use Ecto.Schema
  use Bonf.NaiveSoftDelete, repo: Bonf.TestRepo

  schema "comments" do
    field(:body, :string)
    field(:deleted, :boolean, default: false)

    belongs_to(:post, Bonf.Post)

    timestamps()
  end
end

defmodule Bonf.Article do
  use Ecto.Schema
  use Buzz.SoftDelete, repo: Bonf.TestRepo

  schema "articles" do
    field(:title, :string)
    field(:body, :string)
    field(:published, :boolean, default: false)
    field(:deleted_at, :utc_datetime)

    has_many(:tags, Bonf.Tag)

    timestamps()
  end
end

defmodule Bonf.Tag do
  use Ecto.Schema
  use Buzz.SoftDelete, repo: Bonf.TestRepo

  schema "tags" do
    field(:name, :string)
    field(:deleted_at, :utc_datetime)

    belongs_to(:article, Bonf.Article)

    timestamps()
  end
end
