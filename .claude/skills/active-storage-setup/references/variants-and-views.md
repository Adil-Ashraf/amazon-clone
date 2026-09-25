# Active Storage: Image Variants

Variants are defined on the model and rendered in ERB with `image_tag`;
uploads go through ordinary `form_with` file fields.

## Defining Variants

```ruby
class User < ApplicationRecord
  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_fill: [100, 100]
    attachable.variant :medium, resize_to_limit: [300, 300]
    attachable.variant :large, resize_to_limit: [800, 800]
  end
end
```

## Variant Operations Reference

```ruby
# Resize to fit within dimensions (maintains aspect ratio)
resize_to_limit: [300, 300]

# Resize and crop to exact dimensions
resize_to_fill: [300, 300]

# Resize to cover dimensions (may exceed)
resize_to_cover: [300, 300]

# Custom processing
resize_to_limit: [300, 300], format: :webp, saver: { quality: 80 }
```

## Displaying Variants in Views

```erb
<%# app/views/users/_avatar.html.erb %>
<% if user.avatar.attached? %>
  <%= image_tag user.avatar.variant(:thumb), alt: user.name, width: 100, height: 100, loading: "lazy" %>
<% else %>
  <%= render "shared/avatar_placeholder", user: user %>
<% end %>
```

- Always give meaningful `alt` text and explicit `width`/`height` to avoid layout shift.
- `loading: "lazy"` for images below the fold.

## Upload Forms

```erb
<%= form_with model: @user do |f| %>
  <%= f.label :avatar %>
  <%= f.file_field :avatar, accept: "image/png,image/jpeg,image/webp", direct_upload: true %>
  <%= f.submit "Save" %>
<% end %>
```

`direct_upload: true` needs `@rails/activestorage` pinned via
`bin/importmap pin @rails/activestorage` and started in `application.js`.

## Notes

- Generating a variant is lazy and can be slow on first request. For list
  pages, pre-process variants in a background job rather than blocking the
  response.
- Preload `avatar_attachment: :blob` (`with_attached_avatar`) when rendering a
  collection, or every row triggers its own lookup.
- Signed blob URLs expire. Don't cache pages that embed them for longer than
  the expiry window.
