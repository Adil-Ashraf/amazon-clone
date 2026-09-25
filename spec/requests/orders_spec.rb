require "rails_helper"

RSpec.describe "Orders", type: :request do
  let(:user) { create(:user) }
  let!(:own_order) { create(:order, user: user) }
  let!(:other_order) { create(:order) }

  describe "GET /orders" do
    def get_orders
      get orders_path
    end

    context "as a guest" do
      before { get_orders }

      it { expect(response).to redirect_to(new_session_path) }
    end

    context "when signed in" do
      before do
        sign_in_as(user)
        get_orders
      end

      it { expect(response).to have_http_status(:ok) }

      it "links only to the current user's orders" do
        expect(response_link_hrefs).to include(order_path(own_order)).and exclude(order_path(other_order))
      end
    end
  end

  describe "GET /orders/:id" do
    def get_order(order)
      get order_path(order)
    end

    before { sign_in_as(user) }

    context "for the current user's order" do
      before { get_order(own_order) }

      it { expect(response).to have_http_status(:ok) }
    end

    context "for another user's order" do
      before { get_order(other_order) }

      it { expect(response).to have_http_status(:not_found) }
    end
  end

  describe "GET /orders?status=" do
    let!(:delivered) { create(:order, user: user, status: :delivered) }

    before { sign_in_as(user) }

    context "filtered to delivered" do
      before { get orders_path(status: "delivered") }

      it "lists only delivered orders" do
        expect(response_link_hrefs).to include(order_path(delivered)).and exclude(order_path(own_order))
      end
    end

    context "with an unknown status" do
      before { get orders_path(status: "bogus") }

      it "lists every order" do
        expect(response_link_hrefs).to include(order_path(delivered), order_path(own_order))
      end
    end
  end
end
