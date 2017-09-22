CREATE OR REPLACE FUNCTION  -- add 4 to reported error no
lookup_grid_distinct(h JSONB,
                     row_info JSONB,
                     return_grid_data boolean default false,
                     dis boolean default false)
RETURNS JSONB AS $$
//    var sqls = []
//    var ress = []
    try {
    var query_dir = plv8.find_function('query_grid_dir');
    var errinfo = plv8.find_function('errinfo');
    var ih = {};
    var sql = 'SELECT metadata, lenient, name, group_id, data FROM marty_data_grids WHERE id = $1'
    var dg = plv8.execute(sql, [row_info['id']])[0];
    var res;
    ['h','v'].forEach(function(dir) {
        var infos = dg["metadata"].filter(function(md) { return md["dir"] == dir; });
        if (infos.length == 0)
        {
           ih[dir] = [0]
           return
        }
        a = query_dir(h, infos, row_info, dg['group_id']);
//        sqls.push(a);
        ih[dir] = []
        if (a) {
            res = plv8.execute(a[0], a[1]);
//            ress.push(res);
            for (var j = 0; j < res.length; j++)
            {
                ih[dir].push(res[j]["index"])
            }
        }
        if (dis && ih[dir].length > 1)  {
          throw Error("matches > 1");
        }
    });
    if ((ih["v"].length == 0 || ih["h"].length == 0) && !dg['lenient'] && !return_grid_data)
       {
         throw Error("Data Grid lookup failed");
       }

    vi = ih["v"].length > 0 ? Math.min.apply(9999, ih["v"]) : null
    hi = ih["h"].length > 0 ? Math.min.apply(9999, ih["h"]) : null

    var result = null;
    if (vi!==null && hi!==null) {
        result = dg["data"][vi][hi];
    }
    return { "result" : result,
             "name"   : dg["name"],
             "data"   : return_grid_data ? dg["data"] : null,
             "metadata" : return_grid_data ? dg["metadata"] : null
            };
    } catch (err) {
         ei = errinfo(err);
/*
         plv8.elog(INFO, '********');
         plv8.elog(INFO, '');
         plv8.elog(INFO, `ERROR: ${JSON.stringify(ei)}`);
         for (var k=0; k<sqls.length; ++k) {
             plv8.elog(INFO, `sql = ${sqls[k][0]}`);
             plv8.elog(INFO, `args = ${JSON.stringify(sqls[k][1])}`);
             plv8.elog(INFO, `res = ${JSON.stringify(ress[k])}`);
         }
         plv8.elog(INFO, `params: ${JSON.stringify(h)}`);
         plv8.elog(INFO, `dg: ${JSON.stringify(dg)}`);
*/
         return ei;
    }
$$ LANGUAGE plv8;