defmodule BookApp.Catalog do

  import Ecto.Query, warn: false
  alias BookApp.Repo
  alias BookApp.Catalog.Book
  alias BookApp.Catalog.Review
  alias BookApp.Cache

  def list_books do
    Book
    |> order_by([b], b.title)
    |> Repo.all()
    |> Repo.preload([:author, :yearly_sales])
  end

  def search_books_by_description(search_term) when is_binary(search_term) and search_term != "" do
    Cache.get_or_compute_book_search(search_term, fn ->
      search_pattern = "%#{String.downcase(search_term)}%"

      Book
      |> where([b], like(fragment("LOWER(?)", b.summary), ^search_pattern))
      |> order_by([b], b.title)
      |> Repo.all()
      |> Repo.preload([:author, :yearly_sales])
    end)
  end

  def search_books_by_description(_), do: []

  def get_book(id) do
    Book
    |> Repo.get(id)
    |> Repo.preload([:author, :reviews, :yearly_sales])
  end

  def get_book!(id) do
    Book
    |> Repo.get!(id)
    |> Repo.preload([:author, :reviews, :yearly_sales])
  end

  def create_book(attrs \\ %{}) do
    case %Book{}
         |> Book.changeset(attrs)
         |> Repo.insert() do
      {:ok, book} = result ->
        # Invalidate caches that might be affected
        Cache.invalidate_book_cache(book.id)
        if book.author_id, do: Cache.invalidate_author_cache(book.author_id)
        result
      error -> error
    end
  end

  def update_book(%Book{} = book, attrs) do
    case book
         |> Book.changeset(attrs)
         |> Repo.update() do
      {:ok, updated_book} = result ->
        # Invalidate caches
        Cache.invalidate_book_cache(book.id)
        if book.author_id, do: Cache.invalidate_author_cache(book.author_id)
        result
      error -> error
    end
  end

  def delete_book(%Book{} = book) do
    case Repo.delete(book) do
      {:ok, deleted_book} = result ->
        # Invalidate caches
        Cache.invalidate_book_cache(book.id)
        if book.author_id, do: Cache.invalidate_author_cache(book.author_id)
        result
      error -> error
    end
  end

  def change_book(%Book{} = book, attrs \\ %{}) do
    Book.changeset(book, attrs)
  end

  ## Reviews

  def list_reviews do
    Review
    |> order_by([r], desc: r.inserted_at)
    |> Repo.all()
    |> Repo.preload([:book])
  end

  def get_review!(id) do
    Review
    |> Repo.get!(id)
    |> Repo.preload([:book])
  end

  def create_review(attrs \\ %{}) do
    case %Review{}
         |> Review.changeset(attrs)
         |> Repo.insert() do
      {:ok, review} = result ->
        if review.book_id, do: Cache.invalidate_review_cache(review.book_id)
        result
      error -> error
    end
  end

  def update_review(%Review{} = review, attrs) do
    case review
         |> Review.changeset(attrs)
         |> Repo.update() do
      {:ok, updated_review} = result ->
        if review.book_id, do: Cache.invalidate_review_cache(review.book_id)
        result
      error -> error
    end
  end

  def delete_review(%Review{} = review) do
    case Repo.delete(review) do
      {:ok, deleted_review} = result ->
        if review.book_id, do: Cache.invalidate_review_cache(review.book_id)
        result
      error -> error
    end
  end

  def change_review(%Review{} = review, attrs \\ %{}) do
    Review.changeset(review, attrs)
  end

  def list_top_books(limit \\ 10) do
    Cache.get_or_compute_top_books(limit, fn ->
      from(b in Book,
        left_join: r in assoc(b, :reviews),
        group_by: b.id,
        order_by: [desc: avg(r.score)],
        limit: ^limit,
        preload: [:author, :reviews]
      )
      |> Repo.all()
    end)
  end

  def list_top_selling_books() do
    Cache.get_or_compute_top_selling_books(fn ->
      from(b in Book,
        order_by: [desc: b.lifetime_sales],
        limit: 50,
        preload: [:author, :yearly_sales]
      )
      |> Repo.all()
    end)
  end

  def get_author_total_sales(author_id) do
    Cache.get_or_compute_author_total_sales(author_id, fn ->
      from(b in Book,
        where: b.author_id == ^author_id,
        select: sum(b.lifetime_sales)
      )
      |> Repo.one() || 0
    end)
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
    Cache.get_or_compute_yearly_sales(book_id, year, fn ->
      from(ys in BookApp.Catalog.YearlySale,
        where: ys.book_id == ^book_id and ys.year == ^year,
        select: ys.sales
      )
      |> Repo.one()
    end)
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
    case %BookApp.Catalog.YearlySale{}
         |> BookApp.Catalog.YearlySale.changeset(attrs)
         |> Repo.insert() do
      {:ok, yearly_sale} = result ->
        if yearly_sale.book_id, do: Cache.invalidate_yearly_sale_cache(yearly_sale.book_id)
        result
      error -> error
    end
  end

  def update_yearly_sale(%BookApp.Catalog.YearlySale{} = yearly_sale, attrs) do
    case yearly_sale
         |> BookApp.Catalog.YearlySale.changeset(attrs)
         |> Repo.update() do
      {:ok, updated_yearly_sale} = result ->
        if yearly_sale.book_id, do: Cache.invalidate_yearly_sale_cache(yearly_sale.book_id)
        result
      error -> error
    end
  end

  def delete_yearly_sale(%BookApp.Catalog.YearlySale{} = yearly_sale) do
    case Repo.delete(yearly_sale) do
      {:ok, deleted_yearly_sale} = result ->
        if yearly_sale.book_id, do: Cache.invalidate_yearly_sale_cache(yearly_sale.book_id)
        result
      error -> error
    end
  end

  def change_yearly_sale(%BookApp.Catalog.YearlySale{} = yearly_sale, attrs \\ %{}) do
    BookApp.Catalog.YearlySale.changeset(yearly_sale, attrs)
  end

  def get_book_review_scores(book_id) do
    Cache.get_or_compute_review_scores(book_id, fn ->
      from(r in Review,
        where: r.book_id == ^book_id,
        select: %{
          average_score: avg(r.score),
          total_reviews: count(r.id),
          scores_distribution: fragment("array_agg(?)", r.score)
        }
      )
      |> Repo.one()
    end)
  end
end
