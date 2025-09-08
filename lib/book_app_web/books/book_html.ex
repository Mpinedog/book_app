defmodule BookAppWeb.BookHTML do
  use BookAppWeb, :html

  import BookAppWeb.CoreComponents

  embed_templates "templates/*"

  @doc """
  Formats a number with thousand separators.
  """
  def format_number(number) when is_integer(number) do
    number
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
  end

  @doc """
  Renders a book form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :authors, :list, required: true

  def book_form(assigns) do
    ~H"""
    <.simple_form :let={f} for={@changeset} action={@action} class="space-y-8" enctype="multipart/form-data">
      <.input field={f[:title]} type="text" label="Title" required />
      <.input field={f[:summary]} type="textarea" label="Summary" required />
      <.input field={f[:published_on]} type="date" label="Publication Date" required />
      <.input field={f[:author_id]} type="select" label="Author" required options={Enum.map(@authors, &{&1.name, &1.id})} />
      <.input field={f[:cover_image]} type="file" label="Book Cover" />


      <:actions>
        <.button type="submit" class="btn-primary">Save Book</.button>
      </:actions>
    </.simple_form>
    """
  end

  def average_rating(book) do
    if length(book.reviews) > 0 do
      total = Enum.sum(Enum.map(book.reviews, & &1.score))
      total / length(book.reviews)
    else
      nil
    end
  end

  def highest_rated_review(book) do
    if Ecto.assoc_loaded?(book.reviews) and length(book.reviews) > 0 do
      book.reviews
      |> Enum.filter(& &1.score)
      |> Enum.max_by(fn review -> {review.score, review.upvotes || 0} end, fn -> nil end)
    else
      nil
    end
  end

  def lowest_rated_review(book) do
    if Ecto.assoc_loaded?(book.reviews) and length(book.reviews) > 0 do
      book.reviews
      |> Enum.filter(& &1.score)
      |> Enum.min_by(fn review -> {review.score, -(review.upvotes || 0)} end, fn -> nil end)
    else
      nil
    end
  end

  def author_total_sales(author) do
    if Ecto.assoc_loaded?(author.books) do
      author.books
      |> Enum.map(& &1.lifetime_sales || 0)
      |> Enum.sum()
    else
      BookApp.Catalog.get_author_total_sales(author.id)
    end
  end

  def author_book_percentage(book) do
    total_sales = author_total_sales(book.author)
    if total_sales > 0 do
      percentage = (book.lifetime_sales / total_sales) * 100
      Float.round(percentage, 1)
    else
      0
    end
  end

  def was_top_5_at_publication?(book) do
    publication_year = book.published_on.year

    # Get top 5 books by sales in the publication year
    top_5_sales_that_year = BookApp.Catalog.get_top_5_books_by_year(publication_year)

    # Check if this book's publication year sales were in top 5
    case get_book_sales_for_year(book, publication_year) do
      nil -> false
      book_sales -> book_sales in top_5_sales_that_year
    end
  end

  defp get_book_sales_for_year(book, year) do
    if Ecto.assoc_loaded?(book.yearly_sales) do
      book.yearly_sales
      |> Enum.find(&(&1.year == year))
      |> case do
        nil -> nil
        yearly_sale -> yearly_sale.sales
      end
    else
      # Fallback if yearly_sales not preloaded
      BookApp.Catalog.get_book_sales_for_year(book.id, year)
    end
  end

  def total_combined_sales(books) do
    books
    |> Enum.map(& &1.lifetime_sales || 0)
    |> Enum.sum()
  end

  def count_top_5_books(books) do
    books |> Enum.count(&was_top_5_at_publication?/1)
  end
end
