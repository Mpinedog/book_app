defmodule BookAppWeb.AuthorHTML do
  use BookAppWeb, :html

  embed_templates "templates/*"

  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def author_form(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto mt-8 card bg-base-100 shadow-xl">
      <div class="card-body">
        <.simple_form :let={f} for={@changeset} action={@action} class="space-y-8">
          <.input field={f[:name]} type="text" label="Name" required />
          <.input field={f[:description]} type="textarea" label="Description" />
          <.input field={f[:birth_date]} type="date" label="Birth Date" required />
          <.input field={f[:country]} type="text" label="Country" />
          <:actions>
            <.button phx-disable-with="Saving...">Save Author</.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end
end
