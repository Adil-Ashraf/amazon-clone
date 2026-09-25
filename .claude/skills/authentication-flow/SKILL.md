---
name: authentication-flow
description: >-
  Explains and extends this app's hand-rolled authentication: has_secure_password,
  User.authenticate_by, session[:user_id], current_user and require_login in
  ApplicationController. Use when working on sign up, sign in, sign out,
  session handling, or protecting controllers. WHEN NOT: Authorization and
  permissions (use Pundit policies / policy-agent), OAuth/SSO integration, or
  role-based access control (there are no roles).
paths: "app/controllers/application_controller.rb, app/controllers/sessions_controller.rb, app/controllers/registrations_controller.rb, app/models/user.rb"
---

# Authentication in This App

## Overview

Authentication is deliberately small and hand-rolled — no Devise, no Rails 8
authentication generator, no `Session` model, no `Current` attributes. The
whole surface is sign up, sign in and sign out against one `User` model,
with the user id stored in the Rails session cookie.

```
app/
├── models/user.rb                          # has_secure_password
└── controllers/
    ├── application_controller.rb           # current_user, logged_in?, require_login
    ├── sessions_controller.rb              # sign in / sign out  (resource :session)
    └── registrations_controller.rb         # sign up             (resource :registration)
```

## User Model

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password

  has_one :cart, dependent: :destroy
  has_many :orders, dependent: :destroy

  before_validation :downcase_email

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password, length: { minimum: 8 }, allow_nil: true

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end
end
```

- `password_digest` column (bcrypt).
- `allow_nil: true` on the length check lets you update other fields without
  re-entering the password; `has_secure_password` still requires one on create.

## ApplicationController

```ruby
helper_method :current_user, :logged_in?, :cart_item_count, :live_search?

private

def current_user
  @current_user ||= User.find_by(id: session[:user_id])
end

def logged_in?
  current_user.present?
end

def require_login
  return if logged_in?

  redirect_to new_session_path, alert: "Please sign in to continue."
end
```

Protect a controller with `before_action :require_login`. Public pages
(products, sign in, sign up) simply don't add it.

## Sign In / Sign Out

```ruby
# app/controllers/sessions_controller.rb
def create
  user = User.authenticate_by(email: params[:email], password: params[:password])

  if user
    session[:user_id] = user.id
    redirect_to root_path, notice: "Signed in successfully."
  else
    flash.now[:alert] = "Invalid email or password."
    render :new, status: :unprocessable_content
  end
end

def destroy
  reset_session
  redirect_to root_path, notice: "Signed out."
end
```

`User.authenticate_by` runs in constant time whether or not the email exists,
so it doesn't leak which emails are registered.

## Sign Up

```ruby
# app/controllers/registrations_controller.rb
def create
  @user = User.new(registration_params)

  if @user.save
    @user.create_cart!          # every user has exactly one cart
    session[:user_id] = @user.id
    redirect_to root_path, notice: "Welcome, #{@user.name}!"
  else
    render :new, status: :unprocessable_content
  end
end
```

## Using the Signed-In User

```ruby
# Controllers: scope through the user, then authorize
@order = current_user.orders.find(params[:id])
authorize @order
```

```erb
<%# Views %>
<% if logged_in? %>
  Hello, <%= current_user.name %>
<% end %>
```

Models, services and jobs never read the session: pass the user in
explicitly (`Orders::CheckoutService.new(user: current_user, ...)`).

## Testing Authentication

Helpers in `spec/support/authentication_helpers.rb`:

```ruby
sign_in_as(user, password: "password123")      # request specs: POST session_path
sign_in_via_ui(user, password: "password123")  # system specs: fills in the form
```

The user factory's password is `"password123"`.

```ruby
# spec/requests/authentication_spec.rb
describe "POST /session" do
  context "with an invalid password" do
    before { sign_in_as(user, password: "wrong-password") }

    it { expect(response).to have_http_status(:unprocessable_content) }

    context "when visiting the cart afterwards" do
      before { get cart_path }

      it "is not signed in" do
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
```

Every protected action's request spec includes a guest context that expects
`redirect_to(new_session_path)`.

## Hardening to Consider

These aren't in the app yet; add them deliberately, with specs:

- **Session fixation:** call `reset_session` before setting
  `session[:user_id]` in `SessionsController#create` and
  `RegistrationsController#create`.
- **Rate limiting** sign-in attempts:
  ```ruby
  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to new_session_path, alert: "Try again later." }
  ```
- **Password reset** would need a signed, expiring token
  (`generates_token_for :password_reset, expires_in: 15.minutes`) and a mailer.
