module Marty
  class NotificationChannel < ::ApplicationCable::Channel
    def subscribed
      reject && return if current_user.blank?
      stream_from "marty_notifications_#{current_user.id}"
    end
  end
end
