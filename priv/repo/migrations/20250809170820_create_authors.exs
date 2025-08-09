defmodule BookApp.Repo.Migrations.CreateAuthors do
  use Ecto.Migration

  def change do
    create table(:authors) do
      add :name, :string, null: false
      add :birth_date, :date
      add :country, :string
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:authors, [:name])
  end
end
