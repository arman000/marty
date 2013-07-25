class Marty::Base < ActiveRecord::Base
  self.table_name_prefix = "marty_"
  self.abstract_class = true
end
