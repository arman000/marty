module Marty::DateUtil
  def self.convert_date_str(str)
    case str
    when %r/\d{4}\/-\d{2}\/-\d{2}/
      Date.parse(str)
    when %r/\d{1,2}\/\d{1,2}\/\d{4}/
      Date.strptime(str, '%m/%d/%Y')
    when %r/\d{4}\/-\d{1,2}\/-\d{1,2}/
      Date.strptime(str, '%Y-%m-%d')
    else
      str
    end
  end
end
