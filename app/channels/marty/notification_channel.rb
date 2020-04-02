module Marty
  class NotificationChannel < ::ApplicationCable::Channel
    def subscribed
      reject && return unless
        Rails.application.config.marty.enable_action_cable

      reject && return if current_user.blank?

      stream_from "marty_notifications_#{current_user.id}"
    end
  end
end
