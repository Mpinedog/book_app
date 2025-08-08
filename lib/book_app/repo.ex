defmodule BookApp.Repo do
  use Ecto.Repo,
    otp_app: :book_app,
    adapter: Ecto.Adapters.SQLite3
end
