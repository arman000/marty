module Marty
  class NotificationChannel < ::ApplicationCable::Channel
    def subscribed
      reject && return unless current_user.present?
      stream_from "marty_notifications_#{current_user.id}"
    end
  end
end
