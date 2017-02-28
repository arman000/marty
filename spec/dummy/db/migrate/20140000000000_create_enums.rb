class CreateEnums < ActiveRecord::Migration
  include Marty::Migrations
  def change
    new_enum(Gemini::EnumState, 'gemini')
  end
end
