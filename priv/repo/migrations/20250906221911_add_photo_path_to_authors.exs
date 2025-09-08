defmodule BookApp.Repo.Migrations.AddPhotoPathToAuthors do
  use Ecto.Migration

  def change do
    alter table(:authors) do
      add :photo_path, :string
    end
  end
end
