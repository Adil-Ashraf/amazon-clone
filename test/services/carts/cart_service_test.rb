require "test_helper"

module Carts
  class CartServiceTest < ActiveSupport::TestCase
    setup do
      @cart = carts(:one)
      @service = CartService.new(@cart)
    end

    test "add_item creates a line for a product not yet in the cart" do
      product = products(:novel)

      assert_difference -> { @cart.cart_items.count }, 1 do
        @service.add_item(product: product, quantity: 2)
      end

      assert_equal 2, @cart.cart_items.find_by(product: product).quantity
    end

    test "add_item merges quantities when the product is already in the cart" do
      line = cart_items(:one)

      assert_no_difference -> { @cart.cart_items.count } do
        @service.add_item(product: line.product, quantity: 3)
      end

      assert_equal 4, line.reload.quantity
    end

    test "add_item raises when the merged quantity would exceed stock" do
      line = cart_items(:one) # headphones, quantity 1, stock 10

      assert_raises(CartService::InsufficientStockError) do
        @service.add_item(product: line.product, quantity: 10)
      end

      assert_equal 1, line.reload.quantity
    end

    test "add_item raises for a sold-out product and creates no line" do
      assert_no_difference -> { CartItem.count } do
        assert_raises(CartService::InsufficientStockError) do
          @service.add_item(product: products(:sold_out))
        end
      end
    end

    test "update_quantity sets a new quantity within stock" do
      line = cart_items(:one)

      @service.update_quantity(cart_item: line, quantity: 5)

      assert_equal 5, line.reload.quantity
    end

    test "update_quantity with 0 removes the line" do
      line = cart_items(:one)

      assert_difference -> { @cart.cart_items.count }, -1 do
        @service.update_quantity(cart_item: line, quantity: 0)
      end

      assert_not CartItem.exists?(line.id)
    end

    test "update_quantity above stock raises and leaves the quantity unchanged" do
      line = cart_items(:one)

      assert_raises(CartService::InsufficientStockError) do
        @service.update_quantity(cart_item: line, quantity: line.product.stock + 1)
      end

      assert_equal 1, line.reload.quantity
    end
  end
end
