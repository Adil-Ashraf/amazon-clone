# Layer Interactions

Detailed examples of how architectural layers communicate in a Rails 8 application.

## Request Flow Example

A complete example showing how layers interact for creating an event with vendors.

### 1. Controller (Entry Point)

```ruby
# app/controllers/events_controller.rb
class EventsController < ApplicationController
  def create
    # 1. Authorization (Policy)
    authorize Event

    @form = EventCreationForm.new(event_params)

    if @form.valid?
      # 3. Delegate to Service
      result = Events::CreateService.new.call(
        account: current_account,
        params: @form.attributes
      )

      if result.success?
        # 4. Background job for notifications
        EventCreatedJob.perform_later(result.data.id)

        redirect_to result.data, notice: t(".success")
      else
        flash.now[:alert] = result.error
        render :new, status: :unprocessable_entity
      end
    else
      render :new, status: :unprocessable_entity
    end
  end
end
```

### 3. Service Object (Business Logic)

```ruby
# app/services/events/create_service.rb
module Events
  class CreateService < ApplicationService
    def call(account:, params:)
      event = nil

      ActiveRecord::Base.transaction do
        # Create event
        event = account.events.create!(
          name: params[:name],
          event_date: params[:event_date],
          event_type: params[:event_type]
        )

        # Attach vendors
        attach_vendors(event, params[:vendor_ids])

        # Update statistics
        update_account_stats(account)
      end

      success(event)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message, :validation_error)
    end

    private

    def attach_vendors(event, vendor_ids)
      return if vendor_ids.blank?

      vendor_ids.each do |vendor_id|
        event.event_vendors.create!(vendor_id: vendor_id)
      end
    end

    def update_account_stats(account)
      # Could use a Query Object here
      account.update_column(:events_count, account.events.count)
    end
  end
end
```

### 4. Model (Data & Validations)

```ruby
# app/models/event.rb
class Event < ApplicationRecord
  belongs_to :account
  has_many :event_vendors, dependent: :destroy
  has_many :vendors, through: :event_vendors

  validates :name, presence: true
  validates :event_date, presence: true

  enum :event_type, { wedding: 0, corporate: 1, private: 2 }
  enum :status, { draft: 0, confirmed: 1, completed: 2, cancelled: 3 }

  scope :upcoming, -> { where("event_date >= ?", Date.current) }
  scope :recent, -> { order(created_at: :desc) }
end
```

### 5. Policy (Authorization)

```ruby
# app/policies/event_policy.rb
class EventPolicy < ApplicationPolicy
  def create?
    user.account_id.present?
  end

  def show?
    owner?
  end

  def update?
    owner? && !record.completed?
  end

  private

  def owner?
    record.account_id == user.account_id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(account_id: user.account_id)
    end
  end
end
```

### 6. Background Job (Async Processing)

```ruby
# app/jobs/event_created_job.rb
class EventCreatedJob < ApplicationJob
  queue_as :default

  def perform(event_id)
    event = Event.find(event_id)

    # Send email notification
    EventMailer.created(event).deliver_later

    # Broadcast to dashboard
    DashboardChannel.broadcast_stats(event.account)

    # Log activity
    ActivityService.new.log(
      account: event.account,
      action: :event_created,
      resource: event
    )
  end
end
```

### 7. Mailer (Email)

```ruby
# app/mailers/event_mailer.rb
class EventMailer < ApplicationMailer
  def created(event)
    @event = event
    @user = event.account.users.first

    mail(
      to: @user.email_address,
      subject: t(".subject", name: event.name)
    )
  end
end
```

### 8. Query Object (Complex Queries)

```ruby
# app/queries/dashboard_stats_query.rb
class DashboardStatsQuery
  attr_reader :account

  def initialize(account:)
    @account = account
  end

  def call
    {
      total_events: account.events.count,
      upcoming_events: upcoming_events_count,
      events_by_type: events_by_type,
      recent_events: recent_events
    }
  end

  private

  def upcoming_events_count
    account.events.upcoming.count
  end

  def events_by_type
    account.events.group(:event_type).count
  end

  def recent_events
    account.events.recent.limit(5)
  end
end
```

## Layer Communication Rules

### Who Can Call Whom

```
Controller → Service, Query, Policy, Form
Service    → Model, Query, Job, Mailer, Channel
Query      → Model (read-only)
Job        → Service, Mailer, Channel
Serializer → Model (read-only)
Channel    → Query (for broadcasting data)
```

### Who Should NOT Call Whom

```
Model      → Controller, Service, Job (avoid callbacks that do this)
Serializer → Service, Job (no side effects)
Query      → Service, Job (read-only)
Component  → Service, Job (presentation only)
```

## Data Flow Patterns

### Pattern 1: Simple CRUD

```
Request → Controller → Model → View
```

### Pattern 2: Complex Business Logic

```
Request → Controller → Policy → Use Case → Model → Serializer → Response
                    ↘ Job → Mailer
```

## Testing Each Layer

| Layer | Test Type | What to Test |
|-------|-----------|--------------|
| Controller | Request spec | HTTP flow, status codes, redirects |
| Service | Unit spec | Business logic, Result object |
| Query | Unit spec | SQL results, tenant isolation |
| Model | Model spec | Validations, associations, scopes |
| Policy | Policy spec | Authorization rules |
| Form | Unit spec | Validations, attribute handling |
| Serializer | Unit spec | Approved fields, sensitive-field exclusion |
| Component | Component spec | Rendering |
| Job | Job spec | Execution, side effects |
| Mailer | Mailer spec | Recipients, content |
| Channel | Channel spec | Subscriptions, broadcasts |
