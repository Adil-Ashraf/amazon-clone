Project: Amazon Clone — Rails 8

Goal: Rebuild the core purchase flow of amazon.com — browse, search, cart, checkout, order history — as a fully working, polished, deployed product in a 1-day window. Depth and UX quality over feature breadth. Everything below must actually work end-to-end; nothing is a mockup.

In scope — build these, in this order

1. Auth

Sign up, log in, log out
Session-based auth (has_secure_password / authenticate_by)

2. Product catalog

Product listing (grid), with category filter
Product detail page (image, price, description, stock)
Search (Postgres full-text, not substring match)
Seed data: realistic products, categories, prices, images — enough to not look empty

3. Cart

Add to cart, remove, update quantity
Cart persists per logged-in user
Live-updating cart count/total (no full page reload)

4. Checkout

Shipping address form
Mock payment step (no real payment processor — Stripe test mode or a fake "Pay" button is fine)
Order created from cart on successful checkout
Stock decremented safely (no overselling under concurrent requests)

5. Order history

List of a user's past orders
Order detail page (items, quantities, price paid, address)

6. UI/UX polish pass

Loading states, empty states, error states on every page above
Mobile-responsive
One deliberate improvement over the real Amazon UX (pick one, execute it well — don't spread thin)
Explicitly out of scope — do not build these
Reviews/ratings
Recommendations engine
Seller/marketplace accounts, multi-vendor inventory
Wishlist, coupons, gift cards, multi-currency
Real payment processing
Admin panel / inventory management UI (seed data instead)
Returns/refunds flow
Non-functional requirements
Deployed to a live, publicly reachable URL (Render or Fly.io), working while signed out
Money handled as integer cents, never float
Checkout wrapped in a DB transaction with row-level locking on stock
Order line items snapshot price at purchase time (never reference live product price)
Authorization: a user can only see/modify their own cart and orders (Pundit or equivalent)
Thin controllers — business logic lives in service objects
.agent-logs/ committed incrementally throughout, not in one batch at the end
