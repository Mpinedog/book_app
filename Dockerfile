# syntax=docker/dockerfile:1
FROM hexpm/elixir:1.16.2-erlang-26.2.4-alpine-3.19.1 as build

WORKDIR /app
RUN apk add --no-cache build-base git npm sqlite-dev

# Set environment (can be overridden)
ARG MIX_ENV=prod
ENV MIX_ENV=${MIX_ENV}
ENV HEX_HTTP_CONCURRENCY=1
ENV HEX_HTTP_TIMEOUT=120

RUN mix local.hex --force && mix local.rebar --force

# Copy dep files first for better caching
COPY mix.exs mix.lock ./
COPY config config

# Install dependencies based on environment
RUN if [ "$MIX_ENV" = "prod" ]; then \
        mix deps.get --only prod; \
    else \
        mix deps.get; \
    fi

RUN mix deps.compile

# Copy the rest
COPY . .

# Build based on environment
RUN if [ "$MIX_ENV" = "prod" ]; then \
        mix assets.deploy && \
        mix compile && \
        mix release; \
    else \
        mix compile; \
    fi

# --- release image for production ---
FROM alpine:3.19.1 AS prod
RUN apk add --no-cache openssl ncurses-libs sqlite-libs libstdc++ libgcc

WORKDIR /app
COPY --from=build /app/_build/prod/rel/book_app ./

ENV HOME=/app
ENV MIX_ENV=prod

CMD bin/book_app eval "BookApp.Release.migrate_and_seed()" && \
	echo "\nApp running at http://localhost:4000\n" && \
	bin/book_app start

# --- development image ---
FROM build AS dev
ENV MIX_ENV=dev
ENV PORT=4000

# Make sure we have development dependencies
RUN mix deps.get

EXPOSE 4000

CMD ["mix", "phx.server"]
