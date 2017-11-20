class AddRuleSubTypeEnum < ActiveRecord::Migration
  def change
    [Gemini::XyzRuleSubType, Gemini::RuleSubType, Gemini::GuardOne,
     Gemini::GuardTwo, Gemini::XyzEnum].each do |cl|
      values = cl::VALUES
      str_values = values.map {|v| ActiveRecord::Base.connection.quote v}.
                   join(',')
      clstr = cl.to_s.sub('Gemini::','').underscore
      execute <<-SQL
         CREATE TYPE #{clstr} AS ENUM (#{str_values})
      SQL
    end
  end
end
