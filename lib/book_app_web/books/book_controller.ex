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
    upload = book_params["cover_image"]

    book_params =
      if is_map(upload) and Map.has_key?(upload, :filename) and Map.has_key?(upload, :path) do
        storage_path = Application.get_env(:book_app, :image_storage_path) || "priv/static/uploads"
        filename = "#{:erlang.unique_integer([:positive])}_#{upload.filename}"
        dest_path = Path.join(storage_path, filename)
        File.cp(upload.path, dest_path)
        Map.put(book_params, "cover_image_path", "/uploads/#{filename}")
      else
        book_params
      end

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
    asset_host =
      if System.get_env("SERVE_STATIC_ASSETS", "true") == "true" do
        "http://localhost:4000"
      else
        "http://localhost:2015"
      end

    render(conn, :show, book: book, asset_host: asset_host)
  end

  def edit(conn, %{"id" => id}) do
    book = Catalog.get_book!(id)
    changeset = Catalog.change_book(book)
    authors = BookApp.Authors.list_authors()
    render(conn, :edit, book: book, changeset: changeset, authors: authors)
  end

  def update(conn, %{"id" => id, "book" => book_params}) do
    book = Catalog.get_book!(id)
    upload = book_params["cover_image"]
    image_storage_path = Application.get_env(:book_app, :image_storage_path)

    book_params =
      if is_map(upload) and Map.has_key?(upload, :filename) and Map.has_key?(upload, :path) do
        filename = "#{:erlang.unique_integer([:positive])}_#{upload.filename}"
        dest_path = Path.join(image_storage_path, filename)
        File.cp(upload.path, dest_path)
        Map.put(book_params, "cover_image_path", "/uploads/#{filename}")
      else
        book_params
      end

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

  def top_books(conn, _params) do
    books = Catalog.list_top_books()
    render(conn, :top_books, books: books)
  end

  def top_selling_books(conn, _params) do
    books = Catalog.list_top_selling_books()
    render(conn, :top_selling_books, books: books)
  end

  def search(conn, params) do
    search_term = params["search_term"] || ""
    books = if search_term != "", do: Catalog.search_books_by_description(search_term), else: []
    render(conn, :search, books: books, search_term: search_term)
  end
end
