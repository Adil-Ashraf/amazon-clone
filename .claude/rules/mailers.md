---
paths:
  - "app/mailers/**"
  - "app/views/**/*_mailer/**"
  - "spec/mailers/**"
---

# Mailer Conventions

- Always provide both HTML and text templates
- Use `deliver_later` (async via Solid Queue), never `deliver_now` in controllers
- Create mailer previews in `spec/mailers/previews/`
- Test with `have_enqueued_mail(MailerClass, :method_name)`
- Keep mailer logic minimal -- formatting belongs in helpers (prices via `format_price_cents`)
- Mail goes to the owning user only (`order.user.email`)
