defmodule BookAppWeb.BookController do
  use BookAppWeb, :controller

  alias BookApp.Catalog
  alias BookApp.Catalog.Book
  alias BookApp.Authors

  def index(conn, _params) do
    books = Catalog.list_books()
    render(conn, :index, books: books)
  end

  def new(conn, _params) do
    changeset = Catalog.change_book(%Book{})
    authors = Authors.list_authors()
    render(conn, :new, changeset: changeset, authors: authors)
  end

  def create(conn, %{"book" => book_params}) do
    case Catalog.create_book(book_params) do
      {:ok, book} ->
        conn
        |> put_flash(:info, "Book created successfully.")
        |> redirect(to: ~p"/books/#{book}")

      {:error, %Ecto.Changeset{} = changeset} ->
        authors = BookApp.Authors.list_authors()
        render(conn, :new, changeset: changeset, authors: authors)
    end
  end

  def show(conn, %{"id" => id}) do
    book = Catalog.get_book!(id)
    render(conn, :show, book: book)
  end

  def edit(conn, %{"id" => id}) do
    book = Catalog.get_book!(id)
    changeset = Catalog.change_book(book)
    authors = BookApp.Authors.list_authors()
    render(conn, :edit, book: book, changeset: changeset, authors: authors)
  end

  def update(conn, %{"id" => id, "book" => book_params}) do
    book = Catalog.get_book!(id)

    case Catalog.update_book(book, book_params) do
      {:ok, book} ->
        conn
        |> put_flash(:info, "Book updated successfully.")
        |> redirect(to: ~p"/books/#{book}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, book: book, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    book = Catalog.get_book!(id)
    {:ok, _book} = Catalog.delete_book(book)

    conn
    |> put_flash(:info, "Book deleted successfully.")
    |> redirect(to: ~p"/books")
  end
end
