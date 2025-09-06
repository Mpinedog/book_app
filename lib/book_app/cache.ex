defmodule BookApp.Cache do
  @moduledoc """
  Simple ETS-based cache system with graceful fallback.
  Application can run without cache functionality.
  """

  require Logger

  # Cache TTL configurations
  @review_scores_ttl :timer.hours(2)
  @author_info_ttl :timer.hours(4)
  @book_queries_ttl :timer.minutes(30)
  @top_books_ttl :timer.minutes(15)

  def start_link(_opts \\ []) do
    case :ets.new(:book_app_cache, [:set, :public, :named_table]) do
      :book_app_cache ->
        Logger.info("ETS cache started successfully")
        {:ok, self()}
      error ->
        Logger.error("Failed to start ETS cache: #{inspect(error)}")
        {:error, error}
    end
  end

  # Safe cache operations
  def safe_get(key, fallback_fn \\ fn -> nil end) do
    if cache_available?() do
      case get_from_ets(key) do
        nil -> fallback_fn.()
        value -> value
      end
    else
      fallback_fn.()
    end
  rescue
    error ->
      Logger.warning("Cache get failed for #{key}: #{inspect(error)}")
      fallback_fn.()
  end

  def safe_put(key, value, opts \\ []) do
    if cache_available?() do
      ttl = Keyword.get(opts, :ttl, :timer.hours(1))
      put_to_ets(key, value, ttl)
    else
      :cache_unavailable
    end
  rescue
    error ->
      Logger.warning("Cache put failed for #{key}: #{inspect(error)}")
      :cache_unavailable
  end

  def safe_delete(key) do
    if cache_available?() do
      delete_from_ets(key)
    else
      :cache_unavailable
    end
  rescue
    error ->
      Logger.warning("Cache delete failed for #{key}: #{inspect(error)}")
      :cache_unavailable
  end

  # Check if cache system is available
  defp cache_available? do
    :ets.whereis(:book_app_cache) != :undefined
  end

  # ETS operations
  defp get_from_ets(key) do
    case :ets.lookup(:book_app_cache, key) do
      [{^key, value, expires_at}] ->
        if System.system_time(:millisecond) < expires_at do
          value
        else
          :ets.delete(:book_app_cache, key)
          nil
        end
      [] ->
        nil
    end
  end

  defp put_to_ets(key, value, ttl) do
    expires_at = System.system_time(:millisecond) + ttl
    :ets.insert(:book_app_cache, {key, value, expires_at})
    :ok
  end

  defp delete_from_ets(key) do
    :ets.delete(:book_app_cache, key)
    :ok
  end

  # Review scores caching
  def get_or_compute_review_scores(book_id, compute_fn) do
    key = "review_scores:#{book_id}"

    safe_get(key, fn ->
      Logger.info("Computing review scores for book #{book_id}")
      result = compute_fn.()
      safe_put(key, result, ttl: @review_scores_ttl)
      result
    end)
  end

  # Author information caching
  def get_or_compute_author_info(author_id, compute_fn) do
    key = "author_info:#{author_id}"

    safe_get(key, fn ->
      Logger.info("Computing author info for author #{author_id}")
      result = compute_fn.()
      safe_put(key, result, ttl: @author_info_ttl)
      result
    end)
  end

  # Common queries caching
  def get_or_compute_top_books(limit, compute_fn) do
    key = "top_books:#{limit}"

    safe_get(key, fn ->
      Logger.info("Computing top books with limit #{limit}")
      result = compute_fn.()
      safe_put(key, result, ttl: @top_books_ttl)
      result
    end)
  end

  def get_or_compute_top_selling_books(compute_fn) do
    key = "top_selling_books"

    safe_get(key, fn ->
      Logger.info("Computing top selling books")
      result = compute_fn.()
      safe_put(key, result, ttl: @top_books_ttl)
      result
    end)
  end

  def get_or_compute_book_search(search_term, compute_fn) do
    search_hash = :crypto.hash(:md5, search_term) |> Base.encode16()
    key = "book_search:#{search_hash}"

    safe_get(key, fn ->
      Logger.info("Computing book search for term: #{search_term}")
      result = compute_fn.()
      safe_put(key, result, ttl: @book_queries_ttl)
      result
    end)
  end

  def get_or_compute_yearly_sales(book_id, year, compute_fn) do
    key = "yearly_sales:#{book_id}:#{year}"

    safe_get(key, fn ->
      Logger.info("Computing yearly sales for book #{book_id}, year #{year}")
      result = compute_fn.()
      safe_put(key, result, ttl: @author_info_ttl)
      result
    end)
  end

  def get_or_compute_author_total_sales(author_id, compute_fn) do
    key = "author_total_sales:#{author_id}"

    safe_get(key, fn ->
      Logger.info("Computing total sales for author #{author_id}")
      result = compute_fn.()
      safe_put(key, result, ttl: @author_info_ttl)
      result
    end)
  end

  # Cache invalidation methods
  def invalidate_book_cache(book_id) do
    keys_to_delete = [
      "review_scores:#{book_id}",
      "top_books:10",
      "top_books:20",
      "top_selling_books"
    ]

    Enum.each(keys_to_delete, &safe_delete/1)
    Logger.info("Invalidated cache for book #{book_id}")
  end

  def invalidate_review_cache(book_id) do
    keys_to_delete = [
      "review_scores:#{book_id}",
      "top_books:10",
      "top_books:20"
    ]

    Enum.each(keys_to_delete, &safe_delete/1)
    Logger.info("Invalidated review cache for book #{book_id}")
  end

  def invalidate_author_cache(author_id) do
    keys_to_delete = [
      "author_info:#{author_id}",
      "author_total_sales:#{author_id}",
      "top_books:10",
      "top_books:20",
      "top_selling_books"
    ]

    Enum.each(keys_to_delete, &safe_delete/1)
    Logger.info("Invalidated cache for author #{author_id}")
  end

  def invalidate_yearly_sale_cache(book_id) do
    keys_to_delete = [
      "top_selling_books"
    ]

    Enum.each(keys_to_delete, &safe_delete/1)
    Logger.info("Invalidated yearly sale cache for book #{book_id}")
  end
end
