module Marty
  module RSpec
    module DownloadHelper
      TIMEOUT = 30
      PATH    = Rails.root.join('spec/tmp/downloads')

      ACCEPTED_EXTS = ['.xlsx', '.csv']

      extend self

      def downloads
        Dir[PATH.join('*')]
      end

      def download
        downloads.first
      end

      def download_content
        wait_for_download
        # doesn't work for excel files...
        File.read(download)
      end

      def download_content_acceptable?
        wait_for_download
        downloads.each do |f|
          return false unless ACCEPTED_EXTS.include? File.extname(f)
        end
        true
      end

      def wait_for_download
        Timeout.timeout(TIMEOUT) do
          sleep 0.1 until downloaded?
        end
      end

      def downloaded?
        downloads.any? && !downloading?
      end

      def downloading?
        downloads.grep(/\.part$/).any? ||
          downloads.select { |f| File.size(f).zero? }.any?
      end

      def clear_downloads
        FileUtils.rm_f(downloads)
        Timeout.timeout(TIMEOUT) do
          sleep 0.1 until !downloads.any?
        end
      end
    end
  end
end
