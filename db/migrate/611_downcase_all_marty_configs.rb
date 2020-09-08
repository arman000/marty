class DowncaseAllMartyConfigs < ActiveRecord::Migration[6.0]
  def up
    Mercury::Config.all.each { |c| c.update!(key: c.key.downcase) }
  end

  def down
    Mercury::Config.all.each { |c| c.update!(key: c.key.upcase) }
  end
end
