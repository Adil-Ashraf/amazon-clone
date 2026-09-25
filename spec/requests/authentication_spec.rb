require "rails_helper"

RSpec.describe "Authentication", type: :request do
  let(:user) { create(:user, :with_cart) }

  def visit_cart
    get cart_path
  end

  describe "POST /registration" do
    let(:valid_params) do
      { name: "New User", email: "new@example.com", password: "password123", password_confirmation: "password123" }
    end
    let(:invalid_params) do
      { name: "", email: "bad", password: "short", password_confirmation: "nope" }
    end

    def sign_up(attributes)
      post registration_path, params: { user: attributes }
    end

    context "with valid details" do
      it "creates a user and a cart" do
        expect { sign_up(valid_params) }.to change(User, :count).by(1).and change(Cart, :count).by(1)
      end

      context "after signing up" do
        before { sign_up(valid_params) }

        it { expect(response).to redirect_to(root_path) }

        it "gives the new user a cart" do
          expect(User.find_by!(email: "new@example.com").cart).to be_present
        end
      end

      context "when visiting the cart afterwards" do
        before do
          sign_up(valid_params)
          visit_cart
        end

        it "is signed in" do
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context "with invalid details" do
      it "creates no user or cart" do
        expect { sign_up(invalid_params) }.not_to change { [ User.count, Cart.count ] }
      end

      context "after the request" do
        before { sign_up(invalid_params) }

        it { expect(response).to have_http_status(:unprocessable_content) }
      end
    end
  end

  describe "POST /session" do
    context "with valid credentials" do
      before { sign_in_as(user) }

      it { expect(response).to redirect_to(root_path) }

      context "when visiting the cart afterwards" do
        before { visit_cart }

        it "is signed in" do
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context "with an invalid password" do
      before { sign_in_as(user, password: "wrong-password") }

      it { expect(response).to have_http_status(:unprocessable_content) }

      context "when visiting the cart afterwards" do
        before { visit_cart }

        it "is not signed in" do
          expect(response).to redirect_to(new_session_path)
        end
      end
    end
  end

  describe "DELETE /session" do
    def sign_out
      delete session_path
    end

    before do
      sign_in_as(user)
      sign_out
    end

    it { expect(response).to redirect_to(root_path) }

    context "when visiting the cart afterwards" do
      before { visit_cart }

      it "is signed out" do
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
