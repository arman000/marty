// PARAM: err JSONB
// RETURN: JSONB
var locre = /at.*[ (]([a-z][a-z0-9_]*[:][0-9]+)[:][0-9]+/i;
var stack = err.stack;
var res = '';
if (stack) {
    var lines = stack.split('\\n');
    for (i=0, len=lines.length; i<len; ++i) {
        m = locre.exec(lines[i]);
        if (m) {
            res += m[1];
        }
    }
    return { "error": res + " " + err.message };
}
else return { "error": err };
