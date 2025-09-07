defmodule BookApp.Search.BookStore do
  @behaviour Elasticsearch.Store

  alias BookApp.Catalog.Book
  alias BookApp.Repo
  import Ecto.Query

  @impl true
  def stream(schema) do
    case schema do
      Book ->
        Book
        |> preload([:author, :reviews])
        |> Repo.stream()
    end
  end

  @impl true
  def transaction(fun) do
    {:ok, result} = Repo.transaction(fun, timeout: :infinity)
    result
  end

  @impl true
  def load(schema, offset, limit) do
    case schema do
      Book ->
        Book
        |> preload([:author, :reviews])
        |> offset(^offset)
        |> limit(^limit)
        |> Repo.all()
    end
  end

  @impl true
  def serialize(book = %Book{}) do
    %{
      id: book.id,
      title: book.title,
      summary: book.summary,
      author_name: book.author.name,
      author_description: book.author.description,
      published_on: book.published_on,
      lifetime_sales: book.lifetime_sales,
      reviews: Enum.map(book.reviews, fn review ->
        %{
          body: review.body,
          score: review.score
        }
      end)
    }
  end
end
