defmodule BookApp.Repo.Migrations.CreateBooks do
  use Ecto.Migration

  def change do
    create table(:books) do
      add :title, :string, null: false
      add :summary, :text
      add :published_on, :date
      add :lifetime_sales, :integer, null: false, default: 0
      add :author_id, references(:authors, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:books, [:title])
    create index(:books, [:author_id])

  end
end
