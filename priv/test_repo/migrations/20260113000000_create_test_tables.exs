defmodule Bonf.TestRepo.Migrations.CreateTestTables do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string, null: false
      add :content, :text
      add :deleted, :boolean, default: false, null: false

      timestamps()
    end

    create table(:comments) do
      add :body, :text, null: false
      add :post_id, references(:posts, on_delete: :delete_all)
      add :deleted, :boolean, default: false, null: false

      timestamps()
    end

    create index(:comments, [:post_id])
  end
end
