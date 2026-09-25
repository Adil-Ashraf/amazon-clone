# Caching Strategies: HTTP Caching and Testing

## HTTP Caching

### Conditional GET (ETag/Last-Modified)

Public, user-independent pages are the safe candidates:

```ruby
class ProductsController < ApplicationController
  def show
    @product = Product.includes(:category).find(params[:id])

    # Returns 304 Not Modified if unchanged. The layout shows the signed-in
    # user's cart count, so include the user in the ETag.
    fresh_when etag: [ @product, current_user&.cart&.updated_at ], last_modified: @product.updated_at
  end
end
```

### Cache-Control Headers

```ruby
class ProductsController < ApplicationController
  def show
    @product = Product.find(params[:id])

    # Private caching (browser only) -- the page contains per-user chrome
    expires_in 5.minutes, private: true
  end
end
```

Never mark pages with per-user content (cart, orders, checkout) as `public`.

## Testing Caching

### Spec Configuration

```ruby
# spec/support/caching.rb
RSpec.configure do |config|
  config.around(:each, :caching) do |example|
    caching = ActionController::Base.perform_caching
    ActionController::Base.perform_caching = true
    Rails.cache.clear
    example.run
    ActionController::Base.perform_caching = caching
  end
end
```

### Testing Cached Views

```ruby
RSpec.describe "Products", type: :request, caching: true do
  let(:product) { create(:product) }

  def view_product
    get product_path(product)
  end

  context "after the product changes" do
    before do
      view_product                             # prime the fragment cache
      product.update!(price_cents: product.price_cents + 100)
      view_product
    end

    it "renders the new price" do
      expect(response.body).to include(ApplicationController.helpers.format_price_cents(product.price_cents))
    end
  end
end
```

### Testing Cache Invalidation

```ruby
RSpec.describe OrderStatsService do
  let(:user) { create(:user) }
  let(:service) { described_class.new }

  before do
    service.call(user: user)       # prime
    service.invalidate(user: user)
  end

  it "clears the cache" do
    expect(Rails.cache.exist?("order_stats/#{user.id}")).to be(false)
  end
end
```

## Performance Monitoring

### Cache Hit/Miss Logging

```ruby
# config/environments/production.rb
config.action_controller.enable_fragment_cache_logging = true
```

### Custom Instrumentation

```ruby
# Subscribe to cache events
ActiveSupport::Notifications.subscribe("cache_read.active_support") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  Rails.logger.info "Cache #{event.payload[:hit] ? 'HIT' : 'MISS'}: #{event.payload[:key]}"
end
```
