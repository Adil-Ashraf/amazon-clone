---
name: caching-strategies
description: >-
  Implements Rails caching patterns for performance optimization. Use when
  adding low-level caching, HTTP caching, cache
  invalidation, or when user mentions caching, performance, cache keys,
  or memoization. WHEN NOT: General query optimization (use
  performance-optimization), background job processing, or problems caused by
  N+1 queries rather than missing caches.
paths: "app/controllers/**/*.rb, app/serializers/**/*.rb, components/*/app/controllers/**/*.rb"
---

# Caching Strategies for Rails 8

## Overview

Rails provides multiple caching layers:
- **Low-level caching**: Cache arbitrary data
- **HTTP caching**: Browser and CDN caching
- **Query caching**: Automatic within requests

## Quick Start

```ruby
# config/environments/development.rb
config.action_controller.perform_caching = true
config.cache_store = :memory_store

# config/environments/production.rb
config.cache_store = :solid_cache_store  # Rails 8 default
# OR
config.cache_store = :redis_cache_store, { url: ENV["REDIS_URL"] }
```

Enable caching in development:
```bash
bin/rails dev:cache
```

## Cache Store Options

| Store | Use Case | Pros | Cons |
|-------|----------|------|------|
| `:memory_store` | Development | Fast, no setup | Not shared, limited size |
| `:solid_cache_store` | Production (Rails 8) | Database-backed, no Redis | Slightly slower |
| `:redis_cache_store` | Production | Fast, shared | Requires Redis |
| `:file_store` | Simple production | Persistent, no Redis | Slow, not shared |
| `:null_store` | Testing | No caching | N/A |

## Low-Level Caching

Use `Rails.cache.fetch` with a block for the most common pattern. See [low-level-caching.md](references/low-level-caching.md) for:
- Basic read/write/fetch examples
- Caching in service objects
- Caching in query objects
- Instance variable memoization
- Request-scoped memoization with `CurrentAttributes`

## Cache Invalidation

Three strategies: time-based expiration, key-based expiration (using `updated_at`), and manual deletion. See [cache-invalidation.md](references/cache-invalidation.md) for:
- Time-based and key-based expiration
- Manual invalidation in model callbacks and services
- Pattern-based deletion (`delete_matched`)
- `touch: true` for Russian doll cascade
- Built-in and custom counter caches

## HTTP Caching

Use `stale?` for conditional GET (ETags/Last-Modified) and `expires_in` for Cache-Control headers. See [http-caching-and-testing.md](references/http-caching-and-testing.md) for full examples.

## Testing Caching

Use a `:caching` metadata tag to enable caching in specs. See [http-caching-and-testing.md](references/http-caching-and-testing.md) for:
- `rails_helper.rb` configuration
- Testing cached serializer payload invalidation
- Testing cache invalidation in services
- Performance monitoring and instrumentation

## Checklist

- [ ] Cache store configured for environment
- [ ] Low-level caching for expensive queries
- [ ] Cache invalidation strategy defined
- [ ] Counter caches for counts
- [ ] HTTP caching headers for API
- [ ] Cache warming for cold starts (if needed)
- [ ] Monitoring for hit/miss rates

## References

- [low-level-caching.md](references/low-level-caching.md) - fetch/read/write, service objects, query objects, memoization
- [cache-invalidation.md](references/cache-invalidation.md) - expiration strategies, manual invalidation, touch, counter caches
- [http-caching-and-testing.md](references/http-caching-and-testing.md) - ETags, Cache-Control, spec configuration, monitoring
