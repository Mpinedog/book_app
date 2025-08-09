defmodule BookApp.Catalog.YearlySale do
  use Ecto.Schema
  import Ecto.Changeset

  schema "yearly_sales" do
    field :year, :integer
    field :amount, :integer
    field :sales, :integer
    belongs_to :book, BookApp.Catalog.Book

    timestamps()
  end

  @doc false
  def changeset(yearly_sales, attrs) do
    yearly_sales
    |> cast(attrs, [:year, :amount, :sales, :book_id])
    |> validate_required([:year, :book_id, :sales])
    |> validate_number(:sales, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:book_id)
  end
end
