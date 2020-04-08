module Marty
  module ApplicationHelper
    DEFAULT_JS_PATH = 'app/assets/javascripts'
    def javascript_exists?(file, file_extension = 'js')
      path = Rails.configuration.marty.assets_javascripts_path ||
             DEFAULT_JS_PATH

      asset_path = Rails.root.join("#{path}/#{file}.#{file_extension}")
      File.exist?(asset_path)
    end
  end
end
