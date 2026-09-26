module Orders
  class CheckoutService
    class EmptyCartError < StandardError; end
    class InsufficientStockError < StandardError; end

    def initialize(user:, shipping_attributes:)
      @user = user
      @shipping_attributes = shipping_attributes
    end

    def call
      cart = @user.ensure_cart!

      ActiveRecord::Base.transaction do
        # Lock the cart before reading its lines. A second checkout of the same
        # cart (two tabs, a resubmitted form) waits here until the first one
        # commits, then finds the cart empty instead of ordering it again.
        cart.lock!
        cart_items = cart.cart_items.includes(:product).order(:product_id).to_a
        raise EmptyCartError, "Your cart is empty." if cart_items.empty?

        # Lock product rows in a stable order (by product_id) so two concurrent
        # checkouts touching overlapping products can't deadlock each other.
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

        # Only the lines that were ordered: one added from another tab after
        # they were read stays in the cart instead of vanishing unbought.
        cart_items.each(&:destroy!)
        order
      end
    end
  end
end
