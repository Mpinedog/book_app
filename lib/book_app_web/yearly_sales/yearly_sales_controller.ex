defmodule BookAppWeb.YearlySalesController do
  use BookAppWeb, :controller

  alias BookApp.Catalog
  alias BookApp.Catalog.YearlySale

  def index(conn, %{"book_id" => book_id}) do
    book = Catalog.get_book!(book_id)
    yearly_sales = Catalog.list_yearly_sales_for_book(book_id)
    render(conn, :index, book: book, yearly_sales: yearly_sales)
  end

  def new(conn, %{"book_id" => book_id}) do
    book = Catalog.get_book!(book_id)
    changeset = Catalog.change_yearly_sale(%YearlySale{})
    render(conn, :new, book: book, changeset: changeset)
  end

  def create(conn, %{"book_id" => book_id, "yearly_sale" => yearly_sale_params}) do
    book = Catalog.get_book!(book_id)
    yearly_sale_params = Map.put(yearly_sale_params, "book_id", book_id)

    case Catalog.create_yearly_sale(yearly_sale_params) do
      {:ok, yearly_sale} ->
        conn
        |> put_flash(:info, "Yearly sale created successfully.")
        |> redirect(to: ~p"/books/#{book}/yearly_sales")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, book: book, changeset: changeset)
    end
  end

  def edit(conn, %{"book_id" => book_id, "id" => id}) do
    book = Catalog.get_book!(book_id)
    yearly_sale = Catalog.get_yearly_sale!(id)
    changeset = Catalog.change_yearly_sale(yearly_sale)
    render(conn, :edit, book: book, yearly_sale: yearly_sale, changeset: changeset)
  end

  def update(conn, %{"book_id" => book_id, "id" => id, "yearly_sale" => yearly_sale_params}) do
    book = Catalog.get_book!(book_id)
    yearly_sale = Catalog.get_yearly_sale!(id)

    case Catalog.update_yearly_sale(yearly_sale, yearly_sale_params) do
      {:ok, yearly_sale} ->
        conn
        |> put_flash(:info, "Yearly sale updated successfully.")
        |> redirect(to: ~p"/books/#{book}/yearly_sales")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, book: book, yearly_sale: yearly_sale, changeset: changeset)
    end
  end

  def delete(conn, %{"book_id" => book_id, "id" => id}) do
    book = Catalog.get_book!(book_id)
    yearly_sale = Catalog.get_yearly_sale!(id)
    {:ok, _yearly_sale} = Catalog.delete_yearly_sale(yearly_sale)

    conn
    |> put_flash(:info, "Yearly sale deleted successfully.")
    |> redirect(to: ~p"/books/#{book}/yearly_sales")
  end
end
