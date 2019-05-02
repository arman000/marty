module Gemini
  class BudCategory < Marty::Base
    self.table_name = 'gemini_bud_categories'
    has_mcfly append_only: true
    mcfly_validates_uniqueness_of :name

    def self.create_from_promise_keyword_attrs(name:, group_id:)
      create!(name: name, group_id: group_id).id
    end

    def self.create_from_promise_regular_attrs(name, group_id)
      create!(name: name, group_id: group_id).id
    end

    def self.create_from_promise_mixed_attrs(name, group_id:)
      create!(name: name, group_id: group_id).id
    end

    def self.create_from_promise_error
      raise 'Something went wrong'
    end
  end
end
