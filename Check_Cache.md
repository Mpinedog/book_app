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
