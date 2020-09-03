module Marty
  class SidekiqUiAdminConstraint
    def matches?(request)
      return false unless request.session[:user_id]

      user = User.find_by(id: request.session[:user_id])
      user&.roles&.include?('admin')
    end
  end
end
