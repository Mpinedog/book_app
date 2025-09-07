defmodule BookApp.Search do
  @moduledoc """
  Search functionality using OpenSearch
  (Uses HTTPoison for direct HTTP calls)
  """

  alias BookApp.Catalog.Book
  alias BookApp.Repo
  import Ecto.Query

  @index "books"

  defp opensearch_url do
    System.get_env("OPENSEARCH_URL") || "http://localhost:9200"
  end

  @doc """
  Search books using OpenSearch with full-text search capabilities
  """
  def search_books(query, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)

    search_query = build_search_query(query, limit, offset)

    case post_to_opensearch("/#{@index}/_search", search_query) do
      {:ok, %{"hits" => %{"hits" => hits}}} ->
        book_ids = Enum.map(hits, fn hit -> hit["_source"]["id"] end)
        fetch_books_by_ids(book_ids)

      {:error, _} ->
        # Fallback to database search if OpenSearch fails
        fallback_search(query, limit)
    end
  end

  @doc """
  Index a single book in OpenSearch
  """
  def index_book(%Book{} = book) do
    book_with_preloads = Repo.preload(book, [:author, :reviews])
    document = BookApp.Search.BookStore.serialize(book_with_preloads)
    
    put_to_opensearch("/#{@index}/_doc/#{book.id}", document)
  end

  @doc """
  Remove a book from OpenSearch index
  """
  def delete_book_from_index(book_id) do
    delete_from_opensearch("/#{@index}/_doc/#{book_id}")
  end

  @doc """
  Rebuild the entire search index
  """
  def rebuild_index do
    # Delete existing index if it exists
    case delete_from_opensearch("/#{@index}") do
      {:ok, _} -> IO.puts("Deleted existing index")
      {:error, _} -> IO.puts("Index didn't exist or couldn't be deleted")
    end
    
    # Create new index with basic settings
    settings = %{
      "mappings" => %{
        "properties" => %{
          "id" => %{"type" => "integer"},
          "title" => %{"type" => "text", "analyzer" => "standard"},
          "summary" => %{"type" => "text", "analyzer" => "standard"},
          "author_name" => %{"type" => "text", "analyzer" => "standard"},
          "author_description" => %{"type" => "text", "analyzer" => "standard"},
          "published_on" => %{"type" => "date"},
          "lifetime_sales" => %{"type" => "integer"},
          "reviews" => %{
            "type" => "nested",
            "properties" => %{
              "body" => %{"type" => "text", "analyzer" => "standard"},
              "rating" => %{"type" => "integer"}
            }
          }
        }
      }
    }
    
    case put_to_opensearch("/#{@index}", settings) do
      {:ok, _} -> IO.puts("Index created successfully")
      {:error, error} -> IO.puts("Error creating index: #{inspect(error)}")
    end

    # Index all books
    books = Book
    |> preload([:author, :reviews])
    |> Repo.all()
    
    IO.puts("Indexing #{length(books)} books...")
    Enum.each(books, &index_book/1)
    IO.puts("Indexing completed!")
  end

  # Private functions for HTTP calls

  defp post_to_opensearch(path, body) do
    url = opensearch_url() <> path
    
    case Req.post(url, json: body) do
      {:ok, %Req.Response{status: status, body: response_body}} when status in 200..299 ->
        {:ok, response_body}
      {:ok, %Req.Response{body: response_body}} ->
        {:error, response_body}
      {:error, error} ->
        {:error, error}
    end
  end

  defp put_to_opensearch(path, body) do
    url = opensearch_url() <> path
    
    case Req.put(url, json: body) do
      {:ok, %Req.Response{status: status, body: response_body}} when status in 200..299 ->
        {:ok, response_body}
      {:ok, %Req.Response{body: response_body}} ->
        {:error, response_body}
      {:error, error} ->
        {:error, error}
    end
  end

  defp delete_from_opensearch(path) do
    url = opensearch_url() <> path
    
    case Req.delete(url) do
      {:ok, %Req.Response{status: status, body: response_body}} when status in 200..299 ->
        {:ok, response_body}
      {:ok, %Req.Response{body: response_body}} ->
        {:error, response_body}
      {:error, error} ->
        {:error, error}
    end
  end

  defp build_search_query(query, limit, offset) do
    %{
      "query" => %{
        "multi_match" => %{
          "query" => query,
          "fields" => [
            "title^2",
            "summary",
            "author_name^1.5",
            "author_description",
            "reviews.body"
          ],
          "type" => "best_fields",
          "fuzziness" => "AUTO"
        }
      },
      "highlight" => %{
        "fields" => %{
          "title" => %{},
          "summary" => %{},
          "author_name" => %{},
          "reviews.body" => %{}
        }
      },
      "size" => limit,
      "from" => offset,
      "_source" => ["id", "title", "summary", "author_name", "published_on", "lifetime_sales"]
    }
  end

  defp fetch_books_by_ids(book_ids) when is_list(book_ids) do
    Book
    |> where([b], b.id in ^book_ids)
    |> preload([:author, :reviews, :yearly_sales])
    |> Repo.all()
    |> Enum.sort_by(fn book -> 
      Enum.find_index(book_ids, &(&1 == book.id)) 
    end)
  end

  defp fallback_search(query, limit) do
    search_pattern = "%#{String.downcase(query)}%"

    Book
    |> join(:inner, [b], a in assoc(b, :author))
    |> where([b, a], 
      like(fragment("LOWER(?)", b.title), ^search_pattern) or
      like(fragment("LOWER(?)", b.summary), ^search_pattern) or
      like(fragment("LOWER(?)", a.name), ^search_pattern) or
      like(fragment("LOWER(?)", a.description), ^search_pattern)
    )
    |> limit(^limit)
    |> preload([:author, :reviews, :yearly_sales])
    |> Repo.all()
  end
end
