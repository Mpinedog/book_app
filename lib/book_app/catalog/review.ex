defmodule BookApp.Catalog.Review do
  use Ecto.Schema
  import Ecto.Changeset

  schema "reviews" do
    field :body, :string
    field :score, :integer
    field :upvotes, :integer
    belongs_to :book, BookApp.Catalog.Book

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(review, attrs) do
    review
    |> cast(attrs, [:body, :score, :upvotes, :book_id])
    |> validate_required([:score, :book_id])
    |> validate_number(:score, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_number(:upvotes, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:book_id)
  end
end
