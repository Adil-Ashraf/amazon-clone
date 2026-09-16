# AmazonClone

A scoped rebuild of Amazon's core purchase flow — browse, search, cart, checkout, and order history — as a fully working, deployed product.

## Live Link

**Live app:** https://amazon-clone-production-4093.up.railway.app/

**Repository:** https://github.com/Adil-Ashraf/amazon-clone

## What This Is

This was built for a take-home assignment with a 24-hour window and one instruction: rebuild a live product, not a mockup. Amazon's actual surface area — marketplace sellers, reviews, recommendations, a dozen fulfillment options — is not a 24-hour project; trying to touch all of it would have produced a shallow demo of everything and a working version of nothing.

Instead, this rebuilds the one loop that makes Amazon *Amazon*: a signed-in user finds a product, adds it to a cart, checks out, and can see what they bought. Everything in scope is real — real Postgres full-text search, a real cart that persists and updates live, a real checkout transaction with row-level locking against overselling, real order history with price snapshotting. Nothing here is a stub that just looks right in a screenshot.

## Features Built

**Auth**
- Sign up, log in, log out — session-based, backed by `has_secure_password`
- Every cart and order lookup is scoped to `current_user`; there is no route that leaks another user's data by guessing an ID

**Product Catalog & Search**
- Product grid with category filtering (8 categories, 110 seeded products)
- Full-text search via Postgres (`pg_search`, prefix-matching `tsearch` against name + description) — not a `LIKE '%query%'` substring match
- 24-item pagination (`pagy`) that preserves the active category/search filter across pages, and redirects to the last valid page if a stale `?page=` param points past the end of the result set
- Product detail page with description, price, live stock badge, and a real photo (see below)
- Every product image is a category-cycled, hand-verified Unsplash photo laid over a generated color-tile fallback — if the real photo ever fails to load, the tile (category color + icon, `object-contain` so nothing crops) takes its place with zero layout shift, since both layers render into the same fixed-size box

**Cart**
- Add, remove, update quantity — all validated against live stock
- Cart persists per logged-in user (one cart row per user, not a session/cookie cart)
- Cart count and totals update live via Turbo Streams — no full-page reload on any cart action
- Adding the same product twice (double-click, two open tabs) merges into one line item instead of erroring or duplicating; the underlying unique-constraint race is handled explicitly (see Architecture)

**Checkout**
- Shipping address form
- Mock payment step (no real processor — this is explicitly out of scope, see below)
- Order created from the cart's current contents on successful checkout
- Stock is decremented inside a locked transaction, so two concurrent checkouts for the last unit of a product can't both succeed

**Order History**
- List of a user's past orders with date, status, and total
- Order detail page showing items, quantities, and the price actually paid — not today's live price (see price snapshotting below)

**UI/UX Polish**
- Loading, empty, and error states on every page above (empty cart, empty order history, no search results, out-of-stock products)
- Mobile-responsive throughout
- **Deliberate UX improvement over stock Amazon:** the category sidebar and product grid live inside a single Turbo Frame, so clicking a category, paging, or searching updates instantly with no full navigation — closer to a SPA than Amazon's own frequently-reloading category pages

## Deliberately Left Out

Everything below was a conscious cut to keep the 24-hour build honest, not an oversight:

- **Reviews/ratings** — a real review system needs moderation, verified-purchase logic, and aggregate scoring to not be worse than nothing; a fake star rating would be pure decoration
- **Recommendations engine** — needs real usage data to be anything but random; a placeholder "related products" rail optimizes for looking busy, not for being useful
- **Seller/marketplace accounts, multi-vendor inventory** — this alone is a second product (listings, seller dashboards, split fulfillment, marketplace-vs-owned-inventory pricing); bolting it on would have starved the core purchase flow of the time it needed
- **Real payment processing** — integrating Stripe correctly (webhooks, idempotency, PCI-adjacent handling) is its own multi-day task; a mock payment step exercises the same order-creation path without the false confidence of a "working" payment integration that hasn't been hardened
- **Wishlist, coupons, gift cards, multi-currency** — all real features, none of them load-bearing for the core loop this project is demonstrating
- **Admin panel / inventory management UI** — seed data does this job for a reviewer; building an admin CRUD layer would have traded purchase-flow depth for breadth nobody asked for
- **Returns/refunds flow** — depends on real payment processing existing first

## Architecture / Tech Decisions

- **Service objects for business logic** — `Carts::CartService` and `Orders::CheckoutService` hold the actual rules (stock validation, quantity merging, order creation); controllers stay thin and just orchestrate. `CheckoutService#call` is the one place a cart turns into an order, wrapped in a single transaction.
- **Pundit for authorization** — every cart/order action is scoped through `current_user.cart` / `current_user.orders` before any policy check even runs, so there's no route where swapping an ID in the URL reaches another user's record.
- **Money as integer cents, always** — every price field is `_cents`, never a float. `format_price_cents` is the only place a cent value becomes a display string.
- **Price snapshotting on orders** — `OrderItem#price_cents` is copied from the product at the moment of purchase, not read live from `product.price_cents`. A price change next week can't rewrite what someone paid last week.
- **Row-locking on checkout** — `CheckoutService` locks the product rows involved (`product.lock!`, in stable `product_id` order to avoid cross-checkout deadlocks) inside the checkout transaction, re-validates stock under the lock, then decrements it. Two concurrent checkouts for the same last-unit product can't both win.
- **The same race pattern, applied to cart adds** — `CartService#add_item` retries on `ActiveRecord::RecordNotUnique` instead of letting a double-click or two-tab race surface as a 500; the retry re-reads the row the winning request just committed and merges into it.
- **Turbo Streams for live cart updates** — cart create/update/destroy respond with Turbo Stream partials that patch the cart badge and line items in place, so cart state feels instant without hand-rolled JS or a JSON API layer.
- **Hand-rolled auth via `has_secure_password`, not Devise** — the entire auth surface here is sign up / log in / log out against one `User` model. Devise's value is in the features this project doesn't need (password reset flows, confirmable, lockable, omniauth); pulling it in for three actions would mean carrying its configuration surface and generated views for no real leverage. `has_secure_password` plus a `sessions_controller` is the whole feature, visibly.

## Tech Stack

- **Ruby** 3.4.10 · **Rails** 8.1
- **PostgreSQL** — primary datastore, plus full-text search (`pg_search`) and row-locking for checkout
- **Tailwind CSS** (`tailwindcss-rails`) — utility-first styling, no component library
- **Hotwire** — Turbo (Frames + Streams) and Stimulus for interactivity without a separate frontend build
- **Key gems:** `pg_search` (full-text search), `pundit` (authorization), `pagy` (pagination), `bcrypt` (via `has_secure_password`)
- **Deployment:** Railway, via the repo's `Dockerfile`

## Running Locally

```bash
git clone <repo-url>
cd amazon-clone
bundle install
bin/rails db:prepare   # creates the DB and loads the schema
bin/rails db:seed      # 8 categories, 110 products, a demo user
bin/rails server
```

Visit `http://localhost:3000` and log in with the seeded demo account — no need to sign up to explore:

```
email:    demo@example.com
password: password123
```

## Agent Usage

This project was built with [Claude Code](https://claude.com/claude-code) assistance. The full prompt/response history for every session is committed in [`.agent-logs/`](.agent-logs/), per the assignment's capture requirement — including sessions with unresolved dead ends and abandoned approaches, not just the ones that shipped. That log is the honest record of how this got built, not a cleaned-up highlight reel.

## What I'd Build Next

With more time, in roughly this order:

1. **Real test coverage** — the business-critical paths (stock locking, price snapshotting, checkout concurrency, authorization scoping) are currently verified by hand rather than by a suite that runs on every change. This is the single highest-leverage next step.
2. **Real payment integration** — Stripe in test mode, done properly: webhooks for async confirmation, idempotency keys on the charge, and a payment-failed state that doesn't just fall through to "order placed."
3. **Reviews and ratings** — with real moderation and verified-purchase gating, not a decorative star widget.
4. **Seller accounts** — the actual second product hinted at above: listings, seller-owned inventory, and a dashboard, kept clearly separate from the buyer-facing purchase flow this submission focuses on.
