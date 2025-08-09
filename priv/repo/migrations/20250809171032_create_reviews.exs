defmodule BookApp.Repo.Migrations.CreateReviews do
  use Ecto.Migration

  def change do
    create table(:reviews) do
      add :body, :text
      add :score, :integer, null: false
      add :upvotes, :integer, null: false, default: 0
      add :book_id, references(:books, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:reviews, [:book_id])
    create index(:reviews, [:score, :upvotes])

  end
end
