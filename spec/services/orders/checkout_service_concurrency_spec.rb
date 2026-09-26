require "rails_helper"

# Two checkouts of the same cart at once (two tabs, a resubmitted form). Each
# runs in its own thread and database connection, so this group commits for
# real instead of using a rolled-back transaction, and cleans up after itself.
RSpec.describe Orders::CheckoutService, "concurrent checkout of one cart" do
  self.use_transactional_tests = false

  let(:shipping) do
    { shipping_name: "Test User", shipping_address_line1: "1 Spec Street",
      shipping_city: "Specville", shipping_state: "CA", shipping_zip: "90210" }
  end
  let!(:user) { create(:user, :with_cart) }
  let!(:product) { create(:product, stock: 5) }

  before { create(:cart_item, cart: user.cart, product: product, quantity: 1) }

  after do
    [ OrderItem, Order, CartItem, Cart, Product, Category, User ].each(&:delete_all)
  end

  # The first checkout pauses inside its transaction until the second one is
  # blocked on a row lock, so the two always overlap.
  # Polled from inside the first checkout's transaction, where Postgres would
  # otherwise keep returning the same cached pg_stat_activity snapshot.
  def blocked_on_lock?
    ActiveRecord::Base.connection.execute("SELECT pg_stat_clear_snapshot()")
    ActiveRecord::Base.connection.select_value(<<~SQL).positive?
      SELECT count(*) FROM pg_stat_activity
      WHERE datname = current_database() AND wait_event_type = 'Lock'
    SQL
  end

  def wait_until_second_checkout_blocks
    deadline = 5.seconds.from_now
    until blocked_on_lock?
      raise "the second checkout never waited on a lock" if Time.current > deadline

      sleep 0.01
    end
  end

  # Takes plain values: `let` memoization is locked while `results` is being
  # built, so the threads must not call `user` or `shipping` themselves.
  def checkout_in_thread(user_id, shipping_attributes)
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        described_class.new(user: User.find(user_id), shipping_attributes: shipping_attributes).call
      rescue described_class::EmptyCartError => e
        e
      end
    end
  end

  let!(:results) do
    first_inside = Queue.new
    paused = false
    allow(Order).to receive(:shipping_cents_for).and_wrap_original do |original, *args|
      unless paused
        paused = true
        first_inside << true
        wait_until_second_checkout_blocks
      end
      original.call(*args)
    end

    first = checkout_in_thread(user.id, shipping)
    first_inside.pop
    second = checkout_in_thread(user.id, shipping)
    [ first, second ].map(&:value)
  end

  it "creates exactly one order" do
    expect(Order.where(user: user).count).to eq(1)
  end

  it "decrements stock once" do
    expect(product.reload.stock).to eq(4)
  end

  it "rejects the second checkout because the cart is already empty" do
    expect(results).to contain_exactly(an_instance_of(Order), an_instance_of(described_class::EmptyCartError))
  end

  it "leaves one order line and an empty cart" do
    expect([ OrderItem.count, CartItem.count ]).to eq([ 1, 0 ])
  end
end
