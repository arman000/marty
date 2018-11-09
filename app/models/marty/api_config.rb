class Marty::ApiConfig < Marty::Base
  validates_presence_of :script

  def self.lookup(script, node, attr)
    res = where('node IS NULL OR node = ?', node).
            where('attr IS NULL OR attr = ?', attr).
            order('node nulls last, attr nulls last').
            find_by(script: script)

    res && res.as_json.except('id',
                              'created_at',
                              'updated_at',
                              'script',
                              'node',
                              'attr').symbolize_keys
  end

  def self.multi_lookup(script, node, attrs)
    (attrs.nil? ? [nil] : attrs).
      map { |attr| lookup(script, node, attr).try{|x| x.unshift(attr) }}
  end
end
