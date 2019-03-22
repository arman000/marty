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


  data_grid_metadata := COALESCE(data_grid_metadata, '[]'::JSONB);

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
				 horizontal_indexes := '[0]'::JSONB;
			 ELSE
				 vertical_indexes := '[0]'::JSONB;
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

     query_index_result := '[]'::JSONB;

     -- execute the SQL query that has been received before and 
     -- add it's (possibly multiple) results to query_index_result variable
     FOR target IN EXECUTE query_dir_result ->> 0 USING query_dir_result -> 1 LOOP
       query_index_result := query_index_result || to_jsonb(target.index);
     END LOOP;

     all_results := all_results || query_index_result;
     query_index_result := '[]'::JSONB || query_index_result; -- Use empty JSONB array in case of NULL results

     IF direction = 'h' THEN
       horizontal_indexes := query_index_result;
     ELSE
       vertical_indexes := query_index_result;
     END IF;


     IF dis AND jsonb_array_length(query_index_result) > 1 THEN 
       RAISE EXCEPTION 'matches > 1';
     END IF;

    END LOOP;

    vertical_indexes := COALESCE(vertical_indexes, '[]'::JSONB);
    horizontal_indexes := COALESCE(horizontal_indexes, '[]'::JSONB);

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
