defmodule BookApp.Authors do
	@moduledoc """
	The Authors context.
	"""

	import Ecto.Query, warn: false
	alias BookApp.Repo
	alias BookApp.Authors.Author

	@doc """
	Returns the list of authors.
	"""
	def list_authors do
		Repo.all(Author)
	end

	@doc """
	Gets a single author.
	"""
	def get_author!(id), do: Repo.get!(Author, id)

	def create_author(attrs \\ %{}) do
		%Author{}
		|> Author.changeset(attrs)
		|> Repo.insert()
	end

	def update_author(%Author{} = author, attrs) do
		author
		|> Author.changeset(attrs)
		|> Repo.update()
	end

	def delete_author(%Author{} = author) do
		Repo.delete(author)
	end
end
