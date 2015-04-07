module Gemini::Extras::DataImport
  def import_cleaner
    where(obsoleted_dt: 'infinity').pluck(:id)
  end
end
