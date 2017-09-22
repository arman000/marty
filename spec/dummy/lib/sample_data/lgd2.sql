-- required to utilize plv8 extension
CREATE EXTENSION IF NOT EXISTS plv8;

-- query_grid_dir stub
CREATE OR REPLACE FUNCTION query_grid_dir(h JSONB, infos JSONB[], row_info JSONB)
RETURNS integer[] AS $$
if (infos.length == 0) {return [0];}

var idx_mapper = function(s) {
      switch(s) {
        case "numrange":
          return "marty_grid_index_numranges";
        case "int4range":
          return "marty_grid_index_int4ranges";
        case "boolean":
          return "marty_grid_index_booleans";
        case "integer":
          return "marty_grid_index_integers";
        default:
          return "marty_grid_index_strings";
      }
    };
var typ_mapper = function(s) {
      switch(s) {
        case "boolean":
          return "key = ?";
        case "numrange":
        case "int4range":
          return "key @> ?";
        default:    
          return "key @> ARRAY[?]";
      }
    };
var typ_caster = function(s, v) {;
      switch(s) {
        case "boolean":
          return v
        case "numrange":
          return parseFloat(v).toFixed(1);
        case "in4range", "integer":
          return parseInt(v);
        default:
          // need a way to interpret gemini object or pass in something differently.
          return "" + v
      }
    };
// simple builder that just takes in a JSON object and builds the query from it
// should expand on this in the future and make it fully fleshed out/better
var sql_build  = function(params) {
      var select = "SELECT DISTINCT " + params["select"].join(" FROM ");
      var wheres = [];
      for (var i = 0; i < params["where"].length; i++)
      {
        wheres.push(params["where"][i].join(" = "));
      }
      wheres = wheres.join(" AND ");
      if (params["contains"])
      {
        return select + " WHERE " + wheres + " AND " + "(" + params["contains"] + ")";    
      }
      return select + " WHERE " + wheres;
    };
var sql_exec   = function(sql) {
                    res = plv8.execute(sql)
                    if (res.length == 1) { return res[0]; }
                    return "";     
                  };
var quote      = function(arg) {
                  switch(typeof arg) {
                    case "string":
                       return "'" + arg + "'";
                    default:
                       return arg;
                    }
                  };
var temp = []
for (var i = 0; i < infos.length; i++)
  {
    var type = infos[i]["type"];
    var attr = infos[i]["attr"];

    if (!h.hasOwnProperty(attr)) {continue;}

    var q = "key is NULL";
    var v = h[attr];
    
    if (v != null) {
      q = typ_mapper(type) + " OR " + q;
      v = typ_caster(type, v);

      if (type == "string" || isNaN(v)) {q = q.replace("?", quote(v));}
      else {q = q.replace("?", v.toString());}
    }
    
    var group_id = plv8.execute("SELECT group_id from marty_data_grids WHERE id = $1", 
                            [row_info["id"]])[0]["group_id"];

    var tbl_name = idx_mapper(type);
    var sq_args = {
                  "select"   : ["index", tbl_name],
                  "where"    : [["data_grid_id", quote(group_id)],
                                ["created_dt", quote(row_info["created_dt"])],
                                ["attr", quote(attr)]],
                  "contains" : q
                  }
         
    temp.push(sql_build(sq_args));
  }
var sqls = temp.join(" INTERSECT ");

temp = [];
var res = plv8.execute(sqls);
for (var i = 0; i < res.length; i++)
{
  temp.push(res[i]["index"]);
}
return temp;

$$ LANGUAGE plv8;

-- lookup_grid_distinct js implementation; missing some functionality (can implement,
-- when fully fleshing out)
CREATE OR REPLACE FUNCTION lookup_grid_distinct2(pt text,
                                               h JSONB,
                                               row_info JSONB,
                                               ret_grid_data boolean default false,
                                               dis boolean default false)
RETURNS JSONB AS $$

var dir_infos = function(metadata, dir) {
      var temp = [];
      for (var i = 0; i < metadata.length; i++)
      {
        if (metadata[i]["dir"] == dir){ temp.push(metadata[i]); }
      }
      return temp;
    };
var query_dir = plv8.find_function('query_grid_dir');    

var dirs = ['h', 'v']
var ih = {}

for (var i = 0; i < dirs.length; i++)
  {
    var metadata = plv8.execute('SELECT metadata FROM marty_data_grids WHERE id = $1',
                                [row_info['id']])[0]['metadata']
                                
    var infos = dir_infos(metadata, dirs[i])
    ih[dirs[i]] = query_dir(h, infos, row_info)
    
    if (ih[dirs[i]] == null && !ret_grid_data){return {"error": "attr error"};}
    if (dis && ih[dirs[i]] != null && ih[dirs[i]].length > 1)
    {
      return {"error": "matches > 1" };
    }
  }

if (ih["v"] && ih["h"])
{
  vi = Math.min.apply(null, ih["v"]);
  hi = Math.min.apply(null, ih["h"]);
}

var lenient = plv8.execute('SELECT lenient FROM marty_data_grids WHERE id = $1',
                           [row_info['id']])[0]['lenient']
                           
if ((vi == null && hi == null) && !lenient && !ret_grid_data)
   {
     return {"error" : "Data Grid lookup failed",
             "elements": [vi, hi, lenient, ret_grid_data]};
   }

// MISSING: modify grid functionality would be here

var dg_info = plv8.execute('SELECT data, name FROM marty_data_grids WHERE id = $1',
                           [row_info['id']])[0]

// quick try/catch to determine null indeces (temp)
try{dg_info["data"][vi][hi]}
catch(err){ return { "result" : null,
                     "name"   : dg_info["name"]}}
return { "result" : dg_info["data"][vi][hi],
         "name"   : dg_info["name"],
       };
$$ LANGUAGE plv8;
