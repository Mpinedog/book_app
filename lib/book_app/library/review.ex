defmodule BookApp.Library.Review do
  use Ecto.Schema
  import Ecto.Changeset

  schema "reviews" do
    field :body, :string
    field :score, :integer
    field :upvotes, :integer

    belongs_to :book, BookApp.Library.Book
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(review, attrs) do
    review
    |> cast(attrs, [:body, :score, :upvotes, :book_id])
    |> validate_required([:body, :score, :upvotes])
    |> validate_number(:score, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_number(:upvotes, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:book_id)
    |> check_constraint(:score, name: :score_range)
    |> check_constraint(:upvotes, name: :upvotes_nonneg)
  end
end
