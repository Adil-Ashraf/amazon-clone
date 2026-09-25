# Aisle — Design Spec

This is the single source of truth for the frontend. Read it before any view,
CSS or Stimulus work. Tokens and component classes live in
`app/assets/tailwind/application.css`; if something you need isn't here, add it
here first, then add the token or class.

## 1. Product stance

**Aisle — calm, honest shopping.**

- Show only what helps a person decide. Every element on a page has to earn
  its place by answering a question the shopper actually has.
- Never fake a signal. No invented stock pressure, no struck-through "was"
  prices that never existed, no reviews we don't have, no delivery dates with
  no logistics behind them. If the backend doesn't know it, the UI doesn't say
  it.
- Aisle is an original design built on the existing backend, not a restyled
  Amazon. Routes, models and services stay as they are; the experience on top
  of them is ours.

## 2. Vocabulary

The UI says **bag**, never "cart". Routes, controllers, models, services and
Turbo target ids keep their `cart` names — this is a copy rule only.

| Context            | Copy                  |
| ------------------ | --------------------- |
| Add button         | Add to bag            |
| Bag page / drawer  | Your bag              |
| Add confirmation   | Added to your bag     |

Stock copy (from `stock_badge` in `app/helpers/products_helper.rb`):

| State                                               | Copy          | Tone   |
| --------------------------------------------------- | ------------- | ------ |
| `stock > Product::LOW_STOCK_THRESHOLD`              | In stock      | accent |
| `0 < stock <= Product::LOW_STOCK_THRESHOLD`         | Only N left   | warn   |
| `stock == 0`                                        | Sold out      | danger |

Sentence case everywhere ("Sign in", "Place order"), no exclamation marks.

## 3. Tokens

### Color

| Token         | Hex       | Use                                                  |
| ------------- | --------- | ---------------------------------------------------- |
| `bg`          | `#FAF8F5` | Page background                                      |
| `surface`     | `#FFFFFF` | Cards, inputs, drawer, palette                       |
| `subtle`      | `#F3F0EB` | Hover fills, image wells, secondary panels           |
| `ink`         | `#1A1A1A` | Body text, primary button                            |
| `muted`       | `#6B6B6B` | Secondary text, captions, placeholders               |
| `line`        | `#E8E4DE` | All borders and dividers                             |
| `accent`      | `#1F5E4B` | Links, focus ring, active chip, positive state       |
| `accent-soft` | `#E6EFEB` | Positive badge background                            |
| `warn`        | `#B7791F` | Low stock text                                       |
| `warn-soft`   | `#FBF3E4` | Low stock background                                 |
| `danger`      | `#B42318` | Errors, sold out                                     |
| `danger-soft` | `#FDECEA` | Error / sold-out background                          |

Use them as Tailwind utilities: `bg-bg`, `bg-surface`, `text-ink`,
`text-muted`, `border-line`, `bg-accent-soft text-accent`, … No raw hex and no
stock palettes (`gray-*`, `amber-*`) in markup.

### Type

- **Instrument Serif** (`font-display`), weight 400 only. Used for the
  wordmark, page titles, the product name on the product page and the order
  confirmation heading. Nowhere else.
- **Inter** (`font-sans`, the default), weights 400 / 500 / 600 for
  everything else.
- Fallbacks: `ui-sans-serif, system-ui, sans-serif` and `Georgia, serif`.
- Prices always use tabular numerals (`.price` or `tabular-nums`) so columns
  of money line up.

### Layout and shape

- Content width `max-w-6xl mx-auto px-4 sm:px-6`.
- 8px spacing scale: stick to Tailwind steps 2 / 4 / 6 / 8 / 12 / 16
  (8 / 16 / 24 / 32 / 48 / 64px). Use 1 / 3 (4 / 12px) only inside dense
  components.
- Radius: `rounded-xl` cards, `rounded-lg` buttons and inputs, `rounded-full`
  chips and pills.
- Depth comes from 1px `border-line` borders, not shadows. Shadows are allowed
  only on the bag drawer and the search palette, which float above the page.
- Focus: `focus-visible` ring, 2px `accent` with a 2px offset. Never remove an
  outline without this replacement.
- Touch targets are at least 44px (`min-h-11`) in both directions.

## 4. Components

| Class / partial   | Intent                                                                 |
| ----------------- | ---------------------------------------------------------------------- |
| `.btn-primary`    | The one main action on a view. Ink fill, white text.                   |
| `.btn-secondary`  | Alternative actions. Surface fill with a line border.                  |
| `.btn-ghost`      | Low-emphasis actions (remove, cancel, header links). No fill until hover. |
| `.input`          | Text, email, password, number and select fields.                      |
| `.label`          | Field label above an input. Small, medium weight, ink.                 |
| `.card`           | Any contained block: product tile, summary, form panel.               |
| `.chip` / `.chip-active` | Category filters. Active chip is accent-filled.                 |
| `.pill`           | Status indicator (order status, stock). Colors come from the caller.   |
| toast             | Transient confirmation ("Added to your bag"), `role="status"`.         |
| product tile      | `product_image_tag(product)`: category-tinted tile with the category icon and short name. Fills the caller's box. |
| stock badge       | `stock_badge(product)`: pill with a dot, copy per section 2.           |
| qty stepper       | − / count / + with 44px buttons, bounded by available stock.           |
| empty state       | One sentence of what's missing, one action to fix it. No illustration filler. |
| section heading   | Small Inter semibold label above a group; page titles use `font-display`. |

`.btn` is the shared base (size, radius, focus, disabled); each variant
already includes it, so `class="btn-primary"` is enough. `.price` applies tabular numerals and medium weight.

`input_classes` and `card_classes` in `ApplicationHelper` return `input` and
`card` so existing views pick up the new look without changes.

## 5. Cut list

| Cut                          | Why                                                                                 |
| ---------------------------- | ----------------------------------------------------------------------------------- |
| Star ratings and reviews     | The backend has no reviews. Showing empty or invented stars is a fake signal.       |
| "Sponsored" placements       | Paid ranking works against the shopper; results are ordered by relevance only.      |
| Recommendation rails         | No recommendation data exists; filler rails add noise, not help.                    |
| "Buy now"                    | A second competing CTA. One path: add to bag, then check out.                       |
| Countdown / urgency banners  | Manufactured pressure. The stance is calm.                                          |
| Mega-menu                    | The catalog is small; category chips are enough and work on mobile.                 |
| 6-column dense grid          | Too small to read a name and a price at a glance; max 4 columns.                    |
| Fake delivery dates          | No logistics behind them. We don't promise what we can't know.                      |

## 6. Design decisions

| Area | Amazon does X | Aisle does Y | Why |
| ---- | ------------- | ------------ | --- |
| Header | Dense dark bar with location, account menus, many links | Light bar: serif wordmark, search trigger, Orders, bag with count | Fewer destinations, clearer hierarchy |
| Search | Always-open field with a department dropdown | ⌘K / tap-to-open search palette with live results | Frees the header; search is one keystroke away on desktop and one tap on mobile |
| Categories | Hamburger mega-menu | A row of chips above the grid, one active at a time | Visible, scannable, thumb-friendly |
| Grid density + quick-add | Up to 6 columns, tiny tiles, badges everywhere | 2 / 3 / 4 columns, image, name, price, stock; a quick "Add" on the tile | Enough to decide from the grid without opening every product |
| Stock wording | "Only 2 left — order soon", red urgency | "In stock" / "Only N left" / "Sold out" | Factual; the number is real and the tone is neutral |
| Product page | Buy box with Add to cart, Buy now, subscriptions, protection plans | One CTA: Add to bag, with a qty stepper | One decision per page |
| Bag | Full-page cart after every add | Slide-over bag drawer; full page still exists | Keep browsing context; confirm without leaving |
| Checkout | Multi-step flow across several pages | One page: address, items, total, Place order | Everything visible before committing |
| Stock conflicts | Generic error after submit | Name the item, show what's available, offer "Update to N" or "Remove" | The person can fix it in one click |
| Address | Re-entered or picked from a book each time | Prefilled from the last order, editable | Saves typing without hiding anything |
| Order status | Tracking stages with estimated dates | Timeline of only the states the order actually reached | Honest; no invented progress |
| Past prices | Shows current product price on old orders | "Prices shown are what you paid" from the `OrderItem` snapshot | Order history is a record, not a catalog |
| Buy again | Separate "Buy again" storefront | "Buy again" button on past order items, adds to bag | Reorder where the person already is |
| Demo sign-in | Account required, no shortcut | "Continue with demo account" on sign-in | Reviewers can try the full flow instantly |
| Product imagery | Amazon shows seller photos | Aisle shows a consistent designed tile per product | This catalog has no real product photos; showing a photo of a different item would be a fake signal |
| After sign-in | Lands on the home page | Returns to the page that asked for sign-in | Don't lose the person's place |
