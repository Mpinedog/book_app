
defmodule BookApp.Catalog do
  @moduledoc """
  The Catalog context.
  """

  import Ecto.Query, warn: false
  alias BookApp.Repo
  alias BookApp.Catalog.Book
  alias BookApp.Catalog.Review

  @doc """
  Returns the list of books.
  """
  def list_books do
    Book
    |> order_by([b], b.title)
    |> Repo.all()
    |> Repo.preload([:author, :yearly_sales])
  end

  @doc """
  Searches books by summary/description containing the given terms.
  Uses OpenSearch for full-text search with fallback to database.
  """
  def search_books_by_description(search_term) when is_binary(search_term) and search_term != "" do
    # Try OpenSearch first
    case BookApp.Search.search_books(search_term) do
      [] -> 
        # Fallback to original database search
        search_pattern = "%#{String.downcase(search_term)}%"

        Book
        |> where([b], like(fragment("LOWER(?)", b.summary), ^search_pattern))
        |> order_by([b], b.title)
        |> Repo.all()
        |> Repo.preload([:author, :yearly_sales])
      
      results -> results
    end
  end

  def search_books_by_description(_), do: []

  @doc """
  Gets a single book.
  Returns nil if the Book does not exist.
  """
  def get_book(id) do
    Book
    |> Repo.get(id)
    |> Repo.preload([:author, :reviews, :yearly_sales])
  end

  @doc """
  Gets a single book.
  Raises if the Book does not exist.
  """
  def get_book!(id) do
    Book
    |> Repo.get!(id)
    |> Repo.preload([:author, :reviews, :yearly_sales])
  end

  @doc """
  Creates a book.
  """
  def create_book(attrs \\ %{}) do
    case %Book{}
         |> Book.changeset(attrs)
         |> Repo.insert() do
      {:ok, book} = result ->
        # Index the new book in OpenSearch
        Task.start(fn -> BookApp.Search.index_book(book) end)
        result
      
      error -> error
    end
  end

  @doc """
  Updates a book.
  """
  def update_book(%Book{} = book, attrs) do
    case book
         |> Book.changeset(attrs)
         |> Repo.update() do
      {:ok, updated_book} = result ->
        # Re-index the updated book in OpenSearch
        Task.start(fn -> BookApp.Search.index_book(updated_book) end)
        result
      
      error -> error
    end
  end

  @doc """
  Deletes a book.
  """
  def delete_book(%Book{} = book) do
    case Repo.delete(book) do
      {:ok, deleted_book} = result ->
        # Remove from OpenSearch index
        Task.start(fn -> BookApp.Search.delete_book_from_index(deleted_book.id) end)
        result
      
      error -> error
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking book changes.
  """
  def change_book(%Book{} = book, attrs \\ %{}) do
    Book.changeset(book, attrs)
  end

  ## Reviews

  @doc """
  Returns the list of reviews.
  """
  def list_reviews do
    Review
    |> order_by([r], desc: r.inserted_at)
    |> Repo.all()
    |> Repo.preload([:book])
  end

  @doc """
  Gets a single review.
  Raises if the Review does not exist.
  """
  def get_review!(id) do
    Review
    |> Repo.get!(id)
    |> Repo.preload([:book])
  end

  @doc """
  Creates a review.
  """
  def create_review(attrs \\ %{}) do
    case %Review{}
         |> Review.changeset(attrs)
         |> Repo.insert() do
      {:ok, review} = result ->
        # Re-index the book in OpenSearch since reviews are part of the search index
        if review.book_id do
          book = get_book!(review.book_id)
          Task.start(fn -> BookApp.Search.index_book(book) end)
        end
        result
      
      error -> error
    end
  end

  @doc """
  Updates a review.
  """
  def update_review(%Review{} = review, attrs) do
    case review
         |> Review.changeset(attrs)
         |> Repo.update() do
      {:ok, updated_review} = result ->
        # Re-index the book in OpenSearch since reviews are part of the search index
        if updated_review.book_id do
          book = get_book!(updated_review.book_id)
          Task.start(fn -> BookApp.Search.index_book(book) end)
        end
        result
      
      error -> error
    end
  end

  @doc """
  Deletes a review.
  """
  def delete_review(%Review{} = review) do
    case Repo.delete(review) do
      {:ok, deleted_review} = result ->
        # Re-index the book in OpenSearch since reviews are part of the search index
        if deleted_review.book_id do
          book = get_book!(deleted_review.book_id)
          Task.start(fn -> BookApp.Search.index_book(book) end)
        end
        result
      
      error -> error
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking review changes.
  """
  def change_review(%Review{} = review, attrs \\ %{}) do
    Review.changeset(review, attrs)
  end

  def list_top_books(limit \\ 10) do
    from(b in Book,
      left_join: r in assoc(b, :reviews),
      group_by: b.id,
      order_by: [desc: avg(r.score)],
      limit: ^limit,
      preload: [:author, :reviews]
    )
    |> Repo.all()
  end

  def list_top_selling_books() do
    from(b in Book,
      order_by: [desc: b.lifetime_sales],
      limit: 50,
      preload: [:author, :yearly_sales]
    )
    |> Repo.all()
  end

  def get_author_total_sales(author_id) do
    from(b in Book,
      where: b.author_id == ^author_id,
      select: sum(b.lifetime_sales)
    )
    |> Repo.one() || 0
  end

  def get_top_5_books_by_year(year) do
    from(ys in BookApp.Catalog.YearlySale,
      where: ys.year == ^year,
      order_by: [desc: ys.sales],
      limit: 5,
      select: ys.sales
    )
    |> Repo.all()
  end

  def get_book_sales_for_year(book_id, year) do
    from(ys in BookApp.Catalog.YearlySale,
      where: ys.book_id == ^book_id and ys.year == ^year,
      select: ys.sales
    )
    |> Repo.one()
  end

  def list_yearly_sales_for_book(book_id) do
    from(ys in BookApp.Catalog.YearlySale,
      where: ys.book_id == ^book_id,
      order_by: [desc: ys.year]
    )
    |> Repo.all()
  end


  def get_yearly_sale!(id), do: Repo.get!(BookApp.Catalog.YearlySale, id)


  def create_yearly_sale(attrs \\ %{}) do
    %BookApp.Catalog.YearlySale{}
    |> BookApp.Catalog.YearlySale.changeset(attrs)
    |> Repo.insert()
  end


  def update_yearly_sale(%BookApp.Catalog.YearlySale{} = yearly_sale, attrs) do
    yearly_sale
    |> BookApp.Catalog.YearlySale.changeset(attrs)
    |> Repo.update()
  end


  def delete_yearly_sale(%BookApp.Catalog.YearlySale{} = yearly_sale) do
    Repo.delete(yearly_sale)
  end


  def change_yearly_sale(%BookApp.Catalog.YearlySale{} = yearly_sale, attrs \\ %{}) do
    BookApp.Catalog.YearlySale.changeset(yearly_sale, attrs)
  end

end
