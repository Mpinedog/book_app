defmodule Mix.Tasks.Phx.Setup do
  use Mix.Task

  @shortdoc "Fetches deps, creates & migrates DB, and runs seeds."
  def run(_args) do
    Mix.Task.run("deps.get")
    Mix.Task.run("ecto.setup")
  end
end
