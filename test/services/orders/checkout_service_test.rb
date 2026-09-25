require "test_helper"

module Orders
  class CheckoutServiceTest < ActiveSupport::TestCase
    SHIPPING = {
      shipping_name: "Alice Example",
      shipping_address_line1: "1 Fixture Street",
      shipping_city: "Fixtureville",
      shipping_state: "CA",
      shipping_zip: "90210"
    }.freeze

    setup do
      @user = users(:one)
      @cart = carts(:one)
      @headphones = products(:headphones)
      @novel = products(:novel)
      cart_items(:one).update!(quantity: 2) # 2 x headphones @ 9999
      @cart.cart_items.create!(product: @novel, quantity: 3) # 3 x novel @ 1499, all of its stock
    end

    test "creates a paid order with snapshotted items, decrements stock and empties the cart" do
      order = assert_difference -> { Order.count }, 1 do
        checkout
      end

      assert order.paid?
      assert_equal @user, order.user
      assert_equal (2 * 9999) + (3 * 1499), order.total_cents
      assert_equal "Alice Example", order.shipping_name

      items = order.order_items.index_by(&:product)
      assert_equal 2, items.size
      assert_equal [ 2, 9999 ], [ items[@headphones].quantity, items[@headphones].price_cents ]
      assert_equal [ 3, 1499 ], [ items[@novel].quantity, items[@novel].price_cents ]

      assert_equal 8, @headphones.reload.stock
      assert_equal 0, @novel.reload.stock
      assert_empty @cart.cart_items.reload
    end

    test "changing a product's price after checkout does not change the order item price" do
      order = checkout

      @headphones.update!(price_cents: 1)

      item = order.order_items.find_by(product: @headphones)
      assert_equal 9999, item.reload.price_cents
      assert_equal (2 * 9999) + (3 * 1499), order.reload.total_cents
    end

    test "raises EmptyCartError on an empty cart and creates no order" do
      @cart.cart_items.destroy_all

      assert_no_difference -> { Order.count } do
        assert_raises(CheckoutService::EmptyCartError) { checkout }
      end
    end

    test "raises InsufficientStockError and changes nothing when a line exceeds stock" do
      @novel.update!(stock: 2) # cart wants 3
      cart_before = @cart.cart_items.pluck(:product_id, :quantity).sort

      assert_no_difference [ -> { Order.count }, -> { OrderItem.count } ] do
        assert_raises(CheckoutService::InsufficientStockError) { checkout }
      end

      assert_equal 10, @headphones.reload.stock
      assert_equal 2, @novel.reload.stock
      assert_equal cart_before, @cart.cart_items.reload.pluck(:product_id, :quantity).sort
    end

    private

    def checkout
      CheckoutService.new(user: @user, shipping_attributes: SHIPPING.dup).call
    end
  end
end
