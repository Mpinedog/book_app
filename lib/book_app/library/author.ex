defmodule BookApp.Library.Author do
  use Ecto.Schema
  import Ecto.Changeset

  schema "authors" do
    field :name, :string
    field :birth_date, :date
    field :country, :string
    field :description, :string

    has_many :books, BookApp.Library.Book
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(author, attrs) do
    author
    |> cast(attrs, [:name, :birth_date, :country, :description])
    |> validate_required([:name])
    |> validate_length(:name, min: 2)
    |> unique_constraint(:name)
  end
end
