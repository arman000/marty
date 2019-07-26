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

BEGIN
  FOR i IN 1 .. COALESCE(array_upper(infos, 1), 0)
    LOOP
      attr_type := infos[i] ->> 'type';
      attr_name := infos[i] ->> 'attr';

      -- Use not condition only if given type indexes has rows with 'not' = true
      includes_nots = COALESCE(infos[i] -> 'nots', '[]'::JSONB)  @> 'true';

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
