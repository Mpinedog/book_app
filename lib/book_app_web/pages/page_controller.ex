defmodule BookAppWeb.PageController do
  use BookAppWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
