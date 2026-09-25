# Aisle Market

**Better products. Better everyday.**

Aisle Market is an original e-commerce product built as a full-stack Ruby on
Rails 8.1 application. Shoppers can browse a curated catalog, compare real
prices and verified-buyer reviews, save items, and check out through a
transactional order flow backed by PostgreSQL.

- **Live app:** https://amazon-clone-production-4093.up.railway.app/
- **Repository:** https://github.com/Adil-Ashraf/amazon-clone
- **Design system:** [`docs/DESIGN.md`](docs/DESIGN.md)

## An original design, not a clone

Amazon was the functional reference for what a store needs (catalog, cart,
checkout, orders). Everything the shopper sees is our own: the brand, layout,
type, colour, components and interaction design.

- **Visual identity.** Warm ivory surfaces, deep ink typography and one accent,
  Aisle Orange. The rule is roughly 70% neutral, 20% ink, 10% orange, and
  orange only marks the primary action, the active state or a sale.
- **Calm density.** Cards show just enough to decide: image, category, name,
  rating, price and one action. There are no badge walls or sponsored slots.
- **Every signal is real.** Ratings, "was" prices, deals, stock, shipping,
  order status and recommendations all come from the database. If the backend
  doesn't know it, the UI doesn't show it.

[`docs/DESIGN.md`](docs/DESIGN.md) documents the tokens, type scale,
components and page layouts, and where each UI signal comes from (§6).

## Technology stack

| Layer | Choice |
| --- | --- |
| Language / framework | Ruby 3.4.10, Rails 8.1 (server-rendered ERB) |
| Database | PostgreSQL, full-text search via `pg_search` |
| Frontend | Hotwire (Turbo Frames and Streams, Stimulus via importmap), no Node build |
| Styling | Tailwind CSS v4 (`tailwindcss-rails`), design tokens in `@theme` |
| Assets | Propshaft |
| Auth / authorization | `has_secure_password` (bcrypt), Pundit |
| Pagination | Pagy |
| Tests | RSpec, FactoryBot, Shoulda Matchers, Capybara + Selenium |
| Quality | RuboCop (rails-omakase), Brakeman |
| Deployment | Docker image on Railway |

## Main user journey

1. **Discover.** Start from the home page (today's deals, categories, popular
   and recommended products), search, or browse a filtered catalog.
2. **Decide.** Open a product page with price and savings, live stock,
   specifications and verified-purchase reviews.
3. **Save or add.** Heart it into the wishlist, add it to the cart, or use
   **Buy Now** to go straight to checkout.
4. **Check out.** Enter shipping on one page (prefilled from the last order),
   review items and totals, and place the order.
5. **Track.** A confirmation screen leads to the order's status timeline.
   Order history lists every past order, with filters.

## Features

**Account**
- Sign up, sign in, sign out; an inline error on failed sign-in
- Account page with order, wishlist and review counts, recent orders and the
  last shipping address

**Catalog**
- 8 categories and 110 products, each with a photo; a designed fallback tile
  shows only if a photo fails to load
- Full-text search on name and description (Postgres `tsearch`, prefix match)
- Filters: category, price range, in stock only, on sale, minimum rating
- Sorting: featured, price (low→high / high→low), newest, top rated, and best
  match when searching
- 24 products per page, grid or list view, removable filter chips, and a
  filter drawer on mobile

**Product page**
- Price, compare-at price with savings, stock status, specifications from
  product fields, and related products from the same category
- **Reviews from verified purchasers.** Only a user with an order containing
  the product can review it, once per product. The average and count are stored
  on the product for sorting and filtering.

**Wishlist, cart and checkout**
- Wishlist toggle on every product card and on the product page, plus a
  wishlist page
- Cart with quantity controls, remove, **Save for later** (moves the line to the
  wishlist), and a free-shipping progress bar
- **Buy Now** adds the item and goes to checkout
- **Stock validation** on every add, update and checkout
- One-page checkout (shipping → payment → review). Payment is a clearly
  labelled demo step, so no card is taken.
- **Shipping:** a flat $5.99 under $50, free from $50. The charge is stored on
  the order.

**Orders**
- Order history filtered by status (all, processing, shipped, delivered,
  cancelled)
- Order details: a status timeline, items at the **price paid** (snapshotted
  at purchase), shipping address, payment and totals, plus **Buy again**
- A confirmation panel on the first view of a newly placed order

**Discovery**
- **Today's featured deals** with a countdown. The set is chosen from on-sale
  products, seeded by the date, so it really changes at midnight (server time,
  UTC).
- **Popular** is ranked by units sold. **Recommended for you** shows top-rated
  products in the categories the shopper has bought from; guests see top rated
  overall.
- **Recently viewed** products are kept in the session.
- **Newsletter signup**, stored in the database

**Experience**
- **Responsive** layouts for mobile, tablet and desktop, including a mobile nav
  drawer and sticky action bars
- **Accessibility:**
  - labelled fields, visible focus rings and a skip link
  - 44px touch targets and AA text contrast
  - semantic headings, and `aria-live` regions for cart and toast updates
  - a reduced-motion setting is respected

## Backend architecture

- **Thin controllers, business logic in services.**
  - `Carts::CartService`: add, update, remove and save for later, with stock
    checks and quantity merging.
  - `Orders::CheckoutService`: turns a cart into an order in a single
    transaction.
  - `Reviews::CreateService`: enforces the buyer rule and updates the
    product's rating aggregates.
- **Concurrency-safe checkout.** Product rows are locked in stable id order,
  stock is re-validated under the lock and then decremented, so two checkouts
  can't both buy the last unit. Concurrent cart adds retry on the unique index
  instead of raising an error.
- **Money is integer cents** and is displayed only through
  `format_price_cents`. `OrderItem#price_cents` and `Order#shipping_cents` are
  purchase-time snapshots.
- **Hotwire over an API layer.** Cart, wishlist and newsletter actions answer
  with Turbo Streams that update every affected element in place. The core
  actions (add to cart, wishlist, checkout, search, sort) are ordinary HTML
  forms and links that work without JavaScript.

## Database-backed functionality

| Feature | Storage |
| --- | --- |
| Products, categories, stock | `products`, `categories` |
| Sale prices | `products.compare_at_price_cents` (DB check: must exceed `price_cents`) |
| Reviews and ratings | `reviews` (unique per user and product, rating 1–5 check), plus `products.reviews_count` / `rating_average` |
| Wishlist, save for later | `wishlist_items` (unique per user and product) |
| Cart | `carts`, `cart_items` (unique per cart and product) |
| Orders | `orders` (status, shipping snapshot), `order_items` (price snapshot) |
| Newsletter | `newsletter_subscriptions` (unique email) |

**Seed data** (`db/seeds.rb`, `db/seeds/storefront.rb`; safe to re-run):
- **Catalog:** 110 products in 8 categories, each with an Unsplash photo
  (`db/seeds/product_images.yml`). 98 show that kind of product; 12 (nine
  books and three items with no clean product shot) use a representative
  photo, because book covers are copyrighted. 23 products carry a
  compare-at price.
- **Reviews:** these come from **12 seeded buyer accounts**. Each buyer has a
  delivered order containing every product they review, so the seeded data
  follows the same buyer rule the app enforces. Their passwords are random, so
  they can't be signed into.
- **Demo account:** orders in several statuses and a small wishlist. Order
  statuses beyond "Processing" exist through seed data only; there is no admin
  tool that moves orders forward.

## Security and authorization

- **Scoped lookups.** Every user-owned record is loaded through `current_user`
  (`current_user.orders.find`, `current_user.cart`, and so on), so another
  user's id returns 404. Pundit policies then authorize the cart, orders and
  wishlist items.
- **Sign-in required** for the cart, checkout, orders, wishlist, account and
  reviews. Guests are redirected to sign in.
- **Input handling.** Strong parameters on every form. Sort keys, filter values
  and info-page names are checked against allow-lists and never interpolated
  into SQL or render paths.
- **Framework protection.** Passwords are hashed with bcrypt, and Rails CSRF
  protection is on. Brakeman reports no warnings.

## Testing

291 examples: 263 model, service, helper and request specs, plus 28 browser
(system) specs.

- `spec/models`, `spec/services`: validations, stock rules, price and shipping
  snapshots, review aggregates, save for later
- `spec/requests`: every controller over HTML and Turbo Stream, including
  guest redirects, other-user 404s and `turbo-stream` targets
- `spec/system`: guest browsing, the purchase flow, the account menu, the
  wishlist and Buy Now, and a **mobile checkout layout** check at true
  390/375/360px viewports

```bash
bin/docker-dev test       # everything except system specs
bin/docker-dev system     # system specs in headless Chrome (selenium service)
bin/docker-dev lint       # RuboCop
bin/docker-dev security   # Brakeman
```

## Local setup

**With Docker (recommended).** Only Docker is needed.

```bash
git clone https://github.com/Adil-Ashraf/amazon-clone.git
cd amazon-clone
docker compose up          # builds the image, prepares the DB, starts Rails + Tailwind
bin/docker-dev seed        # in a second terminal: catalog, reviews, demo account
```

Open http://localhost:3000. Postgres is exposed on host port 5433.

**Without Docker** (Ruby 3.4.10 and PostgreSQL):

```bash
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/dev
```

## Demo account

```
email:    demo@example.com
password: password123
```

The sign-in page also shows these credentials.

## Live deployment

The app runs on Railway from the repository's `Dockerfile`. On boot the
container runs `bin/rails db:prepare`, which applies pending migrations.
Seeding is a one-off step: after deploying new seed data, run
`bin/rails db:seed` once against production. It is safe to repeat.

**Live app:** https://amazon-clone-production-4093.up.railway.app/

## Not included

- **Real payments.** Checkout uses a labelled demo payment, and no card
  details are collected.
- **Also not built:** tax calculation, product variants, password reset,
  account settings, seller accounts and an admin panel. See
  [`docs/DESIGN.md`](docs/DESIGN.md) §7 for the reasoning.

## Credits

Product photos from Unsplash (Unsplash License).
