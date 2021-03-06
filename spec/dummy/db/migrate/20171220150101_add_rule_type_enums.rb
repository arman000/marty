class AddRuleTypeEnums < ActiveRecord::Migration[4.2]
  def change
    [Gemini::XyzRuleType, Gemini::MyRuleType, Gemini::GuardOne,
     Gemini::GuardTwo, Gemini::XyzEnum].each do |cl|
      values = cl.values
      str_values = values.map {|v| ActiveRecord::Base.connection.quote v}.
                   join(',')
      clstr = cl.to_s.sub('Gemini::','').underscore
      execute <<-SQL
         CREATE TYPE #{clstr} AS ENUM (#{str_values})
      SQL
    end
  end
end
