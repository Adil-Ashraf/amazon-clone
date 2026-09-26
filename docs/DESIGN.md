# Aisle Market — Design Spec

This is the single source of truth for the frontend. Read it before any view,
CSS or Stimulus work. Tokens and component classes live in
`app/assets/tailwind/application.css`; if something you need isn't here, add it
here first, then add the token or class.

## 1. Product stance

**Aisle Market — Better products. Better everyday.**

Premium, warm, minimal, trustworthy. Amazon is the functional reference only;
layout, type, colour and interaction are our own.

- **Every signal is real.** Ratings, "was" prices, deals, stock, shipping,
  order status and recommendations all come from the database. If the backend
  doesn't know it, the UI doesn't say it (see section 6).
- **Calm density.** Enough to decide from the grid (image, category, name,
  rating, price, one action), never a wall of badges.
- **Orange means act.** Roughly 70% warm neutrals, 20% ink type, 10% orange.
  Orange marks the primary action, the active state, sale prices and nothing
  else.

## 2. Vocabulary

The UI says **cart** ("Add to Cart", "Your Cart", "Added to your cart").
Buttons use Title Case for the primary commerce actions from the brief
(Add to Cart, Buy Now, Proceed to Checkout, Place Order, Shop Now); everything
else is sentence case. No exclamation marks.

Stock copy (`stock_badge` in `app/helpers/products_helper.rb`):

| State                                        | Copy        | Tone    |
| -------------------------------------------- | ----------- | ------- |
| `stock > Product::LOW_STOCK_THRESHOLD`       | In stock    | success |
| `0 < stock <= Product::LOW_STOCK_THRESHOLD`  | Only N left | warn    |
| `stock == 0`                                 | Sold out    | danger  |

Order status copy (`OrdersHelper::STATUS_LABELS`): `paid` shows as
**Processing**; the rest read as their name.

## 3. Tokens

### Color

| Token            | Hex       | Use                                                           |
| ---------------- | --------- | ------------------------------------------------------------- |
| `bg`             | `#F8F6F2` | Warm ivory page background                                    |
| `surface`        | `#FFFFFF` | Cards, forms, dropdowns, drawers                              |
| `subtle`         | `#F3F1EC` | Hover fills, image wells                                      |
| `ink`            | `#172033` | Headings, product names, body                                 |
| `muted`          | `#667085` | Descriptions, metadata on `bg` / `surface` (4.6:1 on `bg`)    |
| `muted-strong`   | `#4B5565` | Secondary text on tinted surfaces (`subtle`, washes, `brand-soft`), where `muted` drops under 4.5:1 |
| `line`           | `#E7E5E0` | Borders                                                       |
| `divider`        | `#EEECE7` | Rules inside cards                                            |
| `brand`          | `#F97316` | Aisle Orange — fills without text: dots, bars, stars, focus ring, badges with ink text |
| `brand-strong`   | `#C2410C` | Primary buttons and orange text (5.2:1 with white)            |
| `brand-deep`     | `#9A3412` | Primary button hover                                          |
| `brand-soft`     | `#FFF1E7` | Deals section, selected chips, highlights                     |
| `success` / `-soft` | `#198754` / `#EAF7F0` | In stock, delivered, success toasts          |
| `danger` / `-soft`  | `#DC2626` / `#FEF2F2` | Errors, sold out, cancelled, remove          |
| `warn` / `warn-strong` / `-soft` | `#D97706` / `#B45309` / `#FEF6E7` | Low stock, processing (text uses `warn-strong`) |
| `wash-peach` `wash-sage` `wash-sky` `wash-sand` | pastels | Promo banners, hero, auth panel |
| `stone`          | `#F1EEE7` | No-photo product tiles (with `bg`, `subtle`, `brand-soft`; icon in `brand-strong`) |

**Why two oranges:** white text on `#F97316` is 2.8:1 and fails WCAG AA.
The brand hue stays for everything that isn't text-on-orange; buttons and
orange text use `brand-strong` from the same family.

Use tokens as utilities (`bg-surface`, `text-muted`, `border-line`,
`bg-brand-soft text-brand-strong`). No raw hex and no stock palettes
(`gray-*`, `amber-*`) in markup.

### Type

Inter only (400 / 500 / 600 / 700), fallbacks `ui-sans-serif, system-ui`.

| Role         | Class / size                         | Weight |
| ------------ | ------------------------------------ | ------ |
| Hero H1      | `.h1` 30 → 36 → 48px (home only)     | 600    |
| Page title   | `.page-title` 28 → 32 → 40px (every other `<h1>`) | 600 |
| H2           | `.h2` 24 → 28 → 32px                 | 600    |
| H3           | `.h3` 20 → 22px                      | 600    |
| Body         | 15–17px, line-height 1.5             | 400    |
| Small        | 13–14px                              | 400–500 |
| Product name | 14–15px on cards, 26–36px on the product page | 500–600 |
| Price        | `.price` 18–20px cards, 28–32px product page, tabular | 700 |
| Eyebrow      | `.eyebrow` 12px uppercase, tracked, `brand-strong` | 600 |

### Layout and shape

- Content: `.page` = `max-w-[1280px]`, padding 16 / 24 / 40px
  (mobile / tablet / desktop).
- Spacing scale 4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · 48 · 64 · 80. Sections on
  the home page are 56px apart on mobile, 80px on desktop.
- Radius: hero and large panels 20px (`rounded-hero`), cards 16px
  (`rounded-2xl`), product cards 12px (`rounded-xl`), buttons and inputs
  10px (`rounded-btn`), badges and chips pill.
- Depth is 1px `line` borders. Shadows only float: dropdowns, drawers,
  toasts (`shadow-float`), and a hover lift on cards (`shadow-lift`).
- Money in promotional copy drops zero cents (`format_price_cents(cents, trim: true)` → "$50"); transaction amounts keep them.
- Grid and flex children that hold long text get `min-w-0`, so a long product name wraps instead of widening the page.
- Motion: 150–250ms on opacity, colour and transform only, all behind
  `motion-safe:` or `prefers-reduced-motion`.
- Focus: `focus-visible` 2px `brand` ring with offset. Touch targets ≥ 44px.

## 4. Components

| Class / partial            | Intent                                                                 |
| -------------------------- | ---------------------------------------------------------------------- |
| `.btn-primary`             | The main action. `brand-strong` fill, white text, 44–48px. Product page Add to Cart and Buy-flow buttons, Proceed to Checkout, Place Order. |
| `.btn-card`                | Add to Cart on product cards: neutral outline, orange on hover. Keeps grids calm. |
| `.btn-secondary`           | Alternative action. White, 1px ink border, ink text.                   |
| `.btn-tertiary`            | Low emphasis, no fill until hover.                                     |
| `.btn-danger`              | Destructive (Remove): red text, soft red hover.                        |
| `.btn-lg` / `.icon-btn`    | 48px size / 44px round icon button.                                    |
| `.input` / `.label`        | 48px field, 10px radius, orange border + ring on focus, `aria-invalid` turns it red. |
| `.card`                    | White, 16px radius, line border.                                       |
| `.chip` / `.chip-active`   | Filter pill; active is `brand-soft` with orange border.                |
| `.selected`                | The same orange selected state for small controls (current page, grid/list). **Rule: orange = active / selected / primary action; ink and neutral = normal.** |
| `.pill`                    | Status badge with a dot (stock, order status).                         |
| `.eyebrow` `.h1–.h3` `.price` `.link` `.quiet-link` | Type roles.                                   |
| `.drawer` (`<dialog>`)     | Slide-over for mobile nav and filters (`drawer_controller`).           |
| `products/_product_card`   | Image (1:1) with heart and small discount badge; category, name, rating, price in ink (a struck-through "was" price marks a sale), low-stock note, full-width `.btn-card`. Hover: lift 2px, image scales 1.04. |
| `product_image_tag`        | Unsplash photos get a 400–1200w `srcset` (default `src` 600w) and a `sizes:` preset (`:card`, `:detail`, `:thumb`). A neutral `subtle` well shows while loading; the icon tile appears only if the photo fails. |
| `products/_product_row`    | List-view version of the card.                                         |
| `products/_wishlist_toggle`, `_quick_add` | Updated in place by Turbo Streams. They use **class** targets (`targets=".wishlist_product_1"`) because one product can appear in several rails on a page. |
| `rating_summary`, `rating_stars`, `price_tag`, `discount_badge`, `stock_badge` | `ProductsHelper`. Rating shows nothing but "No reviews yet" when there are none. |
| `icon(name)`               | `IconsHelper`: one 1.75-stroke line icon set for the whole UI.         |
| `shared/_section_heading`, `_empty_state`, `_toast`, `_error_messages` | Shared building blocks. Every empty state has one sentence and one action. |

## 5. Pages

| Page            | Shape |
| --------------- | ----- |
| Header          | Logo · pill search (live results on the catalog, `live_search_controller`; plus a suggestions dropdown on every page, `search_suggest_controller`) · Orders · Wishlist · Account menu · Cart with count. Second row: Shop, Deals, New arrivals, Categories menu, the five largest categories, Help · Sell on Aisle Market. Below `lg`: menu button (drawer), logo, search toggle, cart. |
| Home            | Hero (real top-rated photos) → category circles → Today's Featured Deals with countdown → three promo banners → Popular (units sold) → Recommended / Top rated → trust row → Recently viewed → newsletter. |
| Catalog         | Sidebar filters (category, price, availability, rating) that become a drawer below `lg`; toolbar with count, sort, grid/list; removable filter chips; 1 / 2 / 3 / 4 columns at <340 / mobile / tablet / desktop. |
| Product         | Sticky image left; category, title, rating, price and savings, stock, description, qty + Add to Cart, Buy Now, wishlist; trust grid; Description, Specifications (real fields), Reviews; You may also like; Recently viewed. Mobile: sticky price + Add to Cart bar. |
| Cart            | Free-shipping progress, lines with − / + / Save for later / Remove, sticky summary (subtotal, shipping, total). Saved for later below. Mobile: sticky total + Checkout. |
| Checkout        | Own layout (logo + Secure Checkout, no nav). Steps 1 Shipping · 2 Payment · 3 Review on one page; address prefilled from the last order; sticky summary with Place Order. |
| Orders / order  | Status filter chips; order cards. Detail: timeline horizontal on desktop, vertical on mobile, showing only steps actually reached; products (with Buy again), address, payment, summary. |
| Wishlist, Account, Sign in / up, info pages | Product grid; profile, counts, recent orders, last address; split brand panel + form; short honest policy pages. |

## 6. Where each signal comes from

| UI                         | Backed by |
| -------------------------- | --------- |
| Rating + review count      | `reviews` table; `products.reviews_count` (counter cache) and `rating_average` kept by `Reviews::CreateService`. Only buyers can review. |
| Previous price, discount %, Deals | `products.compare_at_price_cents` (DB check: above `price_cents`). |
| Today's deals + countdown  | On-sale products shuffled with the date as seed; the set really changes at midnight. |
| Popular                    | `Product.popular`: units sold, then review count. |
| Recommended for you        | Top rated in categories the shopper bought from, excluding what they bought. Guests see "Top rated by customers". |
| Recently viewed            | Product ids in the session. |
| Wishlist, Save for later   | `wishlist_items`; Save for later moves a cart line there (`CartService#save_for_later`). |
| Shipping, free over $50    | `Order.shipping_cents_for`; charged and snapshotted in `orders.shipping_cents` by `CheckoutService`. |
| Order timeline + filters   | `orders.status` enum: pending, paid, shipped, out_for_delivery, delivered, cancelled. |
| Newsletter                 | `newsletter_subscriptions`. |

## 7. Not built, on purpose

| Item                  | Why |
| --------------------- | --- |
| Variants (size/colour) | No variant data; inventing options would be a fake signal. |
| Tax line              | No tax rules; a made-up number would be wrong. |
| Forgot password       | Needs a mailer flow; the link explains the demo account instead. |
| Account settings      | No editable settings beyond what signup collects. |
| Image gallery thumbnails | One photo per product; repeating it as thumbnails adds nothing. |
| Sponsored placements, mega-menu, 6-column grid | Work against clarity. |
