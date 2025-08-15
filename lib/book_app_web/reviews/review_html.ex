defmodule BookAppWeb.ReviewHTML do
  use BookAppWeb, :html

  embed_templates "templates/*"

  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :books, :list, required: true

  def review_form(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto mt-8 card bg-base-100 shadow-xl">
      <div class="card-body">
        <.simple_form :let={f} for={@changeset} action={@action} class="space-y-8">
          <.input field={f[:book_id]} type="select" label="Book" prompt="Choose a book" options={Enum.map(@books, &{&1.title, &1.id})} required />
          <.input field={f[:score]} type="number" label="Score (1-5)" min="1" max="5" required />
          <.input field={f[:body]} type="textarea" label="Review" />
          <.input field={f[:upvotes]} type="number" label="Upvotes" min="0" value="0" />
          <:actions>
            <.button phx-disable-with="Saving...">Save Review</.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end
end
