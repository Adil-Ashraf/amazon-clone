# Caching Strategies: Low-Level Caching

## Basic Read/Write/Fetch

```ruby
# Read with block (fetch - preferred pattern)
Rails.cache.fetch("stats/#{Date.current}", expires_in: 1.hour) do
  # Expensive calculation
  {
    total_events: Event.count,
    total_revenue: Order.sum(:total_cents)
  }
end

# Just read (returns nil if missing)
stats = Rails.cache.read("stats/#{Date.current}")

# Just write
Rails.cache.write("stats/#{Date.current}", stats, expires_in: 1.hour)

# Delete
Rails.cache.delete("stats/#{Date.current}")
```

## In Service Objects

```ruby
# app/services/orders/stats_service.rb
module Orders
  class StatsService
    CACHE_KEY = "order_stats"
    CACHE_TTL = 15.minutes

    def call(user:)
      Rails.cache.fetch(cache_key(user), expires_in: CACHE_TTL) do
        calculate_stats(user)
      end
    end

    def invalidate(user:)
      Rails.cache.delete(cache_key(user))
    end

    private

    def cache_key(user)
      "#{CACHE_KEY}/#{user.id}" # always include the user for per-user data
    end

    def calculate_stats(user)
      {
        orders_count: user.orders.count,
        total_spent_cents: user.orders.paid.sum(:total_cents)
      }
    end
  end
end
```

## In Query Objects

```ruby
# app/queries/top_products_query.rb
class TopProductsQuery
  def initialize(limit: 10, use_cache: true)
    @limit = limit
    @use_cache = use_cache
  end

  def call
    return fetch_top_products unless @use_cache

    Rails.cache.fetch("top_products/#{@limit}", expires_in: 10.minutes) do
      fetch_top_products
    end
  end

  private

  def fetch_top_products
    Product.joins(:order_items)
      .group(:id)
      .order("SUM(order_items.quantity) DESC")
      .limit(@limit)
      .to_a
  end
end
```

## Memoization

### Instance Variable Memoization

```ruby
class Cart < ApplicationRecord
  def total_cents
    @total_cents ||= cart_items.includes(:product).sum { |item| item.product.price_cents * item.quantity }
  end
end
```

Clear or avoid memoized values on records that change within the same
request (e.g. after `add_item`, reload the cart).

### Request-Scoped Memoization

```ruby
# app/controllers/application_controller.rb
def current_user
  @current_user ||= User.find_by(id: session[:user_id])
end
```

One query per request, however many views and helpers call `current_user`.
