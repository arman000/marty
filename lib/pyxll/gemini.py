 from pyxll import (
    xl_func,
    xl_version,
    xl_menu,
    xl_macro,
    xlAsyncReturn,
    xlcAlert,
    xlcCalculateNow,
    xlcCalculateDocument,
    )
import pyxll
import hashlib

import win32com.client

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

def xl_app():
    """returns a Dispatch object for the current Excel instance"""
    # get the Excel application object from PyXLL and wrap it
    xl_window = pyxll.get_active_object()
    xl_app = win32com.client.Dispatch(xl_window).Application

    # it's helpful to make sure the gen_py wrapper has been created
    # as otherwise things like constants and event handlers won't work.
    win32com.client.gencache.EnsureDispatch(xl_app)

    return xl_app

# named Excel cell which we will treat as a call version id for
# clearing the Gemini call cache.
GEMINI_CALL_ID = "gemini_call_id"

@xl_macro()
def gemini_increment_id():
    gemini_reset()
    xl = xl_app()
    range = xl.Range(GEMINI_CALL_ID)
    range.Value = range.Value + 1

@xl_menu("Gemini Reset", menu="Gemini")
def gemini_reset_menu():
    xlcAlert("Remove %d cached items" % len(RESULTS))
    gemini_reset()
    xl = xl_app()
    range = xl.Range(GEMINI_CALL_ID)
    range.Value = 0

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

            hash_str = str(tuple([script, node, attr] + values[0]))
            hkey = hashlib.md5(hash_str).hexdigest()[:30]

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
