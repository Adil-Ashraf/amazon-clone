module Carts
  class CartService
    class InsufficientStockError < StandardError; end

    def initialize(cart)
      @cart = cart
    end

    # find_or_initialize_by + save! has a gap between the SELECT and the
    # INSERT: two concurrent requests for the same cart+product (a
    # double-click, two open tabs) can both see new_record? and both try to
    # INSERT, so the DB's unique index on (cart_id, product_id) raises
    # ActiveRecord::RecordNotUnique for whichever loses the race. Retrying
    # re-runs find_or_initialize_by, which now finds the row the winner just
    # created and merges into it with a plain UPDATE instead of erroring.
    def add_item(product:, quantity: 1, attempt: 1)
      cart_item = @cart.cart_items.find_or_initialize_by(product: product)
      current_quantity = cart_item.new_record? ? 0 : cart_item.quantity
      new_quantity = current_quantity + quantity

      if new_quantity > product.stock
        raise InsufficientStockError, "Only #{product.stock} left in stock"
      end

      cart_item.quantity = new_quantity
      cart_item.save!
      cart_item
    rescue ActiveRecord::RecordNotUnique
      raise if attempt >= 3

      add_item(product: product, quantity: quantity, attempt: attempt + 1)
    end

    def update_quantity(cart_item:, quantity:)
      return remove_item(cart_item: cart_item) if quantity <= 0

      if quantity > cart_item.product.stock
        raise InsufficientStockError, "Only #{cart_item.product.stock} left in stock"
      end

      cart_item.update!(quantity: quantity)
      cart_item
    end

    def remove_item(cart_item:)
      cart_item.destroy!
      cart_item
    end
  end
end
