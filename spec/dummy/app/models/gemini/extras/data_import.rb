module Gemini::Extras::DataImport
  def import_cleaner2
    where(obsoleted_dt: 'infinity').pluck(:id)
  end
end
