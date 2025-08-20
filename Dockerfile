# syntax=docker/dockerfile:1
FROM hexpm/elixir:1.16.2-erlang-26.2.4-alpine-3.19.1 as build

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache build-base git npm sqlite-dev

# Set environment variables
ENV MIX_ENV=prod

# Install Hex + Rebar
RUN mix local.hex --force && mix local.rebar --force

# Copy mix files and install deps
COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy the rest of the app
COPY . .

# Compile assets
RUN mix assets.deploy

# Compile the app
RUN mix compile

# Build release
RUN mix release

# -- Release image --
FROM alpine:3.19.1 AS app
RUN apk add --no-cache openssl ncurses-libs sqlite-libs libstdc++ libgcc

WORKDIR /app

COPY --from=build /app/_build/prod/rel/book_app ./

ENV HOME=/app
ENV MIX_ENV=prod

CMD ["bin/book_app", "start"]