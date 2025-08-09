# BookApp

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Mock Data (seeds)
Generación de datos procedurales conforme a la pauta:

- 50 autores
- 300 libros
- 1 a 10 reseñas por libro
- ≥ 5 años de ventas por libro (desde el año de publicación)
- `books.lifetime_sales` se actualiza con la suma de las ventas anuales

**Cómo ejecutar:**
```bash
mix ecto.create
mix ecto.migrate
mix run priv/repo/seeds.exs

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
