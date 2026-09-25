module Orders
  class CheckoutService
    class EmptyCartError < StandardError; end
    class InsufficientStockError < StandardError; end

    def initialize(user:, shipping_attributes:)
      @user = user
      @shipping_attributes = shipping_attributes
    end

    def call
      cart = @user.cart
      raise EmptyCartError, "Your cart is empty." if cart.cart_items.none?

      order = nil

      ActiveRecord::Base.transaction do
        # Lock product rows in a stable order (by product_id) so two concurrent
        # checkouts touching overlapping products can't deadlock each other.
        cart_items = cart.cart_items.includes(:product).order(:product_id).to_a
        cart_items.each { |cart_item| cart_item.product.lock! }

        cart_items.each do |cart_item|
          product = cart_item.product
          if cart_item.quantity > product.stock
            raise InsufficientStockError, "Only #{product.stock} left in stock for \"#{product.name}\"."
          end
        end

        subtotal_cents = cart_items.sum { |cart_item| cart_item.product.price_cents * cart_item.quantity }
        shipping_cents = Order.shipping_cents_for(subtotal_cents)

        order = @user.orders.create!(
          @shipping_attributes.merge(status: :paid, shipping_cents: shipping_cents, total_cents: subtotal_cents + shipping_cents)
        )

        cart_items.each do |cart_item|
          product = cart_item.product
          order.order_items.create!(product: product, quantity: cart_item.quantity, price_cents: product.price_cents)
          product.decrement!(:stock, cart_item.quantity)
        end

        cart.cart_items.destroy_all
      end

      order
    end
  end
end
