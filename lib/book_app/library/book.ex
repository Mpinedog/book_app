defmodule BookApp.Library.Book do
  use Ecto.Schema
  import Ecto.Changeset

  schema "books" do
    field :title, :string
    field :summary, :string
    field :published_on, :date
    field :lifetime_sales, :integer

    belongs_to :author, BookApp.Library.Author
    has_many :yearly_sales, BookApp.Library.YearlySale
    has_many :reviews, BookApp.Library.Review

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(book, attrs) do
    book
    |> cast(attrs, [:title, :summary, :published_on, :lifetime_sales, :author_id])
    |> validate_required([:title, :author_id])
    |> validate_number(:lifetime_sales, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:author_id)
    |> check_constraint(:lifetime_sales, name: :lifetime_sales_nonneg)
  end
end
