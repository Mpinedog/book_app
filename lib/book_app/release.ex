defmodule BookApp.Release do
  @app :book_app

  def migrate_and_seed do
    # Start the app and its repo
    {:ok, _} = Application.ensure_all_started(@app)
    path = Application.app_dir(@app, "priv/repo/migrations")
    Ecto.Migrator.run(BookApp.Repo, path, :up, all: true)

    # Run seeds if present
    seed_script = Application.app_dir(@app, "priv/repo/seeds.exs")
    if File.exists?(seed_script), do: Code.eval_file(seed_script)

    # Setup OpenSearch index automatically
    setup_search_index()
  end

  defp setup_search_index do
    IO.puts("Setting up OpenSearch index...")
    
    # Wait a bit for OpenSearch to be ready
    Process.sleep(5000)
    
    # Setup the search index
    try do
      BookApp.Search.rebuild_index()
      IO.puts("OpenSearch index setup completed!")
    rescue
      error -> 
        IO.puts("Warning: Could not setup OpenSearch index: #{inspect(error)}")
        IO.puts("Search functionality will fall back to database search.")
    end
  end

  # Removed wait_for_opensearch function - simplified approach
end
