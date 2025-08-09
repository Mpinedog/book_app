defmodule BookApp.Repo.Migrations.CreateYearlySales do
  use Ecto.Migration

  def change do
    create table(:yearly_sales) do
      add :year, :integer, null: false
      add :sales, :integer, null: false
      add :book_id, references(:books, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:yearly_sales, [:book_id, :year])
    create index(:yearly_sales, [:year])

  end
end
