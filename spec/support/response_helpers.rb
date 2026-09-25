# Structural readers for request specs, so examples assert on links and
# Turbo Stream targets rather than on CSS classes or copy.
module ResponseHelpers
  def response_document
    Nokogiri::HTML(response.body)
  end

  def response_link_hrefs
    response_document.css("a[href]").map { |link| link["href"] }
  end

  def turbo_stream_targets
    response_document.css("turbo-stream[target]").map { |stream| stream["target"] }
  end
end

RSpec.configure do |config|
  config.include ResponseHelpers, type: :request
end
