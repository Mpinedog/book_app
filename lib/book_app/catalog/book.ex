defmodule BookApp.Catalog.Book do
  use Ecto.Schema
  import Ecto.Changeset

  schema "books" do
    field :title, :string
    field :summary, :string
    field :published_on, :date
    field :lifetime_sales, :integer
    field :cover_image_path, :string
    belongs_to :author, BookApp.Authors.Author

    has_many :reviews, BookApp.Catalog.Review
    has_many :yearly_sales, BookApp.Catalog.YearlySale

    timestamps()
  end

  @doc false
  def changeset(book, attrs) do
    book
    |> cast(attrs, [:title, :summary, :published_on, :author_id, :lifetime_sales, :cover_image_path])
    |> validate_required([:title, :summary, :published_on, :author_id])
    |> foreign_key_constraint(:author_id)
  end
end
