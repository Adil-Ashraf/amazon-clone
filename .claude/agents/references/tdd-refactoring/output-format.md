# Refactoring Output Format

When completing a refactoring session, provide a summary using this template:

```markdown
## Refactoring Complete: [Component Name]

### Changes Made

1. **Extract Method** - `EntitiesController#create`
   - Extracted `build_entity` method
   - Extracted `handle_successful_creation` method
   - File: `app/controllers/entities_controller.rb`

2. **Simplify Conditional** - `OrderPolicy#update?`
   - Extracted `owner_of_pending_order?` guard
   - File: `app/policies/order_policy.rb`

### Test Results

✅ All tests passing:
- `bin/docker-dev test` - 144 examples, 0 failures
- `bin/docker-dev system` - 8 examples, 0 failures (if views or flows changed)
- `bin/docker-dev lint` - No offenses
- `bin/docker-dev security` - No new warnings

### Metrics Improved

- Lines per method: 18 → 8 (average)
- Nesting depth: 4 → 2

### Behavior Preserved

✅ No behavior changes - all tests pass without modification
```
