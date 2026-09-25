module AuthenticationHelpers
  module Request
    def sign_in_as(user, password: "password123")
      post session_path, params: { email: user.email, password: password }
    end
  end

  module System
    def sign_in_via_ui(user, password: "password123")
      visit new_session_path
      fill_in "Email", with: user.email
      fill_in "Password", with: password
      click_button "Sign In"
    end
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers::Request, type: :request
  config.include AuthenticationHelpers::System, type: :system
end
