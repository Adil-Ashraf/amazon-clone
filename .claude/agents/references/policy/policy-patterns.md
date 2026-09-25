# Pundit Policy Patterns Reference

Isolation in this app is per user. The roles are **owner**, **another
signed-in user** and **guest** (`user` is `nil`). There is no admin role and
no multi-tenancy. Controllers scope lookups through `current_user`
associations first (so another user's record is a 404) and call `authorize`
second.

## ApplicationPolicy Base Class

```ruby
# app/policies/application_policy.rb (generated; denies everything)
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index? = false
  def show? = false
  def create? = false
  def new? = create?
  def update? = false
  def edit? = update?
  def destroy? = false

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end
end
```

## 1. Owner-Only Policy (the pattern used today)

```ruby
# app/policies/cart_policy.rb
class CartPolicy < ApplicationPolicy
  def show?
    owner?
  end

  def update?
    owner?
  end

  private

  def owner?
    user.present? && record.user_id == user.id
  end
end
```

```ruby
# app/policies/order_policy.rb
class OrderPolicy < ApplicationPolicy
  def show?
    owner?
  end

  private

  def owner?
    user.present? && record.user_id == user.id
  end
end
```

## 2. Public Read, Owner Write

Anyone (including guests) can read; only the owner can change.

```ruby
class ReviewPolicy < ApplicationPolicy
  def show? = true
  def create? = user.present?
  def update? = owner?
  def destroy? = owner?

  private

  def owner?
    user.present? && record.user_id == user.id
  end
end
```

## 3. State-Dependent Rules

Combine ownership with the record's state; keep each predicate readable.

```ruby
class OrderPolicy < ApplicationPolicy
  def show? = owner?
  def cancel? = owner? && record.pending?

  private

  def owner?
    user.present? && record.user_id == user.id
  end
end
```

## 4. Temporal Conditions

```ruby
class ReviewPolicy < ApplicationPolicy
  EDIT_WINDOW = 24.hours

  def update?
    owner? && record.created_at > EDIT_WINDOW.ago
  end

  private

  def owner?
    user.present? && record.user_id == user.id
  end
end
```

## 5. Scope (only when an association won't do)

Prefer `current_user.orders`. Add a `Scope` only if the list can't be
expressed as a `current_user` association:

```ruby
class ReviewPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    # Published reviews for everyone, plus the viewer's own drafts.
    def resolve
      return scope.published if user.nil?

      scope.published.or(scope.where(user: user))
    end
  end
end
```
