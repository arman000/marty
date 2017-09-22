-- required to utilize plv8 extension
CREATE EXTENSION IF NOT EXISTS plv8;

-- required before functions that use require can be called
SET plv8.start_proc = plv8_require;

-- js module table
CREATE TABLE IF NOT EXISTS plv8_js_modules (
  module text unique primary key,
  autoload bool default true,
  source text
);

-- plv_require module cache
CREATE OR REPLACE FUNCTION plv8_require()
RETURNS void AS $$
    moduleCache = {};

    load = function(key, source) {
        var module = {exports: {}};
        eval("(function(module, exports){" + source + "; })")(module, module.exports);

        // store in cache
        moduleCache[key] = module.exports;
        return module.exports;
    };

    require = function(module) {
        if(moduleCache[module])
            return moduleCache[module];

        var rows = plv8.execute(
            "SELECT source FROM plv8_js_modules WHERE module = $1",
            [module]
        );

        if(rows.length === 0) {
            plv8.elog(NOTICE, 'Could not load module: ' + module);
            return null;
        }

        return load(module, rows[0].source);
    };

    var query = 'SELECT module, source FROM plv8_js_modules WHERE autoload = true';
    plv8.execute(query).forEach(function(row) {
        load(row.module, row.source);
    });
$$ LANGUAGE plv8;

INSERT INTO plv8_js_modules (module, autoload, source) values ('sql_index_mapper', true, '
    module.exports = function(s) {
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
    }
');

INSERT INTO plv8_js_modules (module, autoload, source) values ('sql_type_mapper', true, '
    module.exports = function(s) {
      switch(s) {
        case "boolean":
          return "key = ?";
        case "numrange":
        case "int4range":
          return "key @> ?";
        default:    
          return "key @> ARRAY[?]";
      }
    }
');

INSERT INTO plv8_js_modules (module, autoload, source) values ('sql_type_caster', true, '
    module.exports = function(s, v) {;
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
    }
');

-- simple builder that just takes in a JSON object and builds the query from it
-- should expand on this in the future and make it fully fleshed out/better
INSERT INTO plv8_js_modules (module, autoload, source) values ('sql_builder', true, '
    module.exports = function(params) {
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
    }
');

-- incomplete wrapper for plv8.execute; might need to implement with sql_builder
INSERT INTO plv8_js_modules (module, autoload, source) values ('sql_execute', true, '
    module.exports = function(sql) {
     res = plv8.execute(sql)
     if (res.length == 1) { return res[0]; }
     return "";
    }
');

-- get dir_infos from provided metadata
INSERT INTO plv8_js_modules (module, autoload, source) values ('dir_infos', true, '
    module.exports = function(metadata, dir) {
      var temp = [];
      for (var i = 0; i < metadata.length; i++)
      {
        if (metadata[i]["dir"] == dir){ temp.push(metadata[i]); }
      }
      return temp;
    }
');
delete from plv8_js_modules where module = 'query_grid_dir';
-- query_grid_dir javascript implementation; issues still with Gemini classes
INSERT INTO plv8_js_modules (module, autoload, source) values ('query_grid_dir', true, '
module.exports = function(h, infos, row_info, group_id) {

if (infos.length == 0) {return [0];}

var idx_mapper = require("sql_index_mapper");
var typ_mapper = require("sql_type_mapper");
var typ_caster = require("sql_type_caster");
var sql_build  = require("sql_builder");
var sql_exec   = require("sql_execute");
var quote      = require("quote");
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
var sqls = temp.join(" INTERSECT ")

temp = []
var res = plv8.execute(sqls)
for (var i = 0; i < res.length; i++)
{
  temp.push(res[i]["index"])
}
return temp
}
');

-- quote function just makes strings work well with sql statements
INSERT INTO plv8_js_modules (module, autoload, source) values ('quote', true, $$
    module.exports = function(arg) {
      switch(typeof arg) {
        case "string":
          return "'" + arg + "'";
        default:
          return arg;
      }
    }
$$);

-- query_grid_dir stub
CREATE OR REPLACE FUNCTION query_grid_dir(h JSONB, infos JSONB[], row_info JSONB)
RETURNS integer[] AS $$
var query_grid_dir = require('query_grid_dir')
return query_grid_dir(h, infos, row_info)
$$ LANGUAGE plv8;

-- lookup_grid_distinct js implementation; missing some functionality (can implement,
-- when fully fleshing out)
CREATE OR REPLACE FUNCTION lookup_grid_distinct(pt text,
                                               h JSONB,
                                               row_info JSONB,
                                               ret_grid_data boolean default false,
                                               dis boolean default false)
RETURNS JSONB AS $$

var dir_infos = require('dir_infos');
var query_dir = require('query_grid_dir')
var dirs = ['h', 'v']
var ih = {}
var dg = plv8.execute('SELECT group_id, data, name, lenient, metadata FROM marty_data_grids WHERE id = $1',
                                [row_info['id']])[0]['metadata']
for (var i = 0; i < dirs.length; i++)
  {
    var infos = dir_infos(dg['metadata'], dirs[i])
    ih[dirs[i]] = query_dir(h, infos, row_info, dg['group_id'])
    
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

if ((vi == null && hi == null) && !dg['lenient'] && !ret_grid_data)
   {
     return {"error" : "Data Grid lookup failed",
             "elements": [vi, hi, dg['lenient'], ret_grid_data]};
   }

// MISSING: modify grid functionality would be here

// quick try/catch to determine null indeces (temp)
try{dg["data"][vi][hi]}
catch(err){ return { "result" : null,
                     "name"   : dg["name"]}}
return { "result" : dg["data"][vi][hi],
         "name"   : dg["name"],
       };
$$ LANGUAGE plv8;
