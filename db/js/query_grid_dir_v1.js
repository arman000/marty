// PARAM: h JSONB
// PARAM: infos JSONB[]
// PARAM: row_info JSONB
// RETURN: JSONB
var getfilter = function(type, idx) {
    switch(type) {
    case "boolean":
        return "key = $" + idx + " OR ";
    case "numrange":
        return "key @> $" + idx + "::numeric OR ";
    case "int4range":
        return "key @> $" + idx + "::integer OR ";
    case "integer":
        return "key @> ARRAY[$" + idx + "::integer] OR ";
    default:
        return "key @> ARRAY[$" + idx + "::text] OR ";
    }
}

var temp = [];
var args = [];

var sql;
for (var sqlidx=1, i = 0; i < infos.length; i++) {
    var type = infos[i]["type"];
    var attr = infos[i]["attr"];
    var v = h[attr];
    if (!h.hasOwnProperty(attr)) {
        //throw Error("missing attr " + attr)
        continue;
    }
    switch (type) {
    case 'boolean':
    case "numrange":
    case "int4range":
    case "integer":
        tab = "marty_grid_index_" + type + "s";
        break;
    default:
        tab = 'marty_grid_index_strings';
    };

    sql = "SELECT DISTINCT index from " + tab +
        " WHERE data_grid_id = $" + sqlidx++ +
        " AND created_dt = $"    + sqlidx++ +
        " AND attr = $"          + sqlidx++ + ' ';

    args.push(row_info["group_id"]);
    args.push(row_info["created_dt"]);
    args.push(attr);

    if (v!==null) {
        filt = getfilter(type, sqlidx++);
        args.push(v);
    } else filt = ''
    sql += ' AND (' + filt + "key is NULL) ";

    temp.push(sql);
}
if (temp ==[]) return null;
return [temp.join(" INTERSECT "), args];
