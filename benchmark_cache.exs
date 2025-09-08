# Limpiar cache antes del test
IO.puts("=== BENCHMARK CACHE OPERATIONS ===")
IO.puts("")

# Test 1: Review Scores (Cache Miss)
IO.puts("1. Review Scores - Cache Miss:")
{time_microseconds, _result} = :timer.tc(fn ->
  BookApp.Cache.get_or_compute_review_scores(999, fn -> 
    :timer.sleep(45)  # Simular query SQLite
    %{average: 4.5, count: 100} 
  end)
end)
IO.puts("   Tiempo: #{time_microseconds} microsegundos (#{Float.round(time_microseconds/1000, 2)} ms)")

# Test 2: Review Scores (Cache Hit)
IO.puts("2. Review Scores - Cache Hit:")
{time_microseconds, _result} = :timer.tc(fn ->
  BookApp.Cache.get_or_compute_review_scores(999, fn -> 
    %{average: 9.9, count: 999} 
  end)
end)
IO.puts("   Tiempo: #{time_microseconds} microsegundos (#{Float.round(time_microseconds/1000, 2)} ms)")

# Test 3: Author Info (Cache Miss)
IO.puts("3. Author Info - Cache Miss:")
{time_microseconds, _result} = :timer.tc(fn ->
  BookApp.Cache.get_or_compute_author_info(888, fn -> 
    :timer.sleep(35)  # Simular query SQLite
    %{name: "Test Author", books_count: 5} 
  end)
end)
IO.puts("   Tiempo: #{time_microseconds} microsegundos (#{Float.round(time_microseconds/1000, 2)} ms)")

# Test 4: Author Info (Cache Hit)
IO.puts("4. Author Info - Cache Hit:")
{time_microseconds, _result} = :timer.tc(fn ->
  BookApp.Cache.get_or_compute_author_info(888, fn -> 
    %{name: "Different Author", books_count: 10} 
  end)
end)
IO.puts("   Tiempo: #{time_microseconds} microsegundos (#{Float.round(time_microseconds/1000, 2)} ms)")

# Test 5: Top Books (Cache Miss)
IO.puts("5. Top Books - Cache Miss:")
{time_microseconds, _result} = :timer.tc(fn ->
  BookApp.Cache.get_or_compute_top_books(15, fn -> 
    :timer.sleep(80)  # Simular query compleja SQLite
    Enum.map(1..15, fn i -> %{id: i, title: "Book #{i}"} end)
  end)
end)
IO.puts("   Tiempo: #{time_microseconds} microsegundos (#{Float.round(time_microseconds/1000, 2)} ms)")

# Test 6: Top Books (Cache Hit)
IO.puts("6. Top Books - Cache Hit:")
{time_microseconds, _result} = :timer.tc(fn ->
  BookApp.Cache.get_or_compute_top_books(15, fn -> 
    Enum.map(1..15, fn i -> %{id: i, title: "Different Book #{i}"} end)
  end)
end)
IO.puts("   Tiempo: #{time_microseconds} microsegundos (#{Float.round(time_microseconds/1000, 2)} ms)")

IO.puts("")
IO.puts("=== BENCHMARK COMPLETADO ===")
