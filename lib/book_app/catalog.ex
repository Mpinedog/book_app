defmodule BookApp.Catalog do
  @moduledoc """
  The Catalog context.
  """

  import Ecto.Query, warn: false
  alias BookApp.Repo
  alias BookApp.Catalog.Book

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
end
