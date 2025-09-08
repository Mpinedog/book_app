
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

Choose the scenario that fits your needs:

#### 1. App + DB

```bash
docker compose -f docker-compose.app-db.yml up --build
```

#### 2. App + DB + OpenSearch

```bash
docker compose -f docker-compose.app-db-opensearch.yml up --build
```

#### 3. App + DB + Reverse Proxy

```bash
docker compose -f docker-compose.app-db-proxy.yml up --build
```

- This will build the app, run migrations, seed the DB, and start the server (port 4000 or behind the proxy).
- Visit [http://localhost:4000](http://localhost:4000) or the proxy’s exposed port.

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

