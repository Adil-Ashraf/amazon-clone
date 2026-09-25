---
paths:
  - "app/views/**"
  - "app/helpers/**"
  - "app/assets/tailwind/**"
---

# View Conventions

- **Read `docs/DESIGN.md` before any UI work.** It defines the design tokens
  (in `@theme` in `app/assets/tailwind/application.css`) and the component
  classes to use.
- Style with design tokens and component classes only. No raw hex colors and
  no ad-hoc palettes (`gray-*`, `amber-*`, ...) in markup; if a value is
  missing, add a token or component class rather than hard-coding it.
- Reusable UI goes in `app/views/shared/` partials (`_toast`,
  `_cart_count_badge`, `_error_messages`, `_section_heading`, `_empty_state`); feature partials live next to their
  views (`carts/_cart_item`, `products/_product_card`). Pass locals
  explicitly to partials instead of reading instance variables inside them.
- Prices only via `format_price_cents(cents)`. Never format money inline.
- Views read what the controller loaded; they don't query or decide business
  rules. Helpers format and compose markup only.
- Keep Turbo target ids stable (`cart_count`, `cart_items`, `cart_flash`,
  `add_to_cart_status`, the `products_results` frame). Every
  `*.turbo_stream.erb` that targets an id, and the request specs that assert
  it, must change together with the markup. Use `dom_id(record)` for per-record ids.
  Per-product controls that can appear more than once on a page (quick-add,
  wishlist heart) use a `dom_id` **class** and `turbo_stream.replace_all`,
  asserted with `turbo_stream_all_targets` in request specs.
- Accessibility:
  - every input has a `<label>` (or `aria-label` when visually hidden)
  - visible focus styles via `focus-visible:`; never remove outlines without a replacement
  - dynamic regions updated by Turbo Streams (toasts, cart count, flash)
    carry `aria-live="polite"` or `role="status"`
  - touch targets are at least 44×44px
  - images have meaningful `alt` text (empty `alt=""` only if decorative)
- Mobile first: base classes target small screens; add `sm:`/`md:`/`lg:`
  variants for larger ones. No horizontal scrolling at 360px wide.
