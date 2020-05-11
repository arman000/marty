module Marty
  module ApplicationHelper
    DEFAULT_ASSETS_PATH = 'app/assets'

    def asset_exists?(file, file_extension, default_path)
      path = Rails.configuration.marty.send("assets_#{file_extension}_path") ||
             default_path

      asset_path = Rails.root.join("#{path}/#{file}.#{file_extension}")
      File.exist?(asset_path)
    end

    def javascript_exists?(file)
      asset_exists?(file, :js, DEFAULT_ASSETS_PATH + '/javascripts')
    end

    def stylesheet_exists?(file)
      asset_exists?(file, :css, DEFAULT_ASSETS_PATH + '/stylesheets')
    end

    def font_exists?(file)
      asset_exists?(file, :ttf, DEFAULT_ASSETS_PATH + '/fonts') ||
        asset_exists?(file, :woff2, DEFAULT_ASSETS_PATH + '/fonts')
    end
  end
end
