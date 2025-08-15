
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
    %Book{}
    |> Book.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a book.
  """
  def update_book(%Book{} = book, attrs) do
    book
    |> Book.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a book.
  """
  def delete_book(%Book{} = book) do
    Repo.delete(book)
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
    %Review{}
    |> Review.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a review.
  """
  def update_review(%Review{} = review, attrs) do
    review
    |> Review.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a review.
  """
  def delete_review(%Review{} = review) do
    Repo.delete(review)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking review changes.
  """
  def change_review(%Review{} = review, attrs \\ %{}) do
    Review.changeset(review, attrs)
  end
end
