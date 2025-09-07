defmodule Mix.Tasks.Search.Setup do
  @moduledoc """
  Sets up OpenSearch index for BookApp.

  ## Examples

      mix search.setup
      mix search.setup --rebuild

  """
  @shortdoc "Sets up the OpenSearch index"

  use Mix.Task

  alias BookApp.Search

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _} = OptionParser.parse!(args, strict: [rebuild: :boolean])

    if opts[:rebuild] do
      Mix.shell().info("Rebuilding OpenSearch index...")
      Search.rebuild_index()
      Mix.shell().info("OpenSearch index rebuilt successfully!")
    else
      Mix.shell().info("Setting up OpenSearch index...")
      setup_index()
      Mix.shell().info("OpenSearch index setup completed!")
    end
  end

  defp setup_index do
    # Create index if it doesn't exist
    case Elasticsearch.head(:default, "/books") do
      {:ok, _} -> 
        Mix.shell().info("Index already exists")
      {:error, _} -> 
        Mix.shell().info("Creating new index...")
        Search.rebuild_index()
    end
  end
end
