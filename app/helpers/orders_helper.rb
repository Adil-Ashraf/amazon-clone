module OrdersHelper
  STATUS_LABELS = {
    "pending" => "Awaiting payment",
    "paid" => "Processing",
    "shipped" => "Shipped",
    "out_for_delivery" => "Out for delivery",
    "delivered" => "Delivered",
    "cancelled" => "Cancelled"
  }.freeze

  STATUS_PILL_CLASSES = {
    "pending" => "bg-subtle text-muted-strong",
    "paid" => "bg-warn-soft text-warn-strong",
    "shipped" => "bg-brand-soft text-brand-strong",
    "out_for_delivery" => "bg-brand-soft text-brand-strong",
    "delivered" => "bg-success-soft text-success",
    "cancelled" => "bg-danger-soft text-danger"
  }.freeze

  # The delivery timeline, in order. Each step is reached once the order's
  # status is at or past it; a cancelled order has no timeline.
  TIMELINE = [
    [ "Confirmed", %w[pending paid shipped out_for_delivery delivered] ],
    [ "Processing", %w[paid shipped out_for_delivery delivered] ],
    [ "Shipped", %w[shipped out_for_delivery delivered] ],
    [ "Out for delivery", %w[out_for_delivery delivered] ],
    [ "Delivered", %w[delivered] ]
  ].freeze

  def order_status_pill(order)
    content_tag :span, class: "pill #{STATUS_PILL_CLASSES.fetch(order.status)}" do
      concat content_tag(:span, "", class: "size-1.5 rounded-full bg-current")
      concat STATUS_LABELS.fetch(order.status)
    end
  end

  # [[label, reached?, current?], ...]
  def order_timeline_steps(order)
    reached = TIMELINE.map { |label, statuses| [ label, statuses.include?(order.status) ] }
    current_index = reached.rindex { |_, done| done }
    reached.each_with_index.map { |(label, done), index| [ label, done, index == current_index ] }
  end

  def order_number(order)
    "##{order.id.to_s.rjust(4, '0')}"
  end
end
