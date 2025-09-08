defmodule BookApp.Cache do
  @moduledoc """
  Redis-based cache system for book application.
  """

  require Logger

  # Cache TTL configurations
  @review_scores_ttl :timer.hours(2)
  @author_info_ttl :timer.hours(4)
  @book_queries_ttl :timer.minutes(30)
  @top_books_ttl :timer.minutes(15)

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(_opts \\ []) do
    redis_url = Application.get_env(:book_app, :redis_url, "redis://redis:6379")

    case Redix.start_link(redis_url, name: :redis_connection) do
      {:ok, pid} ->
        Logger.info("Redis cache started successfully at #{redis_url}")
        {:ok, pid}
      {:error, reason} ->
        Logger.warning("Redis not available, running without cache: #{inspect(reason)}")
        {:ok, :no_redis}
    end
  end

  def safe_get(key, fallback_fn \\ fn -> nil end) do
    case get_from_redis(key) do
      nil -> fallback_fn.()
      value -> value
    end
  rescue
    error ->
      Logger.warning("Cache get failed for #{key}: #{inspect(error)}")
      fallback_fn.()
  end

  def safe_put(key, value, opts \\ []) do
    ttl = Keyword.get(opts, :ttl, :timer.hours(1))
    put_to_redis(key, value, ttl)
  rescue
    error ->
      Logger.warning("Cache put failed for #{key}: #{inspect(error)}")
      :error
  end

  def safe_delete(key) do
    delete_from_redis(key)
  rescue
    error ->
      Logger.warning("Cache delete failed for #{key}: #{inspect(error)}")
      :error
  end

  # Redis operations
  defp get_from_redis(key) do
    case Redix.command(:redis_connection, ["GET", key]) do
      {:ok, nil} -> nil
      {:ok, value} ->
        case Jason.decode(value) do
          {:ok, decoded} -> decoded
          _ -> nil
        end
      {:error, _} -> nil
    end
  end

  defp put_to_redis(key, value, ttl) do
    ttl_seconds = div(ttl, 1000)

    case Jason.encode(value) do
      {:ok, serialized} ->
        case Redix.command(:redis_connection, ["SETEX", key, ttl_seconds, serialized]) do
          {:ok, "OK"} -> :ok
          _ -> :error
        end
      _ -> :error
    end
  end

  defp delete_from_redis(key) do
    case Redix.command(:redis_connection, ["DEL", key]) do
      {:ok, _} -> :ok
      {:error, _} -> :error
    end
  end

  # Review scores caching
  def get_or_compute_review_scores(book_id, compute_fn) do
    key = "review_scores:#{book_id}"

    safe_get(key, fn ->
      Logger.info("Computing review scores for book #{book_id} [Redis]")
      result = compute_fn.()
      safe_put(key, result, ttl: @review_scores_ttl)
      result
    end)
  end

  # Author information caching
  def get_or_compute_author_info(author_id, compute_fn) do
    key = "author_info:#{author_id}"

    safe_get(key, fn ->
      Logger.info("Computing author info for author #{author_id} [Redis]")
      result = compute_fn.()
      safe_put(key, result, ttl: @author_info_ttl)
      result
    end)
  end

  # Common queries caching
  def get_or_compute_top_books(limit, compute_fn) do
    key = "top_books:#{limit}"

    safe_get(key, fn ->
      Logger.info("Computing top books with limit #{limit} [Redis]")
      result = compute_fn.()
      safe_put(key, result, ttl: @top_books_ttl)
      result
    end)
  end

  def get_or_compute_top_selling_books(compute_fn) do
    key = "top_selling_books"

    safe_get(key, fn ->
      Logger.info("Computing top selling books [Redis]")
      result = compute_fn.()
      safe_put(key, result, ttl: @top_books_ttl)
      result
    end)
  end

  def get_or_compute_book_search(search_term, compute_fn) do
    search_hash = :crypto.hash(:md5, search_term) |> Base.encode16()
    key = "book_search:#{search_hash}"

    safe_get(key, fn ->
      Logger.info("Computing book search for term: #{search_term} [Redis]")
      result = compute_fn.()
      safe_put(key, result, ttl: @book_queries_ttl)
      result
    end)
  end

  def get_or_compute_yearly_sales(book_id, year, compute_fn) do
    key = "yearly_sales:#{book_id}:#{year}"

    safe_get(key, fn ->
      Logger.info("Computing yearly sales for book #{book_id}, year #{year} [Redis]")
      result = compute_fn.()
      safe_put(key, result, ttl: @author_info_ttl)
      result
    end)
  end

  def get_or_compute_author_total_sales(author_id, compute_fn) do
    key = "author_total_sales:#{author_id}"

    safe_get(key, fn ->
      Logger.info("Computing total sales for author #{author_id} [Redis]")
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
    Logger.info("Invalidated cache for book #{book_id} [Redis]")
  end

  def invalidate_review_cache(book_id) do
    keys_to_delete = [
      "review_scores:#{book_id}",
      "top_books:10",
      "top_books:20"
    ]

    Enum.each(keys_to_delete, &safe_delete/1)
    Logger.info("Invalidated review cache for book #{book_id} [Redis]")
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
    Logger.info("Invalidated cache for author #{author_id} [Redis]")
  end

  def invalidate_yearly_sale_cache(book_id) do
    keys_to_delete = [
      "top_selling_books"
    ]

    Enum.each(keys_to_delete, &safe_delete/1)
    Logger.info("Invalidated yearly sale cache for book #{book_id} [Redis]")
  end
end
