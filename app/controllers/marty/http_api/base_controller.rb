# frozen_string_literal: true

module Marty
  module HttpApi
    # Create a controller that inherits from Marty::HttpApi::BaseController to use
    # the Marty::HttpApiAuth authentication functionality.
    # You may restrict which path and method can be access for a particular token (token).
    # To limit which endpoints can be accessed, add a list of path and mathods to the
    # +authorizations+ in {Marty::HttpApiAuth}.
    class BaseController < ApplicationController
      before_action :authenticate

      private

      def authenticate
        authenticate_or_request_with_http_token do |token, options|
          auth_procedure(token, options)
        end
      end

      def auth_procedure(token, _options)
        api = Marty::HttpApiAuth.find_by(token: token)
        check_authorizations(api.authorizations) if api
      end

      def check_authorizations(authorizations)
        return true if full_access_chars.include?(authorizations)

        authorizations.any? do |restrict|
          restrict == {
            'path' => request.path,
            'method' => request.method
          }
        end
      end

      def full_access_chars
        Marty::HttpApiAuth::UNFETTERED_ACCESS_CHARS
      end

      def current_token
        @current_token ||= authenticate
      end
    end
  end
end
