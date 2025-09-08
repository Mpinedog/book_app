defmodule BookApp.Authors do

  import Ecto.Query, warn: false
  alias BookApp.Repo
  alias BookApp.Authors.Author
  alias BookApp.Cache

  def list_authors do
    Repo.all(Author)
  end

  def get_author(id) do
    Author
    |> Repo.get(id)
    |> Repo.preload([:books])
  end

  def get_author!(id) do
    Author
    |> Repo.get!(id)
    |> Repo.preload([:books])
  end

  def create_author(attrs \\ %{}) do
    case %Author{}
         |> Author.changeset(attrs)
         |> Repo.insert() do
      {:ok, author} = result ->
        # No need to invalidate cache for new author
        result
      error -> error
    end
  end

  def update_author(%Author{} = author, attrs) do
    case author
         |> Author.changeset(attrs)
         |> Repo.update() do
      {:ok, updated_author} = result ->
        # Invalidate author-related caches
        Cache.invalidate_author_cache(author.id)
        result
      error -> error
    end
  end

  def delete_author(%Author{} = author) do
    case Repo.delete(author) do
      {:ok, deleted_author} = result ->
        # Invalidate author-related caches
        Cache.invalidate_author_cache(author.id)
        result
      error -> error
    end
  end

  def change_author(%Author{} = author, attrs \\ %{}) do
    Author.changeset(author, attrs)
  end

  def get_author_info(author_id) do
    Cache.get_or_compute_author_info(author_id, fn ->
      author = get_author!(author_id)
      total_sales = BookApp.Catalog.get_author_total_sales(author_id)

      %{
        author: author,
        total_sales: total_sales,
        book_count: length(author.books || [])
      }
    end)
  end
end
