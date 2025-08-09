defmodule BookAppWeb.BookHTML do
  use BookAppWeb, :html

  import BookAppWeb.CoreComponents

  embed_templates "book_html/*"

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
    <.simple_form :let={f} for={@changeset} action={@action} class="space-y-8">
      <.input field={f[:title]} type="text" label="Title" required />
      <.input field={f[:summary]} type="textarea" label="Summary" required />
      <.input field={f[:published_on]} type="date" label="Publication Date" required />
      <.input field={f[:author_id]} type="select" label="Author" required options={Enum.map(@authors, &{&1.name, &1.id})} />

      <:actions>
        <.button type="submit" class="btn-primary">Save Book</.button>
      </:actions>
    </.simple_form>
    """
  end
end
