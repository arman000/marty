module Gemini
  class Simple < ActiveRecord::Base
    self.table_name = 'gemini_simples'
    mcfly_validates_uniqueness_of :group_id
  end
end
