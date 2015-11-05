require "attache/api/v1"

Attache::API::V1::HTTPClient.class_eval do
  def post(*args)
    Struct.new(:body).new.tap do |response|
      response.body = '{}' # empty json
    end
  end

  def post_content(*args)
    ""
  end
end
