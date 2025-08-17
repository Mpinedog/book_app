defmodule BookAppWeb.Router do
  use BookAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BookAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BookAppWeb do
    pipe_through :browser

    get "/", PageController, :home

    get "/books/search", BookController, :search
    resources "/books", BookController do
      resources "/yearly_sales", YearlySalesController, except: [:show]
  end
    resources "/authors", AuthorController
    resources "/reviews", ReviewController

    get "/top_books", BookController, :top_books
    get "/top_selling_books", BookController, :top_selling_books

  end

  # Other scopes may use custom stacks.
  # scope "/api", BookAppWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:book_app, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BookAppWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
