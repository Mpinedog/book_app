defmodule BookApp.Repo.Migrations.CreateAuthors do
  use Ecto.Migration

  def change do
    create table(:authors) do
      add :name, :string, null: false
      add :description, :text
      add :birth_date, :date
      add :country, :string

      timestamps()
    end

    create index(:authors, [:name])
  end
end
