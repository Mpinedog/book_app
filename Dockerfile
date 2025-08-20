# syntax=docker/dockerfile:1
FROM hexpm/elixir:1.16.2-erlang-26.2.4-alpine-3.19.1 as build

WORKDIR /app
RUN apk add --no-cache build-base git npm sqlite-dev

ENV MIX_ENV=prod

RUN mix local.hex --force && mix local.rebar --force

# Copy dep files first for better caching
COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy the rest
COPY . .

# Build assets (prod)
RUN mix assets.deploy

# Compile & build release
RUN mix compile
RUN mix release

# --- release image ---
FROM alpine:3.19.1 AS app
RUN apk add --no-cache openssl ncurses-libs sqlite-libs libstdc++ libgcc

WORKDIR /app
COPY --from=build /app/_build/prod/rel/book_app ./

ENV HOME=/app
ENV MIX_ENV=prod

CMD bin/book_app eval "BookApp.Release.migrate_and_seed()" && bin/book_app start
