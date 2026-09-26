RSpec::Matchers.define_negated_matcher :exclude, :include

# expect { get cart_path }.not_to lazy_load_categories
# Fails when a product's category is fetched one row at a time (an N+1);
# a preloaded category arrives in a single `IN (...)` query instead.
RSpec::Matchers.define :lazy_load_categories do
  supports_block_expectations

  match do |block|
    @lookups = 0
    counter = lambda do |*, payload|
      @lookups += 1 if payload[:sql].match?(/FROM "categories" WHERE "categories"\."id" = /)
    end
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    @lookups.positive?
  end

  failure_message_when_negated do
    "expected categories to be preloaded, but saw #{@lookups} single-category lookups"
  end
end
