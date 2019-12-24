require 'delorean_lang'

module Marty
  module RSpec
    module JsonHelper
      def json_response
        JSON.parse(response.body)
      end
    end
  end
end
