
# BookApp

BookApp is a Phoenix application with full-text search powered by OpenSearch, supporting fuzzy matching, weighted results, and automatic index synchronization.

---

## Table of Contents

- [Features](#features)
- [Setup](#setup)
  - [Local Development](#local-development)
  - [Docker Compose Scenarios](#docker-compose-scenarios)
- [Search Index Management](#search-index-management)
- [Mock Data (Seeds)](#mock-data-seeds)
- [Environment Variables](#environment-variables)
- [Notes](#notes)

---

## Features

- Full-text search across book titles, summaries, author names/descriptions, and review content
- Fuzzy matching for typos
- Weighted results (titles and author names have higher relevance)
- Automatic index sync on create/update/delete
- Fallback to DB search if OpenSearch is unavailable

---

## Setup

### Local Development

1. **Start OpenSearch (Docker):**
   ```bash
   docker run -d --name opensearch -p 9200:9200 -p 9600:9600 \
     -e "discovery.type=single-node" \
     -e "DISABLE_SECURITY_PLUGIN=true" \
     opensearchproject/opensearch:2.11.1
   ```

2. **Set up the search index:**
   ```bash
   mix search.setup
   # To rebuild the index:
   mix search.setup --rebuild
   ```

3. **Prepare the database and seed data:**
   ```bash
   mix ecto.create
   mix ecto.migrate
   mix run priv/repo/seeds.exs
   ```

4. **Start the Phoenix server:**
   ```bash
   mix phx.server
   ```

---

### Docker Compose Scenarios



You can run BookApp in several different configurations using Docker Compose. Choose the scenario that fits your needs:

#### 1. App + DB

Runs the Phoenix application and the database (SQLite). This is the minimal setup for local development.

```bash
docker compose -f docker-compose.app-db.yml up --build
```

#### 2. App + DB + OpenSearch

Runs the Phoenix application, the database, and OpenSearch for full-text search capabilities.

```bash
docker compose -f docker-compose.app-db-opensearch.yml up --build
```

#### 3. App + DB + Reverse Proxy

Runs the Phoenix application, the database, and a reverse proxy (Caddy) for routing and static asset serving.

```bash
docker compose -f docker-compose.app-db-proxy.yml up --build
```

- Visit [http://localhost:2015](http://localhost:2015) for the proxy’s exposed port.

#### 4. App + DB + OpenSearch + Reverse Proxy

Runs the Phoenix application, the database, OpenSearch, and a reverse proxy (Caddy) for a full production-like stack.

```bash
docker compose -f docker-compose.app-db-opensearch-proxy.yml up --build
```

#### 5. App + DB + Cache (Redis)

Runs the Phoenix application, the database, and a Redis cache for development or testing caching strategies.

```bash
docker compose -f docker-compose-db-cache.yml up --build
```

#### 6. App + DB + OpenSearch + Reverse Proxy + Cache (Redis)

Runs the Phoenix application, the database, OpenSearch, a reverse proxy (Caddy), and Redis cache for a comprehensive stack with search, caching, and proxying.

```bash
docker compose -f docker-compose.app-db-proxy-cache-opensearch.yml up --build
```

---

- Each scenario will build the app, run migrations, seed the database, and start the server (on port 4000 or behind the proxy).
- Visit [http://localhost:4000](http://localhost:4000) or the proxy’s exposed port as appropriate [http://localhost:2015](http://localhost:2015).
- You can customize environment variables as needed for each scenario.

---

## Search Index Management

- **Set up or rebuild the search index:**
  ```bash
  mix search.setup
  mix search.setup --rebuild
  ```

---

## Mock Data (Seeds)

- 50 authors
- 300 books
- 1–10 reviews per book
- ≥5 years of sales per book (from publication year)
- `books.lifetime_sales` auto-updated

**To generate mock data:**
```bash
mix ecto.create
mix ecto.migrate
mix run priv/repo/seeds.exs
```

---

## Environment Variables

- `OPENSEARCH_URL` — OpenSearch URL (default: `http://localhost:9200`)
- `SECRET_KEY_BASE` — Required for Phoenix. Generate with:
  ```bash
  mix phx.gen.secret
  ```
- `DATABASE_PATH` — SQLite file location (default set in Docker Compose)

---

## Notes

- App and DB run in separate containers, sharing a Docker volume for SQLite.
- On container startup, migrations and seeds run automatically.
- For OpenShift, convert Docker Compose to Kubernetes/OpenShift manifests using [Kompose](https://kompose.io/).

