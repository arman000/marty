module Marty
  module RoleTypeAdapter
    mattr_accessor :klass, default: ::Marty::RoleType
    class << self
      [
        :get_all,
        :from_nice_names,
        :to_nice_names,
        :values
      ].each do |klass_method|
        delegate klass_method, to: :klass
      end
    end
  end
end
