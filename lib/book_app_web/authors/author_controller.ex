defmodule BookAppWeb.AuthorController do
  use BookAppWeb, :controller

  alias BookApp.Authors
  alias BookApp.Authors.Author

  def index(conn, _params) do
    authors = Authors.list_authors()
    render(conn, :index, authors: authors)
  end

  def show(conn, %{"id" => id}) do
    author = Authors.get_author!(id)
    render(conn, :show, author: author)
  end

  def new(conn, _params) do
    changeset = Author.changeset(%Author{}, %{})
    render(conn, :new, changeset: changeset, action: ~p"/authors")
  end

  def create(conn, %{"author" => author_params}) do
    upload = author_params["photo"]
    image_storage_path = Application.get_env(:book_app, :image_storage_path)

    author_params =
      if is_map(upload) and Map.has_key?(upload, :filename) and Map.has_key?(upload, :path) do
        filename = "#{:erlang.unique_integer([:positive])}_#{upload.filename}"
        dest_path = Path.join(image_storage_path, filename)
        File.cp(upload.path, dest_path)
        Map.put(author_params, "photo_path", "/uploads/#{filename}")
      else
        author_params
      end

    case Authors.create_author(author_params) do
      {:ok, author} ->
        conn
        |> put_flash(:info, "Author created successfully.")
        |> redirect(to: ~p"/authors/#{author.id}")
      {:error, changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def update(conn, %{"id" => id, "author" => author_params}) do
    author = Authors.get_author!(id)
    upload = author_params["photo"]
    image_storage_path = Application.get_env(:book_app, :image_storage_path)

    author_params =
      if is_map(upload) and Map.has_key?(upload, :filename) and Map.has_key?(upload, :path) do
        filename = "#{:erlang.unique_integer([:positive])}_#{upload.filename}"
        dest_path = Path.join(image_storage_path, filename)
        File.cp(upload.path, dest_path)
        Map.put(author_params, "photo_path", "/uploads/#{filename}")
      else
        author_params
      end

    case Authors.update_author(author, author_params) do
      {:ok, author} ->
        conn
        |> put_flash(:info, "Author updated successfully.")
        |> redirect(to: ~p"/authors/#{author.id}")
      {:error, changeset} ->
        render(conn, :edit, author: author, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    author = Authors.get_author!(id)
    {:ok, _author} = Authors.delete_author(author)
    conn
    |> put_flash(:info, "Author deleted successfully.")
    |> redirect(to: ~p"/authors")
  end
end
