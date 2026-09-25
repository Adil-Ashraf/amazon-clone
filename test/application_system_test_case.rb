require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  if ENV["SELENIUM_REMOTE_URL"].present?
    # Docker (bin/docker-dev system): Chrome runs in the "chrome" service, so
    # the Capybara server must listen on all interfaces and be addressed by
    # this container's hostname rather than localhost.
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ],
      options: { browser: :remote, url: ENV["SELENIUM_REMOTE_URL"] }

    Capybara.server_host = "0.0.0.0"
    Capybara.server_port = 3001
    Capybara.app_host = "http://#{ENV.fetch("CAPYBARA_APP_HOSTNAME", "web")}:3001"
  else
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
  end
end
