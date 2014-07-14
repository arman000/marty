from pyxll import xl_func, xl_version, xlAsyncReturn

import json
import requests

import multiprocessing
from multiprocessing.pool import ThreadPool

# Excel 2010 or newer is needed since we require async_handle support.
if xl_version() < 14:
    raise Exception("Gemini calls not supported in older Excel versions")

# global hash which stores Gemini call results
RESULTS = {}

# FIXME: hard-coded pool size
pool = ThreadPool(processes=20)

@xl_func(": void")
def gemini_reset():
    global RESULTS
    RESULTS = {}

@xl_func("string, var, var, var, var: var")
def gemini_attr(hkey, *a):
    v = RESULTS.get(hkey)

    try:
        for attr in a:
            if attr is None:
                break

            if isinstance(attr, (int, float)):
                attr = int(attr)

                if not isinstance(v, list):
                    raise Exception("bad index %d" % attr)

                v = v[attr]
            elif isinstance(attr, (str, unicode)):
                if not isinstance(v, dict):
                    raise Exception("bad index %s" % attr)
                v = v[attr]
            else:
                raise Exception("bad attr access %s" % attr)

        if isinstance(v, (dict, list)):
            v = str(v)

        return v
    except Exception, exc:
        return "Exception: %s" % (exc,)

@xl_func("async_handle, string, string, string, string,"
         "var[] keys, var[] values: string")
def gemini_call(handle, url_base, script, node, attr, keys, values):

    def thread_func(data):
        try:
            r = requests.post(url_base,
                              params  = data,
                              headers = {'content-type': 'application/json'},
                              )

            res = json.loads(r.text)

            if isinstance(res, dict) and "error" in res:
                raise Exception(str(res["error"]))

            if not isinstance(res, list) or len(res) != 1:
                raise Exception("unexpected result from Gemini")

            hkey = str(hash(tuple(values[0])))

            RESULTS[hkey] = res[0]

            result = hkey
        except Exception, exc:
            result = "Exception: %s" % (exc,)

        xlAsyncReturn(handle, result)

    ##############################

    try:
        if not keys:
            keys = [[]]

        if not values:
            values = [[]]

        if len(keys) != 1:
            raise Exception("bad keys range")

        if len(values) != 1:
            raise Exception("bad values range")

        params = dict(zip(keys[0], values[0]))

        data = dict(
            node   = node,
            script = script,
            attrs  = json.dumps([attr]),
            params = json.dumps(params),
        )

        pool.map(thread_func, [data])

    except Exception, exc:
        xlAsyncReturn(handle, "Exception: %s" % (exc,))
