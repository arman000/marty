# rubocop:disable all
class DropDataGridIndicesTables < ActiveRecord::Migration[5.1]
  include Marty::Migrations

  def up
    drop_table :marty_grid_index_booleans
    drop_table :marty_grid_index_int4ranges
    drop_table :marty_grid_index_integers
    drop_table :marty_grid_index_numranges
    drop_table :marty_grid_index_strings

    ActiveRecord::Base.connection.execute <<~SQL
      DROP FUNCTION IF EXISTS public.query_grid_dir;
      DROP FUNCTION IF EXISTS public.lookup_grid_distinct;
    SQL
  end

  def down
    create_booleans
    create_int4ranges
    create_integers
    create_numranges
    create_strings

    ActiveRecord::Base.connection.execute <<~SQL
      ALTER TABLE "marty_grid_index_booleans" ALTER COLUMN "attr" TYPE VARCHAR;
      ALTER TABLE "marty_grid_index_int4ranges" ALTER COLUMN "attr" TYPE VARCHAR;
      ALTER TABLE "marty_grid_index_integers" ALTER COLUMN "attr" TYPE VARCHAR;
      ALTER TABLE "marty_grid_index_numranges" ALTER COLUMN "attr" TYPE VARCHAR;
      ALTER TABLE "marty_grid_index_strings" ALTER COLUMN "attr" TYPE VARCHAR;
    SQL

    create_functions
  end

  def create_booleans
    table_name = "marty_grid_index_booleans"

    # drop deprecated version
    execute("DROP TABLE IF EXISTS #{table_name}")

    create_table table_name do |t|
      t.datetime :created_dt, null: false
      t.references :data_grid, null: false
      t.string :attr, null: false
      t.boolean :key
      t.integer :index, null: false
    end

    # FIXME: not sure if this index is appropriate for our queries.
    # May need to break it up.
    add_index table_name,
    [:created_dt, :data_grid_id, :attr],
    name: "index_#{table_name}"
    add_index table_name, :key

    add_fk table_name, :data_grids

    add_column table_name, :not, :boolean, null: false, default: false
    add_index table_name, [:not, :key]
  end

  def create_strings
    table_name = "marty_grid_index_strings"

    # drop deprecated version
    execute("DROP TABLE IF EXISTS #{table_name}")

    create_table table_name do |t|
      t.datetime :created_dt, null: false
      t.references :data_grid, null: false
      t.string :attr, null: false
      t.text :key, array: true
      t.integer :index, null: false
    end

    # FIXME: not sure if this index is appropriate for our queries.
    # May need to break it up.
    add_index table_name,
    [:created_dt, :data_grid_id, :attr],
    name: "index_#{table_name}"
    add_index table_name, :key, using: "GIN"

    add_fk table_name, :data_grids

    add_column table_name, :not, :boolean, null: false, default: false
    add_index table_name, [:not, :key]
  end

  def create_integers
    table_name = "marty_grid_index_integers"

    # drop deprecated version
    execute("DROP TABLE IF EXISTS #{table_name}")

    create_table table_name do |t|
      t.datetime :created_dt, null: false
      t.references :data_grid, null: false
      t.string :attr, null: false
      t.integer :key, array: true
      t.integer :index, null: false
    end

    # FIXME: not sure if this index is appropriate for our queries.
    # May need to break it up.
    add_index table_name,
    [:created_dt, :data_grid_id, :attr],
    name: "index_#{table_name}"
    add_index table_name, :key, using: "GIN"

    add_fk table_name, :data_grids

    add_column table_name, :not, :boolean, null: false, default: false
    add_index table_name, [:not, :key]
  end

  def create_int4ranges
    table_name = "marty_grid_index_int4ranges"

    # drop deprecated version
    execute("DROP TABLE IF EXISTS #{table_name}")

    create_table table_name do |t|
      t.datetime :created_dt, null: false
      t.references :data_grid, null: false
      t.string :attr, null: false
      t.int4range :key
      t.integer :index, null: false
    end

    # FIXME: not sure if this index is appropriate for our queries.
    # May need to break it up.
    add_index table_name,
    [:created_dt, :data_grid_id, :attr],
    name: "index_#{table_name}"
    add_index table_name, :key, using: "GIST"

    add_fk table_name, :data_grids

    add_column table_name, :not, :boolean, null: false, default: false
    add_index table_name, [:not, :key]
  end

  def create_numranges
    table_name = "marty_grid_index_numranges"

    # drop deprecated version
    execute("DROP TABLE IF EXISTS #{table_name}")

    create_table table_name do |t|
      t.datetime :created_dt, null: false
      t.references :data_grid, null: false
      t.string :attr, null: false
      t.numrange :key
      t.integer :index, null: false
    end

    # FIXME: not sure if this index is appropriate for our queries.
    # May need to break it up.
    add_index table_name,
    [:created_dt, :data_grid_id, :attr],
    name: "index_#{table_name}"
    add_index table_name, :key, using: "GIST"

    add_fk table_name, :data_grids

    add_column table_name, :not, :boolean, null: false, default: false
    add_index table_name, [:not, :key]
  end

  def create_functions
    sql1 = <<~SQL
      CREATE OR REPLACE FUNCTION public.lookup_grid_distinct(h jsonb, row_info jsonb, return_grid_data boolean DEFAULT false, dis boolean DEFAULT false) RETURNS jsonb
        LANGUAGE plpgsql
        AS $_$

      -- Finds a data grid metadata, calculates the SQL query for it's vertical and horizontal attributes
      -- Fetches vertical and horizontal indexes and uses them to fetch value from data grid data

      DECLARE
        directions TEXT[] = ARRAY['h', 'v'];
        direction TEXT;

        data_grid_info JSONB;
        data_grid_metadata JSONB;
        data_grid_lenient BOOLEAN;
        data_grid_data JSONB;
        data_grid_name TEXT;
        data_grid_group_id TEXT;
        data_grid_metadata_h JSONB[];
        data_grid_metadata_v JSONB[];
        data_grid_metadata_current JSONB[];

        horizontal_indexes JSONB = '[]'::JSONB;
        horizontal_index INTEGER;

        vertical_indexes JSONB = '[]'::JSONB;
        vertical_index INTEGER;

        default_index_array JSONB = '[0]'::JSONB;
        empty_jsonb_array JSONB = '[]'::JSONB;

        query_dir_result JSONB;
        query_index_result JSONB = '[]'::JSONB;
        metadata_record JSONB;

        all_results JSONB[];
        sql_scripts_arr text[];

        result JSONB;
        return_json JSONB;

        error_extra JSONB;

        target RECORD;
      BEGIN
        EXECUTE 'SELECT metadata, lenient, name, data, group_id FROM marty_data_grids WHERE id = $1::INTEGER'
          INTO data_grid_metadata, data_grid_lenient, data_grid_name, data_grid_data, data_grid_group_id
          USING row_info ->> 'id';


        data_grid_metadata := COALESCE(data_grid_metadata, empty_jsonb_array);

        FOR i IN 0 .. (jsonb_array_length(data_grid_metadata) - 1) LOOP
          metadata_record := data_grid_metadata -> i;
          IF (metadata_record ->> 'dir') = 'h' THEN
            data_grid_metadata_h := data_grid_metadata_h || metadata_record;
          ELSIF (metadata_record ->> 'dir') = 'v' THEN
            data_grid_metadata_v := data_grid_metadata_v || metadata_record;
          END IF;
        END LOOP;

        FOREACH direction IN ARRAY directions LOOP

          IF direction = 'h' THEN
            data_grid_metadata_current := data_grid_metadata_h;
          ELSE
            data_grid_metadata_current := data_grid_metadata_v;
          END IF;


          IF COALESCE(array_length(data_grid_metadata_current, 1), 0) = 0 THEN
             IF direction = 'h' THEN
               horizontal_indexes := default_index_array;
             ELSE
               vertical_indexes := default_index_array;
             END IF;
            CONTINUE;
          END IF;

          -- fetch the resulting SQL query and it's arguments for current direction
          EXECUTE 'SELECT public.query_grid_dir($1, $2, $3)'
            INTO query_dir_result
            USING h, data_grid_metadata_current, row_info;

           IF query_dir_result ->> 0 IS NULL THEN
             CONTINUE;
           END IF;

           sql_scripts_arr := sql_scripts_arr || (query_dir_result ->> 0);

           query_index_result := empty_jsonb_array;

           -- execute the SQL query that has been received before and
           -- add it's (possibly multiplt) results to query_index_result variable
           FOR target IN EXECUTE query_dir_result ->> 0 USING query_dir_result -> 1 LOOP
             query_index_result := query_index_result || to_jsonb(target.index);
           END LOOP;

           all_results := all_results || query_index_result;
           query_index_result := empty_jsonb_array || query_index_result; -- Use empty JSONB array in case of NULL results

           IF direction = 'h' THEN
             horizontal_indexes := query_index_result;
           ELSE
             vertical_indexes := query_index_result;
           END IF;


           IF dis AND jsonb_array_length(query_index_result) > 1 THEN
             RAISE EXCEPTION 'matches > 1';
           END IF;

          END LOOP;

          vertical_indexes := COALESCE(vertical_indexes, empty_jsonb_array);
          horizontal_indexes := COALESCE(horizontal_indexes, empty_jsonb_array);

          IF ((jsonb_array_length(vertical_indexes)) = 0
             OR (jsonb_array_length(horizontal_indexes)) = 0)
             AND NOT data_grid_lenient
             AND NOT return_grid_data THEN

           RAISE EXCEPTION 'Data Grid lookup failed';
          END IF;

          -- Get the smalles vertical index
          IF jsonb_array_length(vertical_indexes) > 0 THEN
            FOR i IN 0 .. (jsonb_array_length(vertical_indexes) - 1) LOOP
              vertical_index := LEAST(vertical_index, (vertical_indexes ->> i)::INTEGER);
            END LOOP;
          END IF;

          -- Get the smalles horizontal index
          IF jsonb_array_length(horizontal_indexes) > 0 THEN
            FOR i IN 0 .. (jsonb_array_length(vertical_indexes) - 1) LOOP
              horizontal_index := LEAST(horizontal_index, (horizontal_indexes ->> i)::INTEGER);
            END LOOP;
          END IF;

          IF vertical_index IS NOT NULL and horizontal_index IS NOT NULL THEN
            result := data_grid_data -> vertical_index -> horizontal_index;
          END IF;

          IF NOT return_grid_data THEN
            data_grid_data := NULL;
            data_grid_metadata := NULL;
          END IF;

          return_json := jsonb_build_object(
            'result', result,
            'name', data_grid_name,
            'data', data_grid_data,
            'metadata', data_grid_metadata
          );

          RETURN return_json;

        EXCEPTION WHEN OTHERS THEN
          error_extra := jsonb_build_object(
            'error', SQLERRM,
            'sql', sql_scripts_arr,
            'results', all_results,
            'params', h,
            'dg', jsonb_build_object(
              'name', data_grid_name,
              'data', data_grid_data,
              'metadata', data_grid_metadata,
              'group_id', data_grid_group_id,
              'lenient', data_grid_lenient
            )
          );

          RETURN jsonb_build_object(
            'error', SQLERRM,
            'error_extra', error_extra
          );
      END

      $_$;
    SQL

    sql2 = <<~SQL
      CREATE OR REPLACE FUNCTION public.query_grid_dir(h jsonb, infos jsonb[], row_info jsonb) returns jsonb 
      LANGUAGE plpgsql 
      AS $$

    -- Iterates through infos and and builds a one big SQL query 
    -- with one SELECT per info and INTERSECT between those SELECTs
    -- in order to find the cells that multiple vertical or horizontal headers are pointing to.
    -- Return JSONB array with resulting SQL query and JSONB array of it's arguments.
    -- Each of the argument is references via it's index in JSONB array. Example: ($1 ->> 0)

    DECLARE
      args text[];
      sqlidx integer = 0;
      i integer;

      attr_type text;
      attr_name text;
      attr_value text;
      h_key_exists boolean;

      table_name text;
      sql_script text;
      sql_scripts_arr text[];
      sql_scripts_arr_intersect text;
      sql_filter text;

      includes_nots boolean;
      default_nots_array JSONB = '[]'::JSONB;
      current_info jsonb;

    BEGIN
      FOR i IN 1 .. COALESCE(array_upper(infos, 1), 0)
        LOOP
          current_info := infos[i];

          attr_type := current_info ->> 'type';
          attr_name := current_info ->> 'attr';

          -- Use not condition only if given type indexes has rows with 'not' = true
          includes_nots = COALESCE(current_info -> 'nots', default_nots_array)  @> 'true';

          attr_value := h ->> attr_name;
          h_key_exists := h ? attr_name;

          IF NOT h_key_exists THEN
            CONTINUE;
          END IF;

          CASE attr_type 
          WHEN 'boolean' THEN
            table_name := 'marty_grid_index_' || attr_type || 's';
          WHEN 'numrange' THEN
            table_name := 'marty_grid_index_' || attr_type || 's';
          WHEN 'int4range' THEN
            table_name := 'marty_grid_index_' || attr_type || 's';
          WHEN 'integer' THEN
            table_name := 'marty_grid_index_' || attr_type || 's';
          ELSE 
            table_name := 'marty_grid_index_strings';
          END CASE;

          sql_script = 'SELECT DISTINCT index from ' || table_name ||
            -- Convertion to FLOAT is needed to make numbers like 2005.0 work
            ' WHERE data_grid_id = ($1 ->> ' || sqlidx || ')::FLOAT::INTEGER' ||
            ' AND created_dt = ($1 ->> ' || (sqlidx + 1) || ')::TIMESTAMP' ||
            ' AND attr = $1 ->> ' || (sqlidx + 2) || ' ';

          sqlidx := sqlidx + 3;

          args := args || (row_info ->> 'group_id');
          args := args || (row_info ->> 'created_dt');
          args := args || attr_name;

          IF attr_value IS NULL THEN
            sql_filter := '';
          ELSE
            CASE attr_type
               WHEN 'boolean' THEN 
                 sql_filter := 'key = ($1 ->> ' || sqlidx || ')::BOOLEAN OR ';
               WHEN 'numrange' THEN 
                 sql_filter := 'key @> ($1 ->> ' || sqlidx || ')::NUMERIC OR ';
               WHEN 'int4range' THEN 
                 -- Convertion to FLOAT is neeed to make numbers like 2005.0 work
                 sql_filter := 'key @> ($1 ->> ' || sqlidx || ')::FLOAT::INTEGER OR ';
               WHEN 'integer' THEN
                 -- Convertion to FLOAT is neeed to make numbers like 2005.0 work
                 sql_filter := 'key @> ARRAY[($1 ->> ' || sqlidx || ')::FLOAT::INTEGER] OR ';
               ELSE 
                 sql_filter := 'key @> ARRAY[($1 ->> ' || sqlidx || ')::TEXT] OR ';
            END CASE;

            sqlidx := sqlidx + 1;
            args := args || attr_value;
          END IF;


          -- Use not condition only if given type indexes has rows with 'not' = true
          IF includes_nots THEN
            sql_script := sql_script || ' AND CASE WHEN ' || table_name ||'.not '
              'THEN NOT (' || sql_filter || 'key IS NULL) '
              'ELSE (' || sql_filter || 'key IS NULL) END';
          ELSE
            sql_script := sql_script || ' AND (' || sql_filter || 'key is NULL) ';
          END IF;

          sql_scripts_arr := sql_scripts_arr || sql_script;
        END LOOP;

      IF array_length(sql_scripts_arr, 1) = 0 THEN
        RETURN NULL;
      END IF;

      sql_scripts_arr_intersect := array_to_string(sql_scripts_arr, ' INTERSECT ');
      
      RETURN json_build_array(sql_scripts_arr_intersect, args);
    END;

    $$;
    SQL

    ActiveRecord::Base.connection.execute sql1
    ActiveRecord::Base.connection.execute sql2
  end
end
# rubocop:enable all
