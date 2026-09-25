FactoryBot.define do
  factory :order do
    user
    status { :paid }
    total_cents { 1000 }
    shipping_name { "Test User" }
    shipping_address_line1 { "1 Spec Street" }
    shipping_city { "Specville" }
    shipping_state { "CA" }
    shipping_zip { "90210" }
  end
end
