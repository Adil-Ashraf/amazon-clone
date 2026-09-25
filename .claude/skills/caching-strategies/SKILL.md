---
name: caching-strategies
description: >-
  Implements Rails caching patterns for performance optimization. Use when
  adding fragment caching, low-level caching, HTTP caching, cache
  invalidation, or when user mentions caching, performance, cache keys,
  or memoization. WHEN NOT: General query optimization (use
  performance-optimization), background job processing, or problems caused by
  N+1 queries rather than missing caches.
paths: "app/controllers/**/*.rb, app/views/**/*.erb, app/services/**/*.rb"
---

# Caching Strategies for Rails 8

## Overview

Rails provides multiple caching layers:
- **Fragment caching**: Cache rendered view partials
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

## Fragment Caching

Cache rendered partials keyed on the record, so any update expires them:

```erb
<%# app/views/products/index.html.erb %>
<% @products.each do |product| %>
  <% cache product do %>
    <%= render "products/product_card", product: product %>
  <% end %>
<% end %>
```

- Never cache per-user content (cart badge, "Hello, name") in a shared fragment;
  include the user in the key or leave it uncached.
- Turbo Stream targets inside a cached fragment still need stable ids.
- `belongs_to :category, touch: true` cascades expiry up nested fragments
  (Russian doll).

## Low-Level Caching

Use `Rails.cache.fetch` with a block for the most common pattern. See [low-level-caching.md](references/low-level-caching.md) for:
- Basic read/write/fetch examples
- Caching in service objects
- Caching in query objects
- Instance variable memoization
- Request-scoped memoization in controllers (`@current_user ||=`)

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
- Testing cached fragment invalidation
- Testing cache invalidation in services
- Performance monitoring and instrumentation

## Checklist

- [ ] Cache store configured for environment
- [ ] Low-level caching for expensive queries
- [ ] Cache invalidation strategy defined
- [ ] Counter caches for counts
- [ ] Fragment caching for expensive, shared partials
- [ ] HTTP caching headers for public pages
- [ ] Cache warming for cold starts (if needed)
- [ ] Monitoring for hit/miss rates

## References

- [low-level-caching.md](references/low-level-caching.md) - fetch/read/write, service objects, query objects, memoization
- [cache-invalidation.md](references/cache-invalidation.md) - expiration strategies, manual invalidation, touch, counter caches
- [http-caching-and-testing.md](references/http-caching-and-testing.md) - ETags, Cache-Control, spec configuration, monitoring
