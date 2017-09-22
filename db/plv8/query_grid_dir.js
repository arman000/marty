CREATE OR REPLACE FUNCTION query_grid_dir(h JSONB, infos JSONB[],
                                          row_info JSONB, group_id integer)
RETURNS JSONB AS $$
    var typer = function(type, value, idx) {
          switch(type) {
            case "boolean":
              return [v, "key = $" + idx, "marty_grid_index_booleans"];
            case "numrange":
              return [parseFloat(v),
                      "key @> $" + idx + "::numeric", "marty_grid_index_numranges"];
            case "int4range":
              return [parseInt(v), "key @> $" + idx + "::integer", "marty_grid_index_int4ranges"];
            case "integer":
              return [parseInt(v), "key @> ARRAY[$" + idx + "::integer]", "marty_grid_index_integers"];
            default:
              return [v, "key @> ARRAY[$" + idx + "::text]", "marty_grid_index_strings"];
              }
           }

    var temp = [];
    var args = [];

    var sql;
    for (var sqlidx=1, i = 0; i < infos.length; i++)
      {
        var type = infos[i]["type"];
        var attr = infos[i]["attr"];
        var v = h[attr];
        if (!h.hasOwnProperty(attr) || v === null) {
            //throw Error(`missing attr ${attr}`)
            continue;
        }
        var a;
        a = typer(type, v, sqlidx+3);
        if (typeof a === 'undefined') {
            plv8.elog(INFO, `type = ${type}`);
            plv8.elog(INFO, `v = ${JSON.stringify(v)}`);
        }
        vv = a[0]
        filt = a[1]
        tab = a[2]

        sql = `SELECT index from ${tab} ` +
                   "WHERE data_grid_id = $" + sqlidx +
                   " AND created_dt = $" + (sqlidx+1) +
                   " AND attr = $" + (sqlidx+2) + ' ';

        args.push(group_id);
        args.push(row_info["created_dt"]);
        args.push(attr);
        args.push(vv);
        sql += ' AND (' + filt + " OR key is NULL) ";
        temp.push(sql);
        sqlidx+=4;
        }
    if (temp ==[]) return null;
    return [temp.join(" INTERSECT "), args];

$$ LANGUAGE plv8;
