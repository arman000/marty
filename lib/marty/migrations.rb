module Marty::Migrations
  def tb_prefix
    "marty_"
  end

  def new_enum(klass, prefix_override = nil)
    raise "bad class arg #{klass}" unless
      klass.is_a?(Class) && klass < ActiveRecord::Base

    raise "model class needs VALUES (as Set)" unless
      klass.const_defined?(:VALUES)

    values = klass::VALUES
    str_values =
      values.map {|v| ActiveRecord::Base.connection.quote v}.join ','

    #hacky way to get name
    prefix = prefix_override || tb_prefix
    enum_name = klass.table_name.sub(/^#{prefix}_*/, '')

    execute <<-SQL
      CREATE TYPE #{enum_name} AS ENUM (#{str_values});
    SQL
  end

  def update_enum(klass, prefix_override = nil)
    raise "bad class arg #{klass}" unless
      klass.is_a?(Class) && klass < ActiveRecord::Base

    raise "model class needs VALUES (as Set)" unless
      klass.const_defined?(:VALUES)

    #hacky way to get name
    prefix = prefix_override || tb_prefix
    enum_name = klass.table_name.sub(/^#{prefix}/, '')

    #check values against underlying values
    res = execute <<-SQL
      SELECT ENUM_RANGE(null::#{enum_name});
    SQL

    db_values = res.first['enum_range'].gsub(/[{"}]/, '').split(',')
    ex_values = klass::VALUES - db_values
    puts "no new #{klass}::VALUES to add" if ex_values.empty?

    #hack to prevent transaction
    execute("COMMIT;")
    ex_values.each do |v|
      prepped_v = ActiveRecord::Base.connection.quote(v)

      execute <<-SQL
        ALTER TYPE #{enum_name} ADD VALUE #{prepped_v};
      SQL
    end
    execute("BEGIN;")
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

  def self.write_view(target_dir, target_view, klass, jsons, excludes, extras)
    colnames = klass.columns_hash.keys
    excludes += ["user_id", "o_user_id"]
    joins = ["join marty_users u on main.user_id = u.id",
             "left join marty_users ou on main.o_user_id = ou.id"]
    columns = ["u.login AS user_name",
               "ou.login AS obsoleted_user"]
    jointabs = {}
    colnames.each do |c|
      if jsons[c]
        jsons[c].each do |subc|
          if subc.class == Array
            subcol, type, fn = subc
            columns.push "#{fn || ''}(main.#{c} ->> '#{subcol}')::#{type} " +
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
          extras.each do |(table, column, new_colname)|
            columns.push "#{tn_alias}.#{column} as #{new_colname}" if
              table == table_name
          end
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

  def self.lines_to_crlf(lines)
    lines.map do |line|
      line.encode(line.encoding, :universal_newline => true).
        encode(line.encoding, :crlf_newline => true)
    end
  end
  def self.generate_sql_migrations(migrations_dir, sql_files_dir)
    sd = Rails.root.join(sql_files_dir)
    md = Rails.root.join(migrations_dir)
    sql_files = Dir.glob("#{sd}/**/*.sql")
    mig_files = Dir.glob("#{migrations_dir}/*.rb").map do |f|
      m = /\A.*\/([0-9]+)_v([0-9]+)_sql_(.*)\.rb\z/.match(f)
      { name: m[3],
        timestamp: m[1],
        version: m[2].to_i,
        raw_sql: "#{md}/sql/#{m[1]}_v#{m[2]}_sql_#{m[3]}.sql"
      }
    end.group_by { |a| a[:name] }.each do |k, v|
      v.sort! { |a, b| b[:version] <=> a[:version] }
    end
    time_now = Time.now.utc
    gen_count = 0

    sql_files.each do |sql|
      base = File.basename(sql, ".sql")
      existing = mig_files[base].first rescue nil
      # must ensure CRLF line endings or SQL Server keep asking about line
      # endings whenever you generating script
      sql_lines = lines_to_crlf(File.open(sql, "r").readlines)
      next if existing && sql_lines == File.open(existing[:raw_sql]).readlines

      timestamp = (time_now + gen_count.seconds).strftime("%Y%m%d%H%M%S")
      v = existing && existing[:version] + 1 || 1
      klass = "v#{v}_sql_#{base}"
      newbase = "#{timestamp}_#{klass}"
      mig_name = File.join(md, "#{newbase}.rb")
      sql_snap_literal = Rails.root.join(md, 'sql', "#{newbase}.sql")
      sql_snap_call =  "Rails.root.join('#{migrations_dir}', 'sql', '#{newbase}.sql')"

      File.open(sql_snap_literal, "w") do |f|
        f.print sql_lines.join
      end
      puts "creating #{newbase}.rb"

      # only split on "GO" at the start of a line with optional whitespace
      # before EOL.  GO in comments could trigger this and will cause an error
      File.open(mig_name, "w") do |f|
        f.print <<OUT
class #{klass.camelcase} < ActiveRecord::Migration[4.2]

  def up
    path = #{sql_snap_call}
    batches = File.read(path).split(/^GO\\s*$/i)
    batches.each { |batch| execute batch }
  end

  def down
    announce('must rollback manually')
  end

end
OUT
      end
      gen_count += 1
    end
  end

  # some migrations attempt to get the id using the model.
  # after enumification models have no notion of numeric id
  # we have to get it from the database
  def get_old_enum_id(klass, name)
    ActiveRecord::Base.
               connection.execute(<<-SQL).to_a.first.try{|v| v['id']}
      select id from #{klass.table_name} where name =
         #{ActiveRecord::Base.sanitize(name)}
    SQL
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

  # if the database does not agree with the model regarding columns,
  # get the actual column name
  def get_attrs(klass)
    cols = (Mcfly.mcfly_uniqueness(klass) + ['obsoleted_dt']).uniq.map(&:to_s)
    act_cols = klass.column_names
    use_cols = cols.map do |col|
      col_id = col + '_id'
      act_cols.include?(col) ? col :
        act_cols.include?(col_id) ? col_id :
          (raise "problem adding index for #{klass}: "\
                 "cols = #{cols}, act_cols = #{act_cols}")
    end.map(&:to_sym)
  end
end
