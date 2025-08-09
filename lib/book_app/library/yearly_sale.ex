defmodule BookApp.Library.YearlySale do
  use Ecto.Schema
  import Ecto.Changeset

  schema "yearly_sales" do
    field :year, :integer
    field :sales, :integer

    belongs_to :book, BookApp.Library.Book

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(yearly_sale, attrs) do
    yearly_sale
    |> cast(attrs, [:year, :sales, :book_id])
    |> validate_required([:year, :sales, :book_id])
    |> validate_number(:sales, greater_than_or_equal_to: 0)
    |> validate_number(:year, greater_than_or_equal_to: 1450, less_than_or_equal_to: 2100)
    |> unique_constraint([:book_id, :year])
    |> foreign_key_constraint(:book_id)
    |> check_constraint(:sales, name: :sales_nonneg)
    |> check_constraint(:year, name: :year_reasonable)
  end
end
