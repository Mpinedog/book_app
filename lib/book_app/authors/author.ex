defmodule BookApp.Authors.Author do
  use Ecto.Schema
  import Ecto.Changeset

  schema "authors" do
    field :name, :string
    field :description, :string
    field :birth_date, :date
    field :country, :string
    field :photo_path, :string

    has_many :books, BookApp.Catalog.Book

    timestamps()
  end

  @doc false
  def changeset(author, attrs) do
    author
    |> cast(attrs, [:name, :description, :birth_date, :country, :photo_path])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
