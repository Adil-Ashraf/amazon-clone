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

      context "after browsing as a guest" do
        def browse_as_guest
          get product_path(create(:product))
          @guest_session_id = session.id.to_s
        end

        before do
          browse_as_guest
          sign_up(valid_params)
        end

        it "had a guest session to replace" do
          expect(@guest_session_id).to be_present
        end

        it "issues a new session id" do
          expect(session.id.to_s).not_to eq(@guest_session_id)
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

    context "with valid credentials after browsing as a guest" do
      let(:product) { create(:product) }

      def browse_as_guest
        get product_path(product)
        @guest_session_id = session.id.to_s
      end

      before do
        browse_as_guest
        sign_in_as(user)
      end

      it "had a guest session to replace" do
        expect(@guest_session_id).to be_present
      end

      it "issues a new session id" do
        expect(session.id.to_s).not_to eq(@guest_session_id)
      end

      it "signs the user into the new session" do
        expect(session[:user_id]).to eq(user.id)
      end

      it "keeps the guest's recently viewed products" do
        expect(session[:recently_viewed]).to eq([ product.id ])
      end
    end

    context "with an invalid password" do
      before { sign_in_as(user, password: "wrong-password") }

      it { expect(response).to have_http_status(:unprocessable_content) }

      it "marks both fields invalid and points them at the inline error" do
        fields = response_document.css("input#email, input#password")
        expect(fields.map { |field| [ field["aria-invalid"], field["aria-describedby"] ] }).to all(eq([ "true", "sign_in_error" ]))
      end

      it "renders the inline error the fields point to" do
        expect(response_document.at_css("#sign_in_error[role='alert']")).to be_present
      end

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
