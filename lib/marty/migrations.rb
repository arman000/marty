require 'digest/md5'

module Marty::Migrations
  def tb_prefix
    "marty_"
  end

  def fk_opts(from, to, column)
    name = "fk_#{from}_#{to}_#{column}"
    if name.length > 63
      s = Digest::MD5.hexdigest("#{to}_#{column}").slice(0..9)
      name = "fk_#{from}_#{s}" 
    end
    {name: name}
  end

  def add_fk(from_table, to_table, options = {})
    options[:column] ||= "#{to_table.to_s.singularize}_id"

    from_table = "#{tb_prefix}#{from_table}" unless
      from_table.to_s.start_with?(tb_prefix)

    # FIXME: so hacky to specifically check for "marty_"
    to_table = "#{tb_prefix}#{to_table}" unless
      to_table.to_s.start_with?(tb_prefix) ||
      to_table.to_s.start_with?("marty_")

    add_foreign_key(from_table,
                    to_table,
                    fk_opts(from_table,
                            to_table,
                            options[:column]).update(options),
                    )
  end

  def index_opts(tb, a)
    name = "index_#{tb}_on_#{a}"
    name.length > 63 ? {
      name: "index_#{tb}_#{Digest::MD5.hexdigest(a.to_s).slice(0..9)}",
    } : {}
  end

  # created_dt/obsoleted_dt need to be indexed since they appear in
  # almost all queries.
  MCFLY_INDEX_COLUMNS = [
                         :created_dt,
                         :obsoleted_dt,
                        ]

  def add_mcfly_index(tb, *attrs)
    tb = "#{tb_prefix}#{tb}" unless
      tb.to_s.start_with?(tb_prefix)

    attrs.each { |a|
      options = index_opts(tb, a)
      options[:order] = {a.to_sym => "NULLS LAST"}
      add_index tb.to_sym, a, options
    }

    MCFLY_INDEX_COLUMNS.each { |a|
      add_index tb.to_sym, a, index_opts(tb, a)
    }
  end

end
