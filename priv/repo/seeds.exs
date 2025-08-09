# priv/repo/seeds.exs
# Procedural mock data:
# - 50 authors
# - 300 books
# - 1..10 reviews per book
# - ≥ 5 years of sales per book (contiguos desde el año de publicación)

alias BookApp.Repo
alias BookApp.Authors.Author
alias BookApp.Catalog.{Book, Review, YearlySale}

# Asegura Faker
{:ok, _} = Application.ensure_all_started(:faker)

# (opcional) semilla p/ aleatoriedad reproducible
:rand.seed(:exsss, {101, 202, 303})

# -------- Helpers --------

rand_date = fn year_min, year_max ->
  year = Enum.random(year_min..year_max)
  month = Enum.random(1..12)

  day =
    case month do
      2 -> Enum.random(1..28)
      4 -> Enum.random(1..30)
      6 -> Enum.random(1..30)
      9 -> Enum.random(1..30)
      11 -> Enum.random(1..30)
      _ -> Enum.random(1..31)
    end

  Date.new!(year, month, day)
end

# evita duplicados en authors.name (por unique_index)
unique_name = fn idx ->
  base = Faker.Person.name()
  "#{base} ##{idx}"
end

# generador simple de títulos (2–4 palabras capitalizadas)
fake_title = fn ->
  Faker.Lorem.words(Enum.random(2..4))
  |> Enum.map(&String.capitalize/1)
  |> Enum.join(" ")
end

# -------- Inserción de datos --------

Repo.transaction(fn ->
  IO.puts("==> Generando autores...")
  author_ids =
    1..50
    |> Enum.map(fn i ->
      %Author{
        name: unique_name.(i),
        birth_date: rand_date.(1940, 1995),
        country: Faker.Address.country(),
        description: Faker.Lorem.paragraph()
      }
      |> Repo.insert!()
      |> Map.fetch!(:id)
    end)

  IO.puts("==> Generando libros + reseñas + ventas por año...")
  1..300
  |> Enum.each(fn i ->
    author_id = Enum.random(author_ids)
    published_on = rand_date.(1980, 2024)

    book =
      %Book{
        title: "#{fake_title.()} (#{i})",
        summary: Faker.Lorem.paragraphs(2..4) |> Enum.join("\n\n"),
        published_on: published_on,
        author_id: author_id,
        lifetime_sales: 0
      }
      |> Repo.insert!()

    # 1..10 reseñas
    Enum.each(1..Enum.random(1..10), fn _ ->
      %Review{
        book_id: book.id,
        body: Faker.Lorem.paragraphs(1..3) |> Enum.join("\n\n"),
        score: Enum.random(1..5),
        upvotes: Enum.random(0..500)
      }
      |> Repo.insert!()
    end)

    # ≥5 años de ventas, desde el año de publicación
    start_year = book.published_on.year
    years = start_year..(start_year + Enum.random(5..10) - 1)

    total_sales =
      years
      |> Enum.map(fn y ->
        sales = Enum.random(500..50_000)

        %YearlySale{book_id: book.id, year: y, sales: sales}
        |> Repo.insert!()

        sales
      end)
      |> Enum.sum()

    book
    |> Ecto.Changeset.change(lifetime_sales: total_sales)
    |> Repo.update!()
  end)

  IO.puts("==> Seeds completados ✅")
end)
