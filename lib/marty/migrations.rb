require 'digest/md5'

module Marty::Migrations
  def tb_prefix
    "marty_"
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

  # created_dt/obsoleted_dt need to be indexed since they appear in
  # almost all queries.
  MCFLY_INDEX_COLUMNS = [
                         :created_dt,
                         :obsoleted_dt,
                        ]

  def add_mcfly_index(tb, *attrs)
    tb = "#{tb_prefix}#{tb}" unless
      tb.to_s.start_with?(tb_prefix)

    add_mcfly_attrs_index(tb, *attrs)

    MCFLY_INDEX_COLUMNS.each { |a|
      add_index tb.to_sym, a, index_opts(tb, a)
    }
  end

  def add_mcfly_unique_index(klass)
    raise "bad class arg #{klass}" unless
      klass.is_a?(Class) && klass < ActiveRecord::Base

    attrs = get_attrs(klass)

    add_index(klass.table_name.to_sym,
              attrs,
              unique: true,
              name: unique_index_name(klass)
              ) unless index_exists?(klass.table_name.to_sym,
                                     attrs,
                                     name: unique_index_name(klass),
                                     unique: true)

  end

  def remove_mcfly_unique_index(klass)
    raise "bad class arg #{klass}" unless
      klass.is_a?(Class) && klass < ActiveRecord::Base

    attrs = get_attrs(klass)

    remove_index(klass.table_name.to_sym,
                 name: unique_index_name(klass)
                 ) if index_exists?(klass.table_name.to_sym,
                                    attrs,
                                    name: unique_index_name(klass),
                                    unique: true)
  end

  def self.write_view(target_dir, target_view, klass, jsons, excludes)
    colnames = klass.columns_hash.keys
    user_id_cols = ["user_id", "o_user_id"]
    excludes += user_id_cols
    joins = ["join marty_users u on main.user_id = u.id",
             "left join marty_users ou on main.o_user_id = ou.id"]
    columns = ["concat(u.firstname, ' ', u.lastname) AS user_name",
               "concat(ou.firstname, ' ', ou.lastname) AS obsoleted_user"]
    jointabs = {}
    colnames.each do |c|
      if jsons[c]
        jsons[c].each do |subc|
          if subc.class == Array
            subcol, type = subc
            columns.push "f_fixfalse(main.#{c} ->> '#{subcol}')::#{type} " +
                         "as \"#{c}_#{subcol}\""
          else
            columns.push "main.#{c} ->> '#{subc}' as \"#{c}_#{subc}\""
          end
        end
      elsif !excludes.include?(c)
        assoc = klass.reflections.find { |(n, h)| h.foreign_key == c }
        if assoc && assoc[1].klass.columns_hash["name"]
          table_name = assoc[1].table_name
          jointabs[table_name] ||= 0
          jointabs[table_name] += 1
          tn_alias = "#{table_name}#{jointabs[table_name]}"
          joins.push "left join #{table_name} #{tn_alias} on main.#{c} " +
                     "= #{tn_alias}.id"
          target_name = c.gsub(/_id$/,'_name')
          columns.push "#{tn_alias}.name as #{target_name}"
        else
          columns.push "main.#{c}"
        end
      end
    end
    File.open(File.join(target_dir, "#{target_view}.sql"), "w") do |f|
      f.puts <<EOSQL
create or replace function f_fixfalse(s text) returns text as $$
begin
    return case when s = 'false' then null else s end;
end
$$ language plpgsql;

drop view if exists #{target_view};
create or replace view #{target_view} as
select
    #{columns.join(",\n    ")}
from #{klass.table_name} main
    #{joins.join("\n    ")};

grant select on #{target_view} to public;
EOSQL
    end
  end

private
  def fk_opts(from, to, column)
    name = "fk_#{from}_#{to}_#{column}"
    if name.length > 63
      s = Digest::MD5.hexdigest("#{to}_#{column}").slice(0..9)
      name = "fk_#{from}_#{s}"
    end
    {name: name}
  end

  def index_opts(tb, a)
    name = "index_#{tb}_on_#{a}"
    name.length > 63 ? {
      name: "index_#{tb}_#{Digest::MD5.hexdigest(a.to_s).slice(0..9)}",
    } : {}
  end

  def add_mcfly_attrs_index(tb, *attrs)
    attrs.each { |a|
      options = index_opts(tb, a)
      options[:order] = {a.to_sym => "NULLS LAST"}
      add_index tb.to_sym, a, options
    }
  end

  def unique_index_name(klass)
    "unique_#{klass.table_name}"
  end

  def get_attrs(klass)
    (Mcfly.mcfly_uniqueness(klass) + ['obsoleted_dt']).uniq
  end
end
