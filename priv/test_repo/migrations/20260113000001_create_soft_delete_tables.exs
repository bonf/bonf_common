defmodule Bonf.TestRepo.Migrations.CreateSoftDeleteTables do
  use Ecto.Migration

  def change do
    create table(:articles) do
      add :title, :string, null: false
      add :body, :text
      add :published, :boolean, default: false
      add :deleted_at, :utc_datetime

      timestamps()
    end

    create table(:tags) do
      add :name, :string, null: false
      add :article_id, references(:articles, on_delete: :delete_all)
      add :deleted_at, :utc_datetime

      timestamps()
    end

    create index(:tags, [:article_id])
    create unique_index(:tags, [:name, :article_id], where: "deleted_at IS NULL")
  end
end
