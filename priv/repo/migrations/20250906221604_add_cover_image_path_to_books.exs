defmodule BookApp.Repo.Migrations.AddCoverImagePathToBooks do
  use Ecto.Migration

  def change do
    alter table(:books) do
      add :cover_image_path, :string
    end
  end
end
