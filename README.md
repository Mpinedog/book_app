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
````

## Docker & Containerized Setup

You can run BookApp and its database in containers using Docker and Docker Compose. This setup is also compatible with Red Hat OpenShift.

### Build and Run with Docker Compose

1. Build and start the containers:
   ```bash
   docker compose up --build
   ```
   This will build the Phoenix app image, run database migrations, seed the database, and start the server on port 4000.

2. Visit [`localhost:4000`](http://localhost:4000) in your browser.

### Environment Variables
- `SECRET_KEY_BASE` must be set to a secure value (see docker-compose.yml for an example). Generate one with:
  ```bash
  mix phx.gen.secret
  ```
- `DATABASE_PATH` is set by default for the SQLite file location.

### Notes
- The database and app run in separate containers, sharing a Docker volume for the SQLite file.
- On container startup, migrations and seeds are run automatically.
- For OpenShift, you can convert the Docker Compose setup to Kubernetes/OpenShift manifests using [Kompose](https://kompose.io/).

