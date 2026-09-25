# Active Storage: Controllers, Service Methods, and Performance

## Controller: Single Upload

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  def update
    if @user.update(user_params)
      redirect_to @user, notice: "Profile updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :avatar)
  end
end
```

## Controller: Multiple Uploads

```ruby
# app/controllers/events_controller.rb
class EventsController < ApplicationController
  def update
    if @event.update(event_params)
      redirect_to @event, notice: "Event updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def event_params
    params.require(:event).permit(:name, :description, photos: [], documents: [])
  end
end
```

## Controller: Removing Attachments

```ruby
class UsersController < ApplicationController
  def remove_avatar
    user = current_user
    user.avatar.purge
    redirect_to edit_user_path(user), notice: "Avatar removed."
  end
end
```

## Service Methods

```ruby
# Check if attached
user.avatar.attached?

# Get URL (requires controller context or url_for)
url_for(user.avatar)
rails_blob_path(user.avatar, disposition: "attachment")

# Get filename
user.avatar.filename.to_s

# Get content type
user.avatar.content_type

# Get byte size
user.avatar.byte_size
```

## Downloading / Streaming

```ruby
# In controller - redirect to blob URL
def download
  @document = Document.find(params[:id])
  redirect_to rails_blob_path(@document.file, disposition: "attachment")
end

# Or stream directly
def download
  @document = Document.find(params[:id])
  send_data @document.file.download,
            filename: @document.file.filename.to_s,
            content_type: @document.file.content_type
end
```

## Performance: Eager Loading

```ruby
# Prevent N+1 on attachments
User.with_attached_avatar.limit(10)

# Multiple attachments
Event.with_attached_photos.with_attached_documents
```

## Performance: Preloading Variants

```ruby
# In controller
@users = User.with_attached_avatar.limit(10)

# Preload variants
@users.each do |user|
  user.avatar.variant(:thumb).processed if user.avatar.attached?
end
```
