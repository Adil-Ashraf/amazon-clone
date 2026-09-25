---
paths:
  - "app/javascript/**"
  - "config/importmap.rb"
---

# JavaScript Conventions

- Behavior is Stimulus controllers in `app/javascript/controllers/`, loaded
  via importmap (`pin_all_from "app/javascript/controllers"`). There is no
  Node bundler.
- Keep controllers small and single-purpose, like `dismissible_controller`
  (removes itself), `quantity_stepper_controller` (−/+ within a max) and
  `live_search_controller` (debounced search into a Turbo Frame).
- Use Stimulus `targets`, `values` and `data-action` instead of
  `querySelector` and manual `addEventListener`. Configuration comes from
  `data-*-value` attributes computed server-side (e.g. the stepper's `max`).
- Clean up in `disconnect()`: clear timers (`clearTimeout(this.timeout)`),
  remove listeners and observers added outside Stimulus actions.
- No inline `<script>` tags or `onclick=` attributes in views.
- Pin third-party packages with `bin/importmap pin <package>` (run through
  `bin/docker-dev bash`); never vendor copies by hand.
- Progressive enhancement: every feature must work as plain HTML first
  (forms submit, links navigate); Stimulus and Turbo only make it nicer. Live
  search enhances a normal search form that still works on Enter.
- Prefer Turbo Frames/Streams from the server over client-side rendering;
  don't build HTML strings in JavaScript.
