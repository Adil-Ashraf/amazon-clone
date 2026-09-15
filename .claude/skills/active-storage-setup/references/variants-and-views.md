# Active Storage: Image Variants

API-only: there are no forms or `image_tag` helpers here. Variants are
generated server-side and exposed to the frontend as URLs through a serializer.

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

## Exposing Variants Through a Serializer

Return URLs, never the attachment object. Use `url_for`/`rails_representation_url`
with an explicit host so the separate frontend gets an absolute URL.

```ruby
class UserSerializer
  def initialize(user:)
    @user = user
  end

  def as_json
    {
      id: user.uuid,
      name: user.name,
      avatar: avatar_urls
    }
  end

  private

  attr_reader :user

  def avatar_urls
    return nil unless user.avatar.attached?

    {
      thumb: variant_url(:thumb),
      medium: variant_url(:medium)
    }
  end

  def variant_url(name)
    Rails.application.routes.url_helpers.rails_representation_url(
      user.avatar.variant(name).processed,
      only_path: false
    )
  end
end
```

## Notes

- Generating a variant is lazy and can be slow on first request. For list
  endpoints, pre-process variants in a background job rather than blocking the
  response.
- Preload `avatar_attachment: :blob` in the query object when serializing a
  collection, or every row triggers its own lookup.
- Signed blob URLs expire. Confirm the expiry window matches what the frontend
  caches.
