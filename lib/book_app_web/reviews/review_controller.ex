defmodule BookAppWeb.ReviewController do
  use BookAppWeb, :controller

  alias BookApp.Catalog
  alias BookApp.Catalog.Review

  def index(conn, _params) do
    reviews = Catalog.list_reviews()
    render(conn, :index, reviews: reviews)
  end

  def show(conn, %{"id" => id}) do
    review = Catalog.get_review!(id)
    render(conn, :show, review: review)
  end

  def new(conn, _params) do
    changeset = Catalog.change_review(%Review{})
    books = Catalog.list_books()
    render(conn, :new, changeset: changeset, books: books, action: ~p"/reviews")
  end

  def create(conn, %{"review" => review_params}) do
    case Catalog.create_review(review_params) do
      {:ok, review} ->
        conn
        |> put_flash(:info, "Review created successfully.")
        |> redirect(to: ~p"/reviews/#{review.id}")
      {:error, changeset} ->
        books = Catalog.list_books()
        render(conn, :new, changeset: changeset, books: books, action: ~p"/reviews")
    end
  end

  def edit(conn, %{"id" => id}) do
    review = Catalog.get_review!(id)
    changeset = Catalog.change_review(review)
    books = Catalog.list_books()
    render(conn, :edit, review: review, changeset: changeset, books: books, action: ~p"/reviews/#{review.id}")
  end

  def update(conn, %{"id" => id, "review" => review_params}) do
    review = Catalog.get_review!(id)
    case Catalog.update_review(review, review_params) do
      {:ok, review} ->
        conn
        |> put_flash(:info, "Review updated successfully.")
        |> redirect(to: ~p"/reviews/#{review.id}")
      {:error, changeset} ->
        books = Catalog.list_books()
        render(conn, :edit, review: review, changeset: changeset, books: books, action: ~p"/reviews/#{review.id}")
    end
  end

  def delete(conn, %{"id" => id}) do
    review = Catalog.get_review!(id)
    {:ok, _review} = Catalog.delete_review(review)
    conn
    |> put_flash(:info, "Review deleted successfully.")
    |> redirect(to: ~p"/reviews")
  end
end
