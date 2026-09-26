module Carts
  class CartService
    class InsufficientStockError < StandardError; end
    class InvalidQuantityError < StandardError; end

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
      # Adding is always an increase: a 0 or negative "add" would otherwise
      # shrink an existing line through the merge below.
      raise InvalidQuantityError, "Choose a quantity of at least 1." unless positive_integer?(quantity)

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

    # 0 removes the line (the stepper's minus button at a quantity of 1).
    def update_quantity(cart_item:, quantity:)
      return remove_item(cart_item: cart_item) if quantity == 0
      raise InvalidQuantityError, "Choose a quantity of at least 1." unless positive_integer?(quantity)

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

    # Moves the line to the owner's wishlist, so it can be bought later
    # without keeping it in the cart total.
    def save_for_later(cart_item:)
      ActiveRecord::Base.transaction do
        @cart.user.wishlist_items.find_or_create_by!(product: cart_item.product)
        cart_item.destroy!
      end
      cart_item
    end

    private

    def positive_integer?(quantity)
      quantity.is_a?(Integer) && quantity.positive?
    end
  end
end
