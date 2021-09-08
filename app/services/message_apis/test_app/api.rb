# frozen_string_literal: true

require "uri"
require "erb"

def valid_url?(uri)
  uri = URI.parse(uri).try(:host)
rescue URI::InvalidURIError
  false
end

module MessageApis::TestApp
  class Api < MessageApis::BasePackage
    BASE_URL = "https://xxx.ss"

    attr_accessor :secret

    def initialize(config:)
      @secret = secret

      @api_token = config["api_secret"]

      @conn = Faraday.new request: {
        params_encoder: Faraday::FlatParamsEncoder
      }

      @conn.headers = {
        "X-TOKEN" => @api_token,
        "Content-Type" => "application/json"
      }
    end

    def url(url)
      "#{BASE_URL}#{url}"
    end

    def trigger(event)
      # case event.action
      # when 'email_changed' then register_contact(event.eventable)
      # end
    end
  end
end
