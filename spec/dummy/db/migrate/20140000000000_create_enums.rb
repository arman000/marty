class CreateEnums < ActiveRecord::Migration[4.2]
  include Marty::Migrations
  def change
    new_enum(Gemini::EnumState, 'gemini')
  end
end
