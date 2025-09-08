# Check Cache - Comandos de Verificación del Sistema de Cache Redis

Este documento contiene todos los comandos necesarios para verificar que el sistema de cache Redis está funcionando correctamente en la aplicación Book App.

## 1. Verificar Estado de Contenedores

```bash
# Verificar que los contenedores están corriendo
docker compose -f docker-compose-db-cache.yml ps
```

## 2. Verificar Conectividad Redis

```bash
# Verificar que Redis responde correctamente
docker exec -it book_app-redis-1 redis-cli ping
# Resultado esperado: PONG
```

## 3. Verificar Proceso Redis en la Aplicación

```bash
# Verificar que el proceso Redis está registrado en Elixir
docker exec book_app-web-1 mix run -e "IO.puts(Process.whereis(:redis_connection) |> inspect())"
# Resultado esperado: #PID<0.XXX.0>
```

## 4. Probar Cache Básico (PUT/GET)

```bash
# Guardar un valor en cache
docker exec book_app-web-1 mix run -e "BookApp.Cache.safe_put(\"test_key\", \"test_value\"); IO.puts(\"Cache put successful\")"

# Recuperar el valor del cache
docker exec book_app-web-1 mix run -e "value = BookApp.Cache.safe_get(\"test_key\"); IO.puts(\"Retrieved value: #{inspect(value)}\")"
# Resultado esperado: Retrieved value: "test_value"
```

## 5. Verificar Datos en Redis Directamente

```bash
# Ver el valor guardado directamente en Redis
docker exec -it book_app-redis-1 redis-cli get "test_key"
# Resultado esperado: "\"test_value\""
```

## 6. Probar Cache Especializado de Review Scores

```bash
# Primera ejecución - computa y guarda en cache
docker exec book_app-web-1 mix run -e "result = BookApp.Cache.get_or_compute_review_scores(1, fn -> %{average: 4.5, count: 10} end); IO.puts(\"Review scores: #{inspect(result)}\")"
# Resultado esperado: 
# [info] Computing review scores for book 1 [Redis]
# Review scores: %{count: 10, average: 4.5}

# Segunda ejecución - obtiene del cache (sin computar)
docker exec book_app-web-1 mix run -e "result = BookApp.Cache.get_or_compute_review_scores(1, fn -> %{average: 9.9, count: 999} end); IO.puts(\"Review scores from cache: #{inspect(result)}\")"
# Resultado esperado (sin mensaje de Computing):
# Review scores from cache: %{"average" => 4.5, "count" => 10}
```

## 7. Probar Invalidación de Cache

```bash
# Invalidar cache del libro 1
docker exec book_app-web-1 mix run -e "BookApp.Cache.invalidate_book_cache(1); IO.puts(\"Cache invalidated for book 1\")"
# Resultado esperado: 
# [info] Invalidated cache for book 1 [Redis]
# Cache invalidated for book 1

# Verificar que se vuelve a computar tras invalidación
docker exec book_app-web-1 mix run -e "result = BookApp.Cache.get_or_compute_review_scores(1, fn -> %{average: 9.9, count: 999} end); IO.puts(\"Review scores after invalidation: #{inspect(result)}\")"
# Resultado esperado:
# [info] Computing review scores for book 1 [Redis]
# Review scores after invalidation: %{count: 999, average: 9.9}
```

## 8. Probar Otras Funciones de Cache

```bash
# Cache de información de autor
docker exec book_app-web-1 mix run -e "result = BookApp.Cache.get_or_compute_author_info(1, fn -> %{name: \"Test Author\", books_count: 5} end); IO.puts(\"Author info: #{inspect(result)}\")"

# Cache de top books
docker exec book_app-web-1 mix run -e "result = BookApp.Cache.get_or_compute_top_books(10, fn -> [%{id: 1, title: \"Book 1\"}, %{id: 2, title: \"Book 2\"}] end); IO.puts(\"Top books: #{inspect(result)}\")"

# Cache de búsqueda de libros
docker exec book_app-web-1 mix run -e "result = BookApp.Cache.get_or_compute_book_search(\"elixir\", fn -> [%{id: 1, title: \"Programming Elixir\"}] end); IO.puts(\"Search results: #{inspect(result)}\")"
```

## 9. Probar Invalidación Específica

```bash
# Invalidar cache de autor
docker exec book_app-web-1 mix run -e "BookApp.Cache.invalidate_author_cache(1); IO.puts(\"Author cache invalidated\")"

# Invalidar cache de reviews
docker exec book_app-web-1 mix run -e "BookApp.Cache.invalidate_review_cache(1); IO.puts(\"Review cache invalidated\")"

# Invalidar cache de ventas anuales
docker exec book_app-web-1 mix run -e "BookApp.Cache.invalidate_yearly_sale_cache(1); IO.puts(\"Yearly sale cache invalidated\")"
```

## 10. Verificar Logs de la Aplicación

```bash
# Ver logs en tiempo real
docker compose -f docker-compose-db-cache.yml logs -f web

# Ver logs específicos de Redis
docker compose -f docker-compose-db-cache.yml logs redis
```

## 11. Comandos de Administración Redis

```bash
# Ver todas las claves en Redis
docker exec -it book_app-redis-1 redis-cli keys "*"

# Ver información de Redis
docker exec -it book_app-redis-1 redis-cli info

# Limpiar toda la cache (¡CUIDADO!)
docker exec -it book_app-redis-1 redis-cli flushall
```

## Notas Importantes

1. **TTL por defecto**: Cada tipo de cache tiene su propio Time To Live configurado:
   - Review scores: 2 horas
   - Author info: 4 horas  
   - Book queries: 30 minutos
   - Top books: 15 minutos

2. **Manejo de errores**: Si Redis falla, las funciones `safe_*` manejan los errores gracefully.

3. **Logging**: Todas las operaciones de cache logean información útil para debugging.

4. **Formato de datos**: Los datos se serializan en JSON automáticamente.

5. **Invalidación inteligente**: Al invalidar un libro/autor/review, se limpian todas las claves relacionadas automáticamente.

## Estructura de Claves en Redis

- `review_scores:{book_id}` - Puntuaciones de reviews por libro
- `author_info:{author_id}` - Información de autores
- `top_books:{limit}` - Top libros con límite específico
- `top_selling_books` - Top libros más vendidos
- `book_search:{hash}` - Resultados de búsqueda (hash MD5 del término)
- `yearly_sales:{book_id}:{year}` - Ventas anuales por libro y año
- `author_total_sales:{author_id}` - Ventas totales por autor

## 12. Benchmarking y Métricas de Rendimiento

### Instalar herramientas de benchmarking

```bash
# Instalar Apache Bench (si no está instalado)
sudo apt-get update && sudo apt-get install apache2-utils

# Instalar curl para timing detallado
sudo apt-get install curl time
```

### A. Medir Tiempos de Respuesta Básicos

```bash
# Medir tiempo de respuesta de página principal
curl -w "@curl-format.txt" -o /dev/null -s http://localhost:4000/

# Crear archivo de formato para curl
echo 'time_namelookup:  %{time_namelookup}\n
time_connect:     %{time_connect}\n
time_appconnect:  %{time_appconnect}\n
time_pretransfer: %{time_pretransfer}\n
time_redirect:    %{time_redirect}\n
time_starttransfer: %{time_starttransfer}\n
time_total:       %{time_total}\n' > curl-format.txt
```

### B. Benchmarking con Apache Bench

```bash
# Test básico - 100 requests, 10 concurrentes
ab -n 100 -c 10 http://localhost:4000/

# Test de carga media - 1000 requests, 50 concurrentes
ab -n 1000 -c 50 http://localhost:4000/

# Test de estrés - 5000 requests, 100 concurrentes
ab -n 5000 -c 100 http://localhost:4000/

# Test específico de endpoints con cache
ab -n 500 -c 25 http://localhost:4000/books
ab -n 500 -c 25 http://localhost:4000/authors
```

### C. Medir Cache Hit/Miss Ratio

```bash
# Obtener estadísticas de Redis antes del test
docker exec -it book_app-redis-1 redis-cli info stats > redis_stats_before.txt

# Ejecutar carga de trabajo
ab -n 1000 -c 50 http://localhost:4000/books

# Obtener estadísticas después
docker exec -it book_app-redis-1 redis-cli info stats > redis_stats_after.txt

# Comparar archivos para ver diferencias
diff redis_stats_before.txt redis_stats_after.txt
```

### D. Benchmark de Funciones de Cache Específicas

```bash
# Script para medir tiempos de cache operations
cat > benchmark_cache.exs << 'EOF'
# Benchmark Review Scores
{time_microseconds, _result} = :timer.tc(fn ->
  BookApp.Cache.get_or_compute_review_scores(1, fn -> 
    %{average: 4.5, count: 100} 
  end)
end)
IO.puts("Review scores (cache miss): #{time_microseconds} microseconds")

# Test cache hit
{time_microseconds, _result} = :timer.tc(fn ->
  BookApp.Cache.get_or_compute_review_scores(1, fn -> 
    %{average: 9.9, count: 999} 
  end)
end)
IO.puts("Review scores (cache hit): #{time_microseconds} microseconds")

# Benchmark Author Info
{time_microseconds, _result} = :timer.tc(fn ->
  BookApp.Cache.get_or_compute_author_info(1, fn -> 
    %{name: "Test Author", books_count: 5} 
  end)
end)
IO.puts("Author info (cache miss): #{time_microseconds} microseconds")

{time_microseconds, _result} = :timer.tc(fn ->
  BookApp.Cache.get_or_compute_author_info(1, fn -> 
    %{name: "Different Author", books_count: 10} 
  end)
end)
IO.puts("Author info (cache hit): #{time_microseconds} microseconds")

# Benchmark Top Books
{time_microseconds, _result} = :timer.tc(fn ->
  BookApp.Cache.get_or_compute_top_books(10, fn -> 
    Enum.map(1..10, fn i -> %{id: i, title: "Book #{i}"} end)
  end)
end)
IO.puts("Top books (cache miss): #{time_microseconds} microseconds")

{time_microseconds, _result} = :timer.tc(fn ->
  BookApp.Cache.get_or_compute_top_books(10, fn -> 
    Enum.map(1..10, fn i -> %{id: i, title: "Different Book #{i}"} end)
  end)
end)
IO.puts("Top books (cache hit): #{time_microseconds} microseconds")
EOF

# Ejecutar benchmark
docker exec book_app-web-1 mix run benchmark_cache.exs
```

### E. Benchmark Comparativo Sin Cache

```bash
# Script para simular operaciones sin cache
cat > benchmark_no_cache.exs << 'EOF'
# Simular consulta a base de datos directa
{time_microseconds, _result} = :timer.tc(fn ->
  # Simular query SQLite costosa
  :timer.sleep(45)  # 45ms típico para consulta compleja
  %{average: 4.5, count: 100}
end)
IO.puts("Direct DB query (simulated): #{time_microseconds} microseconds")

# Repetir para múltiples consultas
Enum.each(1..5, fn i ->
  {time_microseconds, _result} = :timer.tc(fn ->
    :timer.sleep(Enum.random(20..80))  # Variabilidad real de DB
    %{average: 4.5, count: 100}
  end)
  IO.puts("Direct DB query #{i}: #{time_microseconds} microseconds")
end)
EOF

docker exec book_app-web-1 mix run benchmark_no_cache.exs
```

### F. Monitoreo de Memoria Redis

```bash
# Ver uso de memoria en tiempo real
docker exec -it book_app-redis-1 redis-cli info memory

# Monitorear claves y expiración
docker exec -it book_app-redis-1 redis-cli info keyspace

# Ver comandos ejecutados por segundo
docker exec -it book_app-redis-1 redis-cli info stats | grep instantaneous
```

### G. Test de Carga Completo con Métricas

```bash
# Script completo de benchmarking
cat > full_benchmark.sh << 'EOF'
#!/bin/bash

echo "=== BENCHMARK COMPLETO REDIS CACHE ==="
echo "Fecha: $(date)"
echo ""

# 1. Limpiar cache para empezar fresco
echo "1. Limpiando cache..."
docker exec -it book_app-redis-1 redis-cli flushall
echo "Cache limpiado"
echo ""

# 2. Benchmark de página principal (cache miss)
echo "2. Test inicial (cache miss) - 100 requests, 10 concurrent"
ab -n 100 -c 10 -q http://localhost:4000/ | grep -E "(Requests per second|Time per request|Transfer rate)"
echo ""

# 3. Benchmark de página principal (cache hit)
echo "3. Test con cache warm (cache hit) - 100 requests, 10 concurrent"
ab -n 100 -c 10 -q http://localhost:4000/ | grep -E "(Requests per second|Time per request|Transfer rate)"
echo ""

# 4. Test de carga media
echo "4. Test de carga media - 1000 requests, 50 concurrent"
ab -n 1000 -c 50 -q http://localhost:4000/ | grep -E "(Requests per second|Time per request|Transfer rate)"
echo ""

# 5. Estadísticas finales de Redis
echo "5. Estadísticas de Redis:"
docker exec book_app-redis-1 redis-cli info stats | grep -E "(keyspace_hits|keyspace_misses|instantaneous)"
echo ""

echo "=== BENCHMARK COMPLETADO ==="
EOF

chmod +x full_benchmark.sh
./full_benchmark.sh
```

### H. Análisis de Hit Ratio

```bash
# Calcular hit ratio de Redis
docker exec book_app-web-1 mix run -e "
stats = :gen_server.call(:redis_connection, {:command, [\"INFO\", \"stats\"]})
IO.puts(\"Redis Stats:\")
IO.puts(stats)
"

# Script para calcular hit ratio
cat > calculate_hit_ratio.sh << 'EOF'
#!/bin/bash
hits=$(docker exec book_app-redis-1 redis-cli info stats | grep keyspace_hits | cut -d: -f2 | tr -d '\r')
misses=$(docker exec book_app-redis-1 redis-cli info stats | grep keyspace_misses | cut -d: -f2 | tr -d '\r')

if [ ! -z "$hits" ] && [ ! -z "$misses" ]; then
    total=$((hits + misses))
    if [ $total -gt 0 ]; then
        hit_ratio=$(echo "scale=2; $hits * 100 / $total" | bc)
        echo "Cache Hits: $hits"
        echo "Cache Misses: $misses"
        echo "Hit Ratio: ${hit_ratio}%"
    else
        echo "No cache operations recorded yet"
    fi
else
    echo "Could not retrieve Redis stats"
fi
EOF

chmod +x calculate_hit_ratio.sh
./calculate_hit_ratio.sh
```

### Interpretación de Resultados

**Métricas clave a analizar:**
- **Requests per second**: Throughput del sistema
- **Time per request (mean)**: Latencia promedio
- **Cache Hit Ratio**: Eficiencia del cache
- **Memory usage**: Consumo de recursos
- **95th percentile**: Latencia para el 95% de usuarios
