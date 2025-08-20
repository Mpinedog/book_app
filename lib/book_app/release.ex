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
  end
end
