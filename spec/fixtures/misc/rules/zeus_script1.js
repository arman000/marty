var zeus_bundled_code = (() => {
  var __create = Object.create;
  var __defProp = Object.defineProperty;
  var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
  var __getOwnPropNames = Object.getOwnPropertyNames;
  var __getProtoOf = Object.getPrototypeOf;
  var __hasOwnProp = Object.prototype.hasOwnProperty;
  var __markAsModule = (target) => __defProp(target, "__esModule", { value: true });
  var __commonJS = (cb, mod) => function __require() {
    return mod || (0, cb[Object.keys(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  };
  var __export = (target, all) => {
    __markAsModule(target);
    for (var name in all)
      __defProp(target, name, { get: all[name], enumerable: true });
  };
  var __reExport = (target, module, desc) => {
    if (module && typeof module === "object" || typeof module === "function") {
      for (let key of __getOwnPropNames(module))
        if (!__hasOwnProp.call(target, key) && key !== "default")
          __defProp(target, key, { get: () => module[key], enumerable: !(desc = __getOwnPropDesc(module, key)) || desc.enumerable });
    }
    return target;
  };
  var __toModule = (module) => {
    return __reExport(__markAsModule(__defProp(module != null ? __create(__getProtoOf(module)) : {}, "default", module && module.__esModule && "default" in module ? { get: () => module.default, enumerable: true } : { value: module, enumerable: true })), module);
  };

  // node_modules/uri-js/dist/es5/uri.all.js
  var require_uri_all = __commonJS({
    "node_modules/uri-js/dist/es5/uri.all.js"(exports, module) {
      (function(global2, factory) {
        typeof exports === "object" && typeof module !== "undefined" ? factory(exports) : typeof define === "function" && define.amd ? define(["exports"], factory) : factory(global2.URI = global2.URI || {});
      })(exports, function(exports2) {
        "use strict";
        function merge() {
          for (var _len = arguments.length, sets = Array(_len), _key = 0; _key < _len; _key++) {
            sets[_key] = arguments[_key];
          }
          if (sets.length > 1) {
            sets[0] = sets[0].slice(0, -1);
            var xl = sets.length - 1;
            for (var x = 1; x < xl; ++x) {
              sets[x] = sets[x].slice(1, -1);
            }
            sets[xl] = sets[xl].slice(1);
            return sets.join("");
          } else {
            return sets[0];
          }
        }
        function subexp(str) {
          return "(?:" + str + ")";
        }
        function typeOf(o4) {
          return o4 === void 0 ? "undefined" : o4 === null ? "null" : Object.prototype.toString.call(o4).split(" ").pop().split("]").shift().toLowerCase();
        }
        function toUpperCase(str) {
          return str.toUpperCase();
        }
        function toArray(obj) {
          return obj !== void 0 && obj !== null ? obj instanceof Array ? obj : typeof obj.length !== "number" || obj.split || obj.setInterval || obj.call ? [obj] : Array.prototype.slice.call(obj) : [];
        }
        function assign(target, source) {
          var obj = target;
          if (source) {
            for (var key in source) {
              obj[key] = source[key];
            }
          }
          return obj;
        }
        function buildExps(isIRI2) {
          var ALPHA$$ = "[A-Za-z]", CR$ = "[\\x0D]", DIGIT$$ = "[0-9]", DQUOTE$$ = "[\\x22]", HEXDIG$$2 = merge(DIGIT$$, "[A-Fa-f]"), LF$$ = "[\\x0A]", SP$$ = "[\\x20]", PCT_ENCODED$2 = subexp(subexp("%[EFef]" + HEXDIG$$2 + "%" + HEXDIG$$2 + HEXDIG$$2 + "%" + HEXDIG$$2 + HEXDIG$$2) + "|" + subexp("%[89A-Fa-f]" + HEXDIG$$2 + "%" + HEXDIG$$2 + HEXDIG$$2) + "|" + subexp("%" + HEXDIG$$2 + HEXDIG$$2)), GEN_DELIMS$$ = "[\\:\\/\\?\\#\\[\\]\\@]", SUB_DELIMS$$ = "[\\!\\$\\&\\'\\(\\)\\*\\+\\,\\;\\=]", RESERVED$$ = merge(GEN_DELIMS$$, SUB_DELIMS$$), UCSCHAR$$ = isIRI2 ? "[\\xA0-\\u200D\\u2010-\\u2029\\u202F-\\uD7FF\\uF900-\\uFDCF\\uFDF0-\\uFFEF]" : "[]", IPRIVATE$$ = isIRI2 ? "[\\uE000-\\uF8FF]" : "[]", UNRESERVED$$2 = merge(ALPHA$$, DIGIT$$, "[\\-\\.\\_\\~]", UCSCHAR$$), SCHEME$ = subexp(ALPHA$$ + merge(ALPHA$$, DIGIT$$, "[\\+\\-\\.]") + "*"), USERINFO$ = subexp(subexp(PCT_ENCODED$2 + "|" + merge(UNRESERVED$$2, SUB_DELIMS$$, "[\\:]")) + "*"), DEC_OCTET$ = subexp(subexp("25[0-5]") + "|" + subexp("2[0-4]" + DIGIT$$) + "|" + subexp("1" + DIGIT$$ + DIGIT$$) + "|" + subexp("[1-9]" + DIGIT$$) + "|" + DIGIT$$), DEC_OCTET_RELAXED$ = subexp(subexp("25[0-5]") + "|" + subexp("2[0-4]" + DIGIT$$) + "|" + subexp("1" + DIGIT$$ + DIGIT$$) + "|" + subexp("0?[1-9]" + DIGIT$$) + "|0?0?" + DIGIT$$), IPV4ADDRESS$ = subexp(DEC_OCTET_RELAXED$ + "\\." + DEC_OCTET_RELAXED$ + "\\." + DEC_OCTET_RELAXED$ + "\\." + DEC_OCTET_RELAXED$), H16$ = subexp(HEXDIG$$2 + "{1,4}"), LS32$ = subexp(subexp(H16$ + "\\:" + H16$) + "|" + IPV4ADDRESS$), IPV6ADDRESS1$ = subexp(subexp(H16$ + "\\:") + "{6}" + LS32$), IPV6ADDRESS2$ = subexp("\\:\\:" + subexp(H16$ + "\\:") + "{5}" + LS32$), IPV6ADDRESS3$ = subexp(subexp(H16$) + "?\\:\\:" + subexp(H16$ + "\\:") + "{4}" + LS32$), IPV6ADDRESS4$ = subexp(subexp(subexp(H16$ + "\\:") + "{0,1}" + H16$) + "?\\:\\:" + subexp(H16$ + "\\:") + "{3}" + LS32$), IPV6ADDRESS5$ = subexp(subexp(subexp(H16$ + "\\:") + "{0,2}" + H16$) + "?\\:\\:" + subexp(H16$ + "\\:") + "{2}" + LS32$), IPV6ADDRESS6$ = subexp(subexp(subexp(H16$ + "\\:") + "{0,3}" + H16$) + "?\\:\\:" + H16$ + "\\:" + LS32$), IPV6ADDRESS7$ = subexp(subexp(subexp(H16$ + "\\:") + "{0,4}" + H16$) + "?\\:\\:" + LS32$), IPV6ADDRESS8$ = subexp(subexp(subexp(H16$ + "\\:") + "{0,5}" + H16$) + "?\\:\\:" + H16$), IPV6ADDRESS9$ = subexp(subexp(subexp(H16$ + "\\:") + "{0,6}" + H16$) + "?\\:\\:"), IPV6ADDRESS$ = subexp([IPV6ADDRESS1$, IPV6ADDRESS2$, IPV6ADDRESS3$, IPV6ADDRESS4$, IPV6ADDRESS5$, IPV6ADDRESS6$, IPV6ADDRESS7$, IPV6ADDRESS8$, IPV6ADDRESS9$].join("|")), ZONEID$ = subexp(subexp(UNRESERVED$$2 + "|" + PCT_ENCODED$2) + "+"), IPV6ADDRZ$ = subexp(IPV6ADDRESS$ + "\\%25" + ZONEID$), IPV6ADDRZ_RELAXED$ = subexp(IPV6ADDRESS$ + subexp("\\%25|\\%(?!" + HEXDIG$$2 + "{2})") + ZONEID$), IPVFUTURE$ = subexp("[vV]" + HEXDIG$$2 + "+\\." + merge(UNRESERVED$$2, SUB_DELIMS$$, "[\\:]") + "+"), IP_LITERAL$ = subexp("\\[" + subexp(IPV6ADDRZ_RELAXED$ + "|" + IPV6ADDRESS$ + "|" + IPVFUTURE$) + "\\]"), REG_NAME$ = subexp(subexp(PCT_ENCODED$2 + "|" + merge(UNRESERVED$$2, SUB_DELIMS$$)) + "*"), HOST$ = subexp(IP_LITERAL$ + "|" + IPV4ADDRESS$ + "(?!" + REG_NAME$ + ")|" + REG_NAME$), PORT$ = subexp(DIGIT$$ + "*"), AUTHORITY$ = subexp(subexp(USERINFO$ + "@") + "?" + HOST$ + subexp("\\:" + PORT$) + "?"), PCHAR$ = subexp(PCT_ENCODED$2 + "|" + merge(UNRESERVED$$2, SUB_DELIMS$$, "[\\:\\@]")), SEGMENT$ = subexp(PCHAR$ + "*"), SEGMENT_NZ$ = subexp(PCHAR$ + "+"), SEGMENT_NZ_NC$ = subexp(subexp(PCT_ENCODED$2 + "|" + merge(UNRESERVED$$2, SUB_DELIMS$$, "[\\@]")) + "+"), PATH_ABEMPTY$ = subexp(subexp("\\/" + SEGMENT$) + "*"), PATH_ABSOLUTE$ = subexp("\\/" + subexp(SEGMENT_NZ$ + PATH_ABEMPTY$) + "?"), PATH_NOSCHEME$ = subexp(SEGMENT_NZ_NC$ + PATH_ABEMPTY$), PATH_ROOTLESS$ = subexp(SEGMENT_NZ$ + PATH_ABEMPTY$), PATH_EMPTY$ = "(?!" + PCHAR$ + ")", PATH$ = subexp(PATH_ABEMPTY$ + "|" + PATH_ABSOLUTE$ + "|" + PATH_NOSCHEME$ + "|" + PATH_ROOTLESS$ + "|" + PATH_EMPTY$), QUERY$ = subexp(subexp(PCHAR$ + "|" + merge("[\\/\\?]", IPRIVATE$$)) + "*"), FRAGMENT$ = subexp(subexp(PCHAR$ + "|[\\/\\?]") + "*"), HIER_PART$ = subexp(subexp("\\/\\/" + AUTHORITY$ + PATH_ABEMPTY$) + "|" + PATH_ABSOLUTE$ + "|" + PATH_ROOTLESS$ + "|" + PATH_EMPTY$), URI$ = subexp(SCHEME$ + "\\:" + HIER_PART$ + subexp("\\?" + QUERY$) + "?" + subexp("\\#" + FRAGMENT$) + "?"), RELATIVE_PART$ = subexp(subexp("\\/\\/" + AUTHORITY$ + PATH_ABEMPTY$) + "|" + PATH_ABSOLUTE$ + "|" + PATH_NOSCHEME$ + "|" + PATH_EMPTY$), RELATIVE$ = subexp(RELATIVE_PART$ + subexp("\\?" + QUERY$) + "?" + subexp("\\#" + FRAGMENT$) + "?"), URI_REFERENCE$ = subexp(URI$ + "|" + RELATIVE$), ABSOLUTE_URI$ = subexp(SCHEME$ + "\\:" + HIER_PART$ + subexp("\\?" + QUERY$) + "?"), GENERIC_REF$ = "^(" + SCHEME$ + ")\\:" + subexp(subexp("\\/\\/(" + subexp("(" + USERINFO$ + ")@") + "?(" + HOST$ + ")" + subexp("\\:(" + PORT$ + ")") + "?)") + "?(" + PATH_ABEMPTY$ + "|" + PATH_ABSOLUTE$ + "|" + PATH_ROOTLESS$ + "|" + PATH_EMPTY$ + ")") + subexp("\\?(" + QUERY$ + ")") + "?" + subexp("\\#(" + FRAGMENT$ + ")") + "?$", RELATIVE_REF$ = "^(){0}" + subexp(subexp("\\/\\/(" + subexp("(" + USERINFO$ + ")@") + "?(" + HOST$ + ")" + subexp("\\:(" + PORT$ + ")") + "?)") + "?(" + PATH_ABEMPTY$ + "|" + PATH_ABSOLUTE$ + "|" + PATH_NOSCHEME$ + "|" + PATH_EMPTY$ + ")") + subexp("\\?(" + QUERY$ + ")") + "?" + subexp("\\#(" + FRAGMENT$ + ")") + "?$", ABSOLUTE_REF$ = "^(" + SCHEME$ + ")\\:" + subexp(subexp("\\/\\/(" + subexp("(" + USERINFO$ + ")@") + "?(" + HOST$ + ")" + subexp("\\:(" + PORT$ + ")") + "?)") + "?(" + PATH_ABEMPTY$ + "|" + PATH_ABSOLUTE$ + "|" + PATH_ROOTLESS$ + "|" + PATH_EMPTY$ + ")") + subexp("\\?(" + QUERY$ + ")") + "?$", SAMEDOC_REF$ = "^" + subexp("\\#(" + FRAGMENT$ + ")") + "?$", AUTHORITY_REF$ = "^" + subexp("(" + USERINFO$ + ")@") + "?(" + HOST$ + ")" + subexp("\\:(" + PORT$ + ")") + "?$";
          return {
            NOT_SCHEME: new RegExp(merge("[^]", ALPHA$$, DIGIT$$, "[\\+\\-\\.]"), "g"),
            NOT_USERINFO: new RegExp(merge("[^\\%\\:]", UNRESERVED$$2, SUB_DELIMS$$), "g"),
            NOT_HOST: new RegExp(merge("[^\\%\\[\\]\\:]", UNRESERVED$$2, SUB_DELIMS$$), "g"),
            NOT_PATH: new RegExp(merge("[^\\%\\/\\:\\@]", UNRESERVED$$2, SUB_DELIMS$$), "g"),
            NOT_PATH_NOSCHEME: new RegExp(merge("[^\\%\\/\\@]", UNRESERVED$$2, SUB_DELIMS$$), "g"),
            NOT_QUERY: new RegExp(merge("[^\\%]", UNRESERVED$$2, SUB_DELIMS$$, "[\\:\\@\\/\\?]", IPRIVATE$$), "g"),
            NOT_FRAGMENT: new RegExp(merge("[^\\%]", UNRESERVED$$2, SUB_DELIMS$$, "[\\:\\@\\/\\?]"), "g"),
            ESCAPE: new RegExp(merge("[^]", UNRESERVED$$2, SUB_DELIMS$$), "g"),
            UNRESERVED: new RegExp(UNRESERVED$$2, "g"),
            OTHER_CHARS: new RegExp(merge("[^\\%]", UNRESERVED$$2, RESERVED$$), "g"),
            PCT_ENCODED: new RegExp(PCT_ENCODED$2, "g"),
            IPV4ADDRESS: new RegExp("^(" + IPV4ADDRESS$ + ")$"),
            IPV6ADDRESS: new RegExp("^\\[?(" + IPV6ADDRESS$ + ")" + subexp(subexp("\\%25|\\%(?!" + HEXDIG$$2 + "{2})") + "(" + ZONEID$ + ")") + "?\\]?$")
          };
        }
        var URI_PROTOCOL = buildExps(false);
        var IRI_PROTOCOL = buildExps(true);
        var slicedToArray = function() {
          function sliceIterator(arr, i) {
            var _arr = [];
            var _n = true;
            var _d = false;
            var _e = void 0;
            try {
              for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) {
                _arr.push(_s.value);
                if (i && _arr.length === i)
                  break;
              }
            } catch (err) {
              _d = true;
              _e = err;
            } finally {
              try {
                if (!_n && _i["return"])
                  _i["return"]();
              } finally {
                if (_d)
                  throw _e;
              }
            }
            return _arr;
          }
          return function(arr, i) {
            if (Array.isArray(arr)) {
              return arr;
            } else if (Symbol.iterator in Object(arr)) {
              return sliceIterator(arr, i);
            } else {
              throw new TypeError("Invalid attempt to destructure non-iterable instance");
            }
          };
        }();
        var toConsumableArray = function(arr) {
          if (Array.isArray(arr)) {
            for (var i = 0, arr2 = Array(arr.length); i < arr.length; i++)
              arr2[i] = arr[i];
            return arr2;
          } else {
            return Array.from(arr);
          }
        };
        var maxInt = 2147483647;
        var base = 36;
        var tMin = 1;
        var tMax = 26;
        var skew = 38;
        var damp = 700;
        var initialBias = 72;
        var initialN = 128;
        var delimiter = "-";
        var regexPunycode = /^xn--/;
        var regexNonASCII = /[^\0-\x7E]/;
        var regexSeparators = /[\x2E\u3002\uFF0E\uFF61]/g;
        var errors = {
          "overflow": "Overflow: input needs wider integers to process",
          "not-basic": "Illegal input >= 0x80 (not a basic code point)",
          "invalid-input": "Invalid input"
        };
        var baseMinusTMin = base - tMin;
        var floor = Math.floor;
        var stringFromCharCode = String.fromCharCode;
        function error$1(type4) {
          throw new RangeError(errors[type4]);
        }
        function map(array, fn) {
          var result = [];
          var length = array.length;
          while (length--) {
            result[length] = fn(array[length]);
          }
          return result;
        }
        function mapDomain(string, fn) {
          var parts = string.split("@");
          var result = "";
          if (parts.length > 1) {
            result = parts[0] + "@";
            string = parts[1];
          }
          string = string.replace(regexSeparators, ".");
          var labels = string.split(".");
          var encoded = map(labels, fn).join(".");
          return result + encoded;
        }
        function ucs2decode(string) {
          var output = [];
          var counter = 0;
          var length = string.length;
          while (counter < length) {
            var value = string.charCodeAt(counter++);
            if (value >= 55296 && value <= 56319 && counter < length) {
              var extra = string.charCodeAt(counter++);
              if ((extra & 64512) == 56320) {
                output.push(((value & 1023) << 10) + (extra & 1023) + 65536);
              } else {
                output.push(value);
                counter--;
              }
            } else {
              output.push(value);
            }
          }
          return output;
        }
        var ucs2encode = function ucs2encode2(array) {
          return String.fromCodePoint.apply(String, toConsumableArray(array));
        };
        var basicToDigit = function basicToDigit2(codePoint) {
          if (codePoint - 48 < 10) {
            return codePoint - 22;
          }
          if (codePoint - 65 < 26) {
            return codePoint - 65;
          }
          if (codePoint - 97 < 26) {
            return codePoint - 97;
          }
          return base;
        };
        var digitToBasic = function digitToBasic2(digit, flag) {
          return digit + 22 + 75 * (digit < 26) - ((flag != 0) << 5);
        };
        var adapt = function adapt2(delta, numPoints, firstTime) {
          var k = 0;
          delta = firstTime ? floor(delta / damp) : delta >> 1;
          delta += floor(delta / numPoints);
          for (; delta > baseMinusTMin * tMax >> 1; k += base) {
            delta = floor(delta / baseMinusTMin);
          }
          return floor(k + (baseMinusTMin + 1) * delta / (delta + skew));
        };
        var decode = function decode2(input) {
          var output = [];
          var inputLength = input.length;
          var i = 0;
          var n = initialN;
          var bias = initialBias;
          var basic = input.lastIndexOf(delimiter);
          if (basic < 0) {
            basic = 0;
          }
          for (var j = 0; j < basic; ++j) {
            if (input.charCodeAt(j) >= 128) {
              error$1("not-basic");
            }
            output.push(input.charCodeAt(j));
          }
          for (var index = basic > 0 ? basic + 1 : 0; index < inputLength; ) {
            var oldi = i;
            for (var w = 1, k = base; ; k += base) {
              if (index >= inputLength) {
                error$1("invalid-input");
              }
              var digit = basicToDigit(input.charCodeAt(index++));
              if (digit >= base || digit > floor((maxInt - i) / w)) {
                error$1("overflow");
              }
              i += digit * w;
              var t = k <= bias ? tMin : k >= bias + tMax ? tMax : k - bias;
              if (digit < t) {
                break;
              }
              var baseMinusT = base - t;
              if (w > floor(maxInt / baseMinusT)) {
                error$1("overflow");
              }
              w *= baseMinusT;
            }
            var out = output.length + 1;
            bias = adapt(i - oldi, out, oldi == 0);
            if (floor(i / out) > maxInt - n) {
              error$1("overflow");
            }
            n += floor(i / out);
            i %= out;
            output.splice(i++, 0, n);
          }
          return String.fromCodePoint.apply(String, output);
        };
        var encode = function encode2(input) {
          var output = [];
          input = ucs2decode(input);
          var inputLength = input.length;
          var n = initialN;
          var delta = 0;
          var bias = initialBias;
          var _iteratorNormalCompletion = true;
          var _didIteratorError = false;
          var _iteratorError = void 0;
          try {
            for (var _iterator = input[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
              var _currentValue2 = _step.value;
              if (_currentValue2 < 128) {
                output.push(stringFromCharCode(_currentValue2));
              }
            }
          } catch (err) {
            _didIteratorError = true;
            _iteratorError = err;
          } finally {
            try {
              if (!_iteratorNormalCompletion && _iterator.return) {
                _iterator.return();
              }
            } finally {
              if (_didIteratorError) {
                throw _iteratorError;
              }
            }
          }
          var basicLength = output.length;
          var handledCPCount = basicLength;
          if (basicLength) {
            output.push(delimiter);
          }
          while (handledCPCount < inputLength) {
            var m = maxInt;
            var _iteratorNormalCompletion2 = true;
            var _didIteratorError2 = false;
            var _iteratorError2 = void 0;
            try {
              for (var _iterator2 = input[Symbol.iterator](), _step2; !(_iteratorNormalCompletion2 = (_step2 = _iterator2.next()).done); _iteratorNormalCompletion2 = true) {
                var currentValue = _step2.value;
                if (currentValue >= n && currentValue < m) {
                  m = currentValue;
                }
              }
            } catch (err) {
              _didIteratorError2 = true;
              _iteratorError2 = err;
            } finally {
              try {
                if (!_iteratorNormalCompletion2 && _iterator2.return) {
                  _iterator2.return();
                }
              } finally {
                if (_didIteratorError2) {
                  throw _iteratorError2;
                }
              }
            }
            var handledCPCountPlusOne = handledCPCount + 1;
            if (m - n > floor((maxInt - delta) / handledCPCountPlusOne)) {
              error$1("overflow");
            }
            delta += (m - n) * handledCPCountPlusOne;
            n = m;
            var _iteratorNormalCompletion3 = true;
            var _didIteratorError3 = false;
            var _iteratorError3 = void 0;
            try {
              for (var _iterator3 = input[Symbol.iterator](), _step3; !(_iteratorNormalCompletion3 = (_step3 = _iterator3.next()).done); _iteratorNormalCompletion3 = true) {
                var _currentValue = _step3.value;
                if (_currentValue < n && ++delta > maxInt) {
                  error$1("overflow");
                }
                if (_currentValue == n) {
                  var q = delta;
                  for (var k = base; ; k += base) {
                    var t = k <= bias ? tMin : k >= bias + tMax ? tMax : k - bias;
                    if (q < t) {
                      break;
                    }
                    var qMinusT = q - t;
                    var baseMinusT = base - t;
                    output.push(stringFromCharCode(digitToBasic(t + qMinusT % baseMinusT, 0)));
                    q = floor(qMinusT / baseMinusT);
                  }
                  output.push(stringFromCharCode(digitToBasic(q, 0)));
                  bias = adapt(delta, handledCPCountPlusOne, handledCPCount == basicLength);
                  delta = 0;
                  ++handledCPCount;
                }
              }
            } catch (err) {
              _didIteratorError3 = true;
              _iteratorError3 = err;
            } finally {
              try {
                if (!_iteratorNormalCompletion3 && _iterator3.return) {
                  _iterator3.return();
                }
              } finally {
                if (_didIteratorError3) {
                  throw _iteratorError3;
                }
              }
            }
            ++delta;
            ++n;
          }
          return output.join("");
        };
        var toUnicode = function toUnicode2(input) {
          return mapDomain(input, function(string) {
            return regexPunycode.test(string) ? decode(string.slice(4).toLowerCase()) : string;
          });
        };
        var toASCII = function toASCII2(input) {
          return mapDomain(input, function(string) {
            return regexNonASCII.test(string) ? "xn--" + encode(string) : string;
          });
        };
        var punycode = {
          "version": "2.1.0",
          "ucs2": {
            "decode": ucs2decode,
            "encode": ucs2encode
          },
          "decode": decode,
          "encode": encode,
          "toASCII": toASCII,
          "toUnicode": toUnicode
        };
        var SCHEMES = {};
        function pctEncChar(chr) {
          var c = chr.charCodeAt(0);
          var e = void 0;
          if (c < 16)
            e = "%0" + c.toString(16).toUpperCase();
          else if (c < 128)
            e = "%" + c.toString(16).toUpperCase();
          else if (c < 2048)
            e = "%" + (c >> 6 | 192).toString(16).toUpperCase() + "%" + (c & 63 | 128).toString(16).toUpperCase();
          else
            e = "%" + (c >> 12 | 224).toString(16).toUpperCase() + "%" + (c >> 6 & 63 | 128).toString(16).toUpperCase() + "%" + (c & 63 | 128).toString(16).toUpperCase();
          return e;
        }
        function pctDecChars(str) {
          var newStr = "";
          var i = 0;
          var il = str.length;
          while (i < il) {
            var c = parseInt(str.substr(i + 1, 2), 16);
            if (c < 128) {
              newStr += String.fromCharCode(c);
              i += 3;
            } else if (c >= 194 && c < 224) {
              if (il - i >= 6) {
                var c2 = parseInt(str.substr(i + 4, 2), 16);
                newStr += String.fromCharCode((c & 31) << 6 | c2 & 63);
              } else {
                newStr += str.substr(i, 6);
              }
              i += 6;
            } else if (c >= 224) {
              if (il - i >= 9) {
                var _c = parseInt(str.substr(i + 4, 2), 16);
                var c3 = parseInt(str.substr(i + 7, 2), 16);
                newStr += String.fromCharCode((c & 15) << 12 | (_c & 63) << 6 | c3 & 63);
              } else {
                newStr += str.substr(i, 9);
              }
              i += 9;
            } else {
              newStr += str.substr(i, 3);
              i += 3;
            }
          }
          return newStr;
        }
        function _normalizeComponentEncoding(components, protocol) {
          function decodeUnreserved2(str) {
            var decStr = pctDecChars(str);
            return !decStr.match(protocol.UNRESERVED) ? str : decStr;
          }
          if (components.scheme)
            components.scheme = String(components.scheme).replace(protocol.PCT_ENCODED, decodeUnreserved2).toLowerCase().replace(protocol.NOT_SCHEME, "");
          if (components.userinfo !== void 0)
            components.userinfo = String(components.userinfo).replace(protocol.PCT_ENCODED, decodeUnreserved2).replace(protocol.NOT_USERINFO, pctEncChar).replace(protocol.PCT_ENCODED, toUpperCase);
          if (components.host !== void 0)
            components.host = String(components.host).replace(protocol.PCT_ENCODED, decodeUnreserved2).toLowerCase().replace(protocol.NOT_HOST, pctEncChar).replace(protocol.PCT_ENCODED, toUpperCase);
          if (components.path !== void 0)
            components.path = String(components.path).replace(protocol.PCT_ENCODED, decodeUnreserved2).replace(components.scheme ? protocol.NOT_PATH : protocol.NOT_PATH_NOSCHEME, pctEncChar).replace(protocol.PCT_ENCODED, toUpperCase);
          if (components.query !== void 0)
            components.query = String(components.query).replace(protocol.PCT_ENCODED, decodeUnreserved2).replace(protocol.NOT_QUERY, pctEncChar).replace(protocol.PCT_ENCODED, toUpperCase);
          if (components.fragment !== void 0)
            components.fragment = String(components.fragment).replace(protocol.PCT_ENCODED, decodeUnreserved2).replace(protocol.NOT_FRAGMENT, pctEncChar).replace(protocol.PCT_ENCODED, toUpperCase);
          return components;
        }
        function _stripLeadingZeros(str) {
          return str.replace(/^0*(.*)/, "$1") || "0";
        }
        function _normalizeIPv4(host, protocol) {
          var matches = host.match(protocol.IPV4ADDRESS) || [];
          var _matches = slicedToArray(matches, 2), address = _matches[1];
          if (address) {
            return address.split(".").map(_stripLeadingZeros).join(".");
          } else {
            return host;
          }
        }
        function _normalizeIPv6(host, protocol) {
          var matches = host.match(protocol.IPV6ADDRESS) || [];
          var _matches2 = slicedToArray(matches, 3), address = _matches2[1], zone = _matches2[2];
          if (address) {
            var _address$toLowerCase$ = address.toLowerCase().split("::").reverse(), _address$toLowerCase$2 = slicedToArray(_address$toLowerCase$, 2), last = _address$toLowerCase$2[0], first = _address$toLowerCase$2[1];
            var firstFields = first ? first.split(":").map(_stripLeadingZeros) : [];
            var lastFields = last.split(":").map(_stripLeadingZeros);
            var isLastFieldIPv4Address = protocol.IPV4ADDRESS.test(lastFields[lastFields.length - 1]);
            var fieldCount = isLastFieldIPv4Address ? 7 : 8;
            var lastFieldsStart = lastFields.length - fieldCount;
            var fields = Array(fieldCount);
            for (var x = 0; x < fieldCount; ++x) {
              fields[x] = firstFields[x] || lastFields[lastFieldsStart + x] || "";
            }
            if (isLastFieldIPv4Address) {
              fields[fieldCount - 1] = _normalizeIPv4(fields[fieldCount - 1], protocol);
            }
            var allZeroFields = fields.reduce(function(acc, field, index) {
              if (!field || field === "0") {
                var lastLongest = acc[acc.length - 1];
                if (lastLongest && lastLongest.index + lastLongest.length === index) {
                  lastLongest.length++;
                } else {
                  acc.push({ index, length: 1 });
                }
              }
              return acc;
            }, []);
            var longestZeroFields = allZeroFields.sort(function(a3, b) {
              return b.length - a3.length;
            })[0];
            var newHost = void 0;
            if (longestZeroFields && longestZeroFields.length > 1) {
              var newFirst = fields.slice(0, longestZeroFields.index);
              var newLast = fields.slice(longestZeroFields.index + longestZeroFields.length);
              newHost = newFirst.join(":") + "::" + newLast.join(":");
            } else {
              newHost = fields.join(":");
            }
            if (zone) {
              newHost += "%" + zone;
            }
            return newHost;
          } else {
            return host;
          }
        }
        var URI_PARSE = /^(?:([^:\/?#]+):)?(?:\/\/((?:([^\/?#@]*)@)?(\[[^\/?#\]]+\]|[^\/?#:]*)(?:\:(\d*))?))?([^?#]*)(?:\?([^#]*))?(?:#((?:.|\n|\r)*))?/i;
        var NO_MATCH_IS_UNDEFINED = "".match(/(){0}/)[1] === void 0;
        function parse(uriString) {
          var options = arguments.length > 1 && arguments[1] !== void 0 ? arguments[1] : {};
          var components = {};
          var protocol = options.iri !== false ? IRI_PROTOCOL : URI_PROTOCOL;
          if (options.reference === "suffix")
            uriString = (options.scheme ? options.scheme + ":" : "") + "//" + uriString;
          var matches = uriString.match(URI_PARSE);
          if (matches) {
            if (NO_MATCH_IS_UNDEFINED) {
              components.scheme = matches[1];
              components.userinfo = matches[3];
              components.host = matches[4];
              components.port = parseInt(matches[5], 10);
              components.path = matches[6] || "";
              components.query = matches[7];
              components.fragment = matches[8];
              if (isNaN(components.port)) {
                components.port = matches[5];
              }
            } else {
              components.scheme = matches[1] || void 0;
              components.userinfo = uriString.indexOf("@") !== -1 ? matches[3] : void 0;
              components.host = uriString.indexOf("//") !== -1 ? matches[4] : void 0;
              components.port = parseInt(matches[5], 10);
              components.path = matches[6] || "";
              components.query = uriString.indexOf("?") !== -1 ? matches[7] : void 0;
              components.fragment = uriString.indexOf("#") !== -1 ? matches[8] : void 0;
              if (isNaN(components.port)) {
                components.port = uriString.match(/\/\/(?:.|\n)*\:(?:\/|\?|\#|$)/) ? matches[4] : void 0;
              }
            }
            if (components.host) {
              components.host = _normalizeIPv6(_normalizeIPv4(components.host, protocol), protocol);
            }
            if (components.scheme === void 0 && components.userinfo === void 0 && components.host === void 0 && components.port === void 0 && !components.path && components.query === void 0) {
              components.reference = "same-document";
            } else if (components.scheme === void 0) {
              components.reference = "relative";
            } else if (components.fragment === void 0) {
              components.reference = "absolute";
            } else {
              components.reference = "uri";
            }
            if (options.reference && options.reference !== "suffix" && options.reference !== components.reference) {
              components.error = components.error || "URI is not a " + options.reference + " reference.";
            }
            var schemeHandler = SCHEMES[(options.scheme || components.scheme || "").toLowerCase()];
            if (!options.unicodeSupport && (!schemeHandler || !schemeHandler.unicodeSupport)) {
              if (components.host && (options.domainHost || schemeHandler && schemeHandler.domainHost)) {
                try {
                  components.host = punycode.toASCII(components.host.replace(protocol.PCT_ENCODED, pctDecChars).toLowerCase());
                } catch (e) {
                  components.error = components.error || "Host's domain name can not be converted to ASCII via punycode: " + e;
                }
              }
              _normalizeComponentEncoding(components, URI_PROTOCOL);
            } else {
              _normalizeComponentEncoding(components, protocol);
            }
            if (schemeHandler && schemeHandler.parse) {
              schemeHandler.parse(components, options);
            }
          } else {
            components.error = components.error || "URI can not be parsed.";
          }
          return components;
        }
        function _recomposeAuthority(components, options) {
          var protocol = options.iri !== false ? IRI_PROTOCOL : URI_PROTOCOL;
          var uriTokens = [];
          if (components.userinfo !== void 0) {
            uriTokens.push(components.userinfo);
            uriTokens.push("@");
          }
          if (components.host !== void 0) {
            uriTokens.push(_normalizeIPv6(_normalizeIPv4(String(components.host), protocol), protocol).replace(protocol.IPV6ADDRESS, function(_, $1, $2) {
              return "[" + $1 + ($2 ? "%25" + $2 : "") + "]";
            }));
          }
          if (typeof components.port === "number" || typeof components.port === "string") {
            uriTokens.push(":");
            uriTokens.push(String(components.port));
          }
          return uriTokens.length ? uriTokens.join("") : void 0;
        }
        var RDS1 = /^\.\.?\//;
        var RDS2 = /^\/\.(\/|$)/;
        var RDS3 = /^\/\.\.(\/|$)/;
        var RDS5 = /^\/?(?:.|\n)*?(?=\/|$)/;
        function removeDotSegments(input) {
          var output = [];
          while (input.length) {
            if (input.match(RDS1)) {
              input = input.replace(RDS1, "");
            } else if (input.match(RDS2)) {
              input = input.replace(RDS2, "/");
            } else if (input.match(RDS3)) {
              input = input.replace(RDS3, "/");
              output.pop();
            } else if (input === "." || input === "..") {
              input = "";
            } else {
              var im = input.match(RDS5);
              if (im) {
                var s = im[0];
                input = input.slice(s.length);
                output.push(s);
              } else {
                throw new Error("Unexpected dot segment condition");
              }
            }
          }
          return output.join("");
        }
        function serialize(components) {
          var options = arguments.length > 1 && arguments[1] !== void 0 ? arguments[1] : {};
          var protocol = options.iri ? IRI_PROTOCOL : URI_PROTOCOL;
          var uriTokens = [];
          var schemeHandler = SCHEMES[(options.scheme || components.scheme || "").toLowerCase()];
          if (schemeHandler && schemeHandler.serialize)
            schemeHandler.serialize(components, options);
          if (components.host) {
            if (protocol.IPV6ADDRESS.test(components.host)) {
            } else if (options.domainHost || schemeHandler && schemeHandler.domainHost) {
              try {
                components.host = !options.iri ? punycode.toASCII(components.host.replace(protocol.PCT_ENCODED, pctDecChars).toLowerCase()) : punycode.toUnicode(components.host);
              } catch (e) {
                components.error = components.error || "Host's domain name can not be converted to " + (!options.iri ? "ASCII" : "Unicode") + " via punycode: " + e;
              }
            }
          }
          _normalizeComponentEncoding(components, protocol);
          if (options.reference !== "suffix" && components.scheme) {
            uriTokens.push(components.scheme);
            uriTokens.push(":");
          }
          var authority = _recomposeAuthority(components, options);
          if (authority !== void 0) {
            if (options.reference !== "suffix") {
              uriTokens.push("//");
            }
            uriTokens.push(authority);
            if (components.path && components.path.charAt(0) !== "/") {
              uriTokens.push("/");
            }
          }
          if (components.path !== void 0) {
            var s = components.path;
            if (!options.absolutePath && (!schemeHandler || !schemeHandler.absolutePath)) {
              s = removeDotSegments(s);
            }
            if (authority === void 0) {
              s = s.replace(/^\/\//, "/%2F");
            }
            uriTokens.push(s);
          }
          if (components.query !== void 0) {
            uriTokens.push("?");
            uriTokens.push(components.query);
          }
          if (components.fragment !== void 0) {
            uriTokens.push("#");
            uriTokens.push(components.fragment);
          }
          return uriTokens.join("");
        }
        function resolveComponents(base2, relative) {
          var options = arguments.length > 2 && arguments[2] !== void 0 ? arguments[2] : {};
          var skipNormalization = arguments[3];
          var target = {};
          if (!skipNormalization) {
            base2 = parse(serialize(base2, options), options);
            relative = parse(serialize(relative, options), options);
          }
          options = options || {};
          if (!options.tolerant && relative.scheme) {
            target.scheme = relative.scheme;
            target.userinfo = relative.userinfo;
            target.host = relative.host;
            target.port = relative.port;
            target.path = removeDotSegments(relative.path || "");
            target.query = relative.query;
          } else {
            if (relative.userinfo !== void 0 || relative.host !== void 0 || relative.port !== void 0) {
              target.userinfo = relative.userinfo;
              target.host = relative.host;
              target.port = relative.port;
              target.path = removeDotSegments(relative.path || "");
              target.query = relative.query;
            } else {
              if (!relative.path) {
                target.path = base2.path;
                if (relative.query !== void 0) {
                  target.query = relative.query;
                } else {
                  target.query = base2.query;
                }
              } else {
                if (relative.path.charAt(0) === "/") {
                  target.path = removeDotSegments(relative.path);
                } else {
                  if ((base2.userinfo !== void 0 || base2.host !== void 0 || base2.port !== void 0) && !base2.path) {
                    target.path = "/" + relative.path;
                  } else if (!base2.path) {
                    target.path = relative.path;
                  } else {
                    target.path = base2.path.slice(0, base2.path.lastIndexOf("/") + 1) + relative.path;
                  }
                  target.path = removeDotSegments(target.path);
                }
                target.query = relative.query;
              }
              target.userinfo = base2.userinfo;
              target.host = base2.host;
              target.port = base2.port;
            }
            target.scheme = base2.scheme;
          }
          target.fragment = relative.fragment;
          return target;
        }
        function resolve(baseURI, relativeURI, options) {
          var schemelessOptions = assign({ scheme: "null" }, options);
          return serialize(resolveComponents(parse(baseURI, schemelessOptions), parse(relativeURI, schemelessOptions), schemelessOptions, true), schemelessOptions);
        }
        function normalize(uri, options) {
          if (typeof uri === "string") {
            uri = serialize(parse(uri, options), options);
          } else if (typeOf(uri) === "object") {
            uri = parse(serialize(uri, options), options);
          }
          return uri;
        }
        function equal(uriA, uriB, options) {
          if (typeof uriA === "string") {
            uriA = serialize(parse(uriA, options), options);
          } else if (typeOf(uriA) === "object") {
            uriA = serialize(uriA, options);
          }
          if (typeof uriB === "string") {
            uriB = serialize(parse(uriB, options), options);
          } else if (typeOf(uriB) === "object") {
            uriB = serialize(uriB, options);
          }
          return uriA === uriB;
        }
        function escapeComponent(str, options) {
          return str && str.toString().replace(!options || !options.iri ? URI_PROTOCOL.ESCAPE : IRI_PROTOCOL.ESCAPE, pctEncChar);
        }
        function unescapeComponent(str, options) {
          return str && str.toString().replace(!options || !options.iri ? URI_PROTOCOL.PCT_ENCODED : IRI_PROTOCOL.PCT_ENCODED, pctDecChars);
        }
        var handler = {
          scheme: "http",
          domainHost: true,
          parse: function parse2(components, options) {
            if (!components.host) {
              components.error = components.error || "HTTP URIs must have a host.";
            }
            return components;
          },
          serialize: function serialize2(components, options) {
            var secure = String(components.scheme).toLowerCase() === "https";
            if (components.port === (secure ? 443 : 80) || components.port === "") {
              components.port = void 0;
            }
            if (!components.path) {
              components.path = "/";
            }
            return components;
          }
        };
        var handler$1 = {
          scheme: "https",
          domainHost: handler.domainHost,
          parse: handler.parse,
          serialize: handler.serialize
        };
        function isSecure(wsComponents) {
          return typeof wsComponents.secure === "boolean" ? wsComponents.secure : String(wsComponents.scheme).toLowerCase() === "wss";
        }
        var handler$2 = {
          scheme: "ws",
          domainHost: true,
          parse: function parse2(components, options) {
            var wsComponents = components;
            wsComponents.secure = isSecure(wsComponents);
            wsComponents.resourceName = (wsComponents.path || "/") + (wsComponents.query ? "?" + wsComponents.query : "");
            wsComponents.path = void 0;
            wsComponents.query = void 0;
            return wsComponents;
          },
          serialize: function serialize2(wsComponents, options) {
            if (wsComponents.port === (isSecure(wsComponents) ? 443 : 80) || wsComponents.port === "") {
              wsComponents.port = void 0;
            }
            if (typeof wsComponents.secure === "boolean") {
              wsComponents.scheme = wsComponents.secure ? "wss" : "ws";
              wsComponents.secure = void 0;
            }
            if (wsComponents.resourceName) {
              var _wsComponents$resourc = wsComponents.resourceName.split("?"), _wsComponents$resourc2 = slicedToArray(_wsComponents$resourc, 2), path = _wsComponents$resourc2[0], query = _wsComponents$resourc2[1];
              wsComponents.path = path && path !== "/" ? path : void 0;
              wsComponents.query = query;
              wsComponents.resourceName = void 0;
            }
            wsComponents.fragment = void 0;
            return wsComponents;
          }
        };
        var handler$3 = {
          scheme: "wss",
          domainHost: handler$2.domainHost,
          parse: handler$2.parse,
          serialize: handler$2.serialize
        };
        var O = {};
        var isIRI = true;
        var UNRESERVED$$ = "[A-Za-z0-9\\-\\.\\_\\~" + (isIRI ? "\\xA0-\\u200D\\u2010-\\u2029\\u202F-\\uD7FF\\uF900-\\uFDCF\\uFDF0-\\uFFEF" : "") + "]";
        var HEXDIG$$ = "[0-9A-Fa-f]";
        var PCT_ENCODED$ = subexp(subexp("%[EFef]" + HEXDIG$$ + "%" + HEXDIG$$ + HEXDIG$$ + "%" + HEXDIG$$ + HEXDIG$$) + "|" + subexp("%[89A-Fa-f]" + HEXDIG$$ + "%" + HEXDIG$$ + HEXDIG$$) + "|" + subexp("%" + HEXDIG$$ + HEXDIG$$));
        var ATEXT$$ = "[A-Za-z0-9\\!\\$\\%\\'\\*\\+\\-\\^\\_\\`\\{\\|\\}\\~]";
        var QTEXT$$ = "[\\!\\$\\%\\'\\(\\)\\*\\+\\,\\-\\.0-9\\<\\>A-Z\\x5E-\\x7E]";
        var VCHAR$$ = merge(QTEXT$$, '[\\"\\\\]');
        var SOME_DELIMS$$ = "[\\!\\$\\'\\(\\)\\*\\+\\,\\;\\:\\@]";
        var UNRESERVED = new RegExp(UNRESERVED$$, "g");
        var PCT_ENCODED = new RegExp(PCT_ENCODED$, "g");
        var NOT_LOCAL_PART = new RegExp(merge("[^]", ATEXT$$, "[\\.]", '[\\"]', VCHAR$$), "g");
        var NOT_HFNAME = new RegExp(merge("[^]", UNRESERVED$$, SOME_DELIMS$$), "g");
        var NOT_HFVALUE = NOT_HFNAME;
        function decodeUnreserved(str) {
          var decStr = pctDecChars(str);
          return !decStr.match(UNRESERVED) ? str : decStr;
        }
        var handler$4 = {
          scheme: "mailto",
          parse: function parse$$1(components, options) {
            var mailtoComponents = components;
            var to = mailtoComponents.to = mailtoComponents.path ? mailtoComponents.path.split(",") : [];
            mailtoComponents.path = void 0;
            if (mailtoComponents.query) {
              var unknownHeaders = false;
              var headers = {};
              var hfields = mailtoComponents.query.split("&");
              for (var x = 0, xl = hfields.length; x < xl; ++x) {
                var hfield = hfields[x].split("=");
                switch (hfield[0]) {
                  case "to":
                    var toAddrs = hfield[1].split(",");
                    for (var _x = 0, _xl = toAddrs.length; _x < _xl; ++_x) {
                      to.push(toAddrs[_x]);
                    }
                    break;
                  case "subject":
                    mailtoComponents.subject = unescapeComponent(hfield[1], options);
                    break;
                  case "body":
                    mailtoComponents.body = unescapeComponent(hfield[1], options);
                    break;
                  default:
                    unknownHeaders = true;
                    headers[unescapeComponent(hfield[0], options)] = unescapeComponent(hfield[1], options);
                    break;
                }
              }
              if (unknownHeaders)
                mailtoComponents.headers = headers;
            }
            mailtoComponents.query = void 0;
            for (var _x2 = 0, _xl2 = to.length; _x2 < _xl2; ++_x2) {
              var addr = to[_x2].split("@");
              addr[0] = unescapeComponent(addr[0]);
              if (!options.unicodeSupport) {
                try {
                  addr[1] = punycode.toASCII(unescapeComponent(addr[1], options).toLowerCase());
                } catch (e) {
                  mailtoComponents.error = mailtoComponents.error || "Email address's domain name can not be converted to ASCII via punycode: " + e;
                }
              } else {
                addr[1] = unescapeComponent(addr[1], options).toLowerCase();
              }
              to[_x2] = addr.join("@");
            }
            return mailtoComponents;
          },
          serialize: function serialize$$1(mailtoComponents, options) {
            var components = mailtoComponents;
            var to = toArray(mailtoComponents.to);
            if (to) {
              for (var x = 0, xl = to.length; x < xl; ++x) {
                var toAddr = String(to[x]);
                var atIdx = toAddr.lastIndexOf("@");
                var localPart = toAddr.slice(0, atIdx).replace(PCT_ENCODED, decodeUnreserved).replace(PCT_ENCODED, toUpperCase).replace(NOT_LOCAL_PART, pctEncChar);
                var domain = toAddr.slice(atIdx + 1);
                try {
                  domain = !options.iri ? punycode.toASCII(unescapeComponent(domain, options).toLowerCase()) : punycode.toUnicode(domain);
                } catch (e) {
                  components.error = components.error || "Email address's domain name can not be converted to " + (!options.iri ? "ASCII" : "Unicode") + " via punycode: " + e;
                }
                to[x] = localPart + "@" + domain;
              }
              components.path = to.join(",");
            }
            var headers = mailtoComponents.headers = mailtoComponents.headers || {};
            if (mailtoComponents.subject)
              headers["subject"] = mailtoComponents.subject;
            if (mailtoComponents.body)
              headers["body"] = mailtoComponents.body;
            var fields = [];
            for (var name in headers) {
              if (headers[name] !== O[name]) {
                fields.push(name.replace(PCT_ENCODED, decodeUnreserved).replace(PCT_ENCODED, toUpperCase).replace(NOT_HFNAME, pctEncChar) + "=" + headers[name].replace(PCT_ENCODED, decodeUnreserved).replace(PCT_ENCODED, toUpperCase).replace(NOT_HFVALUE, pctEncChar));
              }
            }
            if (fields.length) {
              components.query = fields.join("&");
            }
            return components;
          }
        };
        var URN_PARSE = /^([^\:]+)\:(.*)/;
        var handler$5 = {
          scheme: "urn",
          parse: function parse$$1(components, options) {
            var matches = components.path && components.path.match(URN_PARSE);
            var urnComponents = components;
            if (matches) {
              var scheme = options.scheme || urnComponents.scheme || "urn";
              var nid = matches[1].toLowerCase();
              var nss = matches[2];
              var urnScheme = scheme + ":" + (options.nid || nid);
              var schemeHandler = SCHEMES[urnScheme];
              urnComponents.nid = nid;
              urnComponents.nss = nss;
              urnComponents.path = void 0;
              if (schemeHandler) {
                urnComponents = schemeHandler.parse(urnComponents, options);
              }
            } else {
              urnComponents.error = urnComponents.error || "URN can not be parsed.";
            }
            return urnComponents;
          },
          serialize: function serialize$$1(urnComponents, options) {
            var scheme = options.scheme || urnComponents.scheme || "urn";
            var nid = urnComponents.nid;
            var urnScheme = scheme + ":" + (options.nid || nid);
            var schemeHandler = SCHEMES[urnScheme];
            if (schemeHandler) {
              urnComponents = schemeHandler.serialize(urnComponents, options);
            }
            var uriComponents = urnComponents;
            var nss = urnComponents.nss;
            uriComponents.path = (nid || options.nid) + ":" + nss;
            return uriComponents;
          }
        };
        var UUID = /^[0-9A-Fa-f]{8}(?:\-[0-9A-Fa-f]{4}){3}\-[0-9A-Fa-f]{12}$/;
        var handler$6 = {
          scheme: "urn:uuid",
          parse: function parse2(urnComponents, options) {
            var uuidComponents = urnComponents;
            uuidComponents.uuid = uuidComponents.nss;
            uuidComponents.nss = void 0;
            if (!options.tolerant && (!uuidComponents.uuid || !uuidComponents.uuid.match(UUID))) {
              uuidComponents.error = uuidComponents.error || "UUID is not valid.";
            }
            return uuidComponents;
          },
          serialize: function serialize2(uuidComponents, options) {
            var urnComponents = uuidComponents;
            urnComponents.nss = (uuidComponents.uuid || "").toLowerCase();
            return urnComponents;
          }
        };
        SCHEMES[handler.scheme] = handler;
        SCHEMES[handler$1.scheme] = handler$1;
        SCHEMES[handler$2.scheme] = handler$2;
        SCHEMES[handler$3.scheme] = handler$3;
        SCHEMES[handler$4.scheme] = handler$4;
        SCHEMES[handler$5.scheme] = handler$5;
        SCHEMES[handler$6.scheme] = handler$6;
        exports2.SCHEMES = SCHEMES;
        exports2.pctEncChar = pctEncChar;
        exports2.pctDecChars = pctDecChars;
        exports2.parse = parse;
        exports2.removeDotSegments = removeDotSegments;
        exports2.serialize = serialize;
        exports2.resolveComponents = resolveComponents;
        exports2.resolve = resolve;
        exports2.normalize = normalize;
        exports2.equal = equal;
        exports2.escapeComponent = escapeComponent;
        exports2.unescapeComponent = unescapeComponent;
        Object.defineProperty(exports2, "__esModule", { value: true });
      });
    }
  });

  // node_modules/fast-deep-equal/index.js
  var require_fast_deep_equal = __commonJS({
    "node_modules/fast-deep-equal/index.js"(exports, module) {
      "use strict";
      module.exports = function equal(a3, b) {
        if (a3 === b)
          return true;
        if (a3 && b && typeof a3 == "object" && typeof b == "object") {
          if (a3.constructor !== b.constructor)
            return false;
          var length, i, keys;
          if (Array.isArray(a3)) {
            length = a3.length;
            if (length != b.length)
              return false;
            for (i = length; i-- !== 0; )
              if (!equal(a3[i], b[i]))
                return false;
            return true;
          }
          if (a3.constructor === RegExp)
            return a3.source === b.source && a3.flags === b.flags;
          if (a3.valueOf !== Object.prototype.valueOf)
            return a3.valueOf() === b.valueOf();
          if (a3.toString !== Object.prototype.toString)
            return a3.toString() === b.toString();
          keys = Object.keys(a3);
          length = keys.length;
          if (length !== Object.keys(b).length)
            return false;
          for (i = length; i-- !== 0; )
            if (!Object.prototype.hasOwnProperty.call(b, keys[i]))
              return false;
          for (i = length; i-- !== 0; ) {
            var key = keys[i];
            if (!equal(a3[key], b[key]))
              return false;
          }
          return true;
        }
        return a3 !== a3 && b !== b;
      };
    }
  });

  // node_modules/ajv/lib/compile/ucs2length.js
  var require_ucs2length = __commonJS({
    "node_modules/ajv/lib/compile/ucs2length.js"(exports, module) {
      "use strict";
      module.exports = function ucs2length(str) {
        var length = 0, len = str.length, pos = 0, value;
        while (pos < len) {
          length++;
          value = str.charCodeAt(pos++);
          if (value >= 55296 && value <= 56319 && pos < len) {
            value = str.charCodeAt(pos);
            if ((value & 64512) == 56320)
              pos++;
          }
        }
        return length;
      };
    }
  });

  // node_modules/ajv/lib/compile/util.js
  var require_util = __commonJS({
    "node_modules/ajv/lib/compile/util.js"(exports, module) {
      "use strict";
      module.exports = {
        copy,
        checkDataType,
        checkDataTypes,
        coerceToTypes,
        toHash,
        getProperty,
        escapeQuotes,
        equal: require_fast_deep_equal(),
        ucs2length: require_ucs2length(),
        varOccurences,
        varReplace,
        schemaHasRules,
        schemaHasRulesExcept,
        schemaUnknownRules,
        toQuotedString,
        getPathExpr,
        getPath,
        getData,
        unescapeFragment,
        unescapeJsonPointer,
        escapeFragment,
        escapeJsonPointer
      };
      function copy(o4, to) {
        to = to || {};
        for (var key in o4)
          to[key] = o4[key];
        return to;
      }
      function checkDataType(dataType, data, strictNumbers, negate) {
        var EQUAL = negate ? " !== " : " === ", AND = negate ? " || " : " && ", OK = negate ? "!" : "", NOT = negate ? "" : "!";
        switch (dataType) {
          case "null":
            return data + EQUAL + "null";
          case "array":
            return OK + "Array.isArray(" + data + ")";
          case "object":
            return "(" + OK + data + AND + "typeof " + data + EQUAL + '"object"' + AND + NOT + "Array.isArray(" + data + "))";
          case "integer":
            return "(typeof " + data + EQUAL + '"number"' + AND + NOT + "(" + data + " % 1)" + AND + data + EQUAL + data + (strictNumbers ? AND + OK + "isFinite(" + data + ")" : "") + ")";
          case "number":
            return "(typeof " + data + EQUAL + '"' + dataType + '"' + (strictNumbers ? AND + OK + "isFinite(" + data + ")" : "") + ")";
          default:
            return "typeof " + data + EQUAL + '"' + dataType + '"';
        }
      }
      function checkDataTypes(dataTypes, data, strictNumbers) {
        switch (dataTypes.length) {
          case 1:
            return checkDataType(dataTypes[0], data, strictNumbers, true);
          default:
            var code = "";
            var types = toHash(dataTypes);
            if (types.array && types.object) {
              code = types.null ? "(" : "(!" + data + " || ";
              code += "typeof " + data + ' !== "object")';
              delete types.null;
              delete types.array;
              delete types.object;
            }
            if (types.number)
              delete types.integer;
            for (var t in types)
              code += (code ? " && " : "") + checkDataType(t, data, strictNumbers, true);
            return code;
        }
      }
      var COERCE_TO_TYPES = toHash(["string", "number", "integer", "boolean", "null"]);
      function coerceToTypes(optionCoerceTypes, dataTypes) {
        if (Array.isArray(dataTypes)) {
          var types = [];
          for (var i = 0; i < dataTypes.length; i++) {
            var t = dataTypes[i];
            if (COERCE_TO_TYPES[t])
              types[types.length] = t;
            else if (optionCoerceTypes === "array" && t === "array")
              types[types.length] = t;
          }
          if (types.length)
            return types;
        } else if (COERCE_TO_TYPES[dataTypes]) {
          return [dataTypes];
        } else if (optionCoerceTypes === "array" && dataTypes === "array") {
          return ["array"];
        }
      }
      function toHash(arr) {
        var hash = {};
        for (var i = 0; i < arr.length; i++)
          hash[arr[i]] = true;
        return hash;
      }
      var IDENTIFIER = /^[a-z$_][a-z$_0-9]*$/i;
      var SINGLE_QUOTE = /'|\\/g;
      function getProperty(key) {
        return typeof key == "number" ? "[" + key + "]" : IDENTIFIER.test(key) ? "." + key : "['" + escapeQuotes(key) + "']";
      }
      function escapeQuotes(str) {
        return str.replace(SINGLE_QUOTE, "\\$&").replace(/\n/g, "\\n").replace(/\r/g, "\\r").replace(/\f/g, "\\f").replace(/\t/g, "\\t");
      }
      function varOccurences(str, dataVar) {
        dataVar += "[^0-9]";
        var matches = str.match(new RegExp(dataVar, "g"));
        return matches ? matches.length : 0;
      }
      function varReplace(str, dataVar, expr) {
        dataVar += "([^0-9])";
        expr = expr.replace(/\$/g, "$$$$");
        return str.replace(new RegExp(dataVar, "g"), expr + "$1");
      }
      function schemaHasRules(schema, rules) {
        if (typeof schema == "boolean")
          return !schema;
        for (var key in schema)
          if (rules[key])
            return true;
      }
      function schemaHasRulesExcept(schema, rules, exceptKeyword) {
        if (typeof schema == "boolean")
          return !schema && exceptKeyword != "not";
        for (var key in schema)
          if (key != exceptKeyword && rules[key])
            return true;
      }
      function schemaUnknownRules(schema, rules) {
        if (typeof schema == "boolean")
          return;
        for (var key in schema)
          if (!rules[key])
            return key;
      }
      function toQuotedString(str) {
        return "'" + escapeQuotes(str) + "'";
      }
      function getPathExpr(currentPath, expr, jsonPointers, isNumber) {
        var path = jsonPointers ? "'/' + " + expr + (isNumber ? "" : ".replace(/~/g, '~0').replace(/\\//g, '~1')") : isNumber ? "'[' + " + expr + " + ']'" : "'[\\'' + " + expr + " + '\\']'";
        return joinPaths(currentPath, path);
      }
      function getPath(currentPath, prop, jsonPointers) {
        var path = jsonPointers ? toQuotedString("/" + escapeJsonPointer(prop)) : toQuotedString(getProperty(prop));
        return joinPaths(currentPath, path);
      }
      var JSON_POINTER = /^\/(?:[^~]|~0|~1)*$/;
      var RELATIVE_JSON_POINTER = /^([0-9]+)(#|\/(?:[^~]|~0|~1)*)?$/;
      function getData($data, lvl, paths) {
        var up, jsonPointer, data, matches;
        if ($data === "")
          return "rootData";
        if ($data[0] == "/") {
          if (!JSON_POINTER.test($data))
            throw new Error("Invalid JSON-pointer: " + $data);
          jsonPointer = $data;
          data = "rootData";
        } else {
          matches = $data.match(RELATIVE_JSON_POINTER);
          if (!matches)
            throw new Error("Invalid JSON-pointer: " + $data);
          up = +matches[1];
          jsonPointer = matches[2];
          if (jsonPointer == "#") {
            if (up >= lvl)
              throw new Error("Cannot access property/index " + up + " levels up, current level is " + lvl);
            return paths[lvl - up];
          }
          if (up > lvl)
            throw new Error("Cannot access data " + up + " levels up, current level is " + lvl);
          data = "data" + (lvl - up || "");
          if (!jsonPointer)
            return data;
        }
        var expr = data;
        var segments = jsonPointer.split("/");
        for (var i = 0; i < segments.length; i++) {
          var segment = segments[i];
          if (segment) {
            data += getProperty(unescapeJsonPointer(segment));
            expr += " && " + data;
          }
        }
        return expr;
      }
      function joinPaths(a3, b) {
        if (a3 == '""')
          return b;
        return (a3 + " + " + b).replace(/([^\\])' \+ '/g, "$1");
      }
      function unescapeFragment(str) {
        return unescapeJsonPointer(decodeURIComponent(str));
      }
      function escapeFragment(str) {
        return encodeURIComponent(escapeJsonPointer(str));
      }
      function escapeJsonPointer(str) {
        return str.replace(/~/g, "~0").replace(/\//g, "~1");
      }
      function unescapeJsonPointer(str) {
        return str.replace(/~1/g, "/").replace(/~0/g, "~");
      }
    }
  });

  // node_modules/ajv/lib/compile/schema_obj.js
  var require_schema_obj = __commonJS({
    "node_modules/ajv/lib/compile/schema_obj.js"(exports, module) {
      "use strict";
      var util = require_util();
      module.exports = SchemaObject;
      function SchemaObject(obj) {
        util.copy(obj, this);
      }
    }
  });

  // node_modules/json-schema-traverse/index.js
  var require_json_schema_traverse = __commonJS({
    "node_modules/json-schema-traverse/index.js"(exports, module) {
      "use strict";
      var traverse = module.exports = function(schema, opts, cb) {
        if (typeof opts == "function") {
          cb = opts;
          opts = {};
        }
        cb = opts.cb || cb;
        var pre = typeof cb == "function" ? cb : cb.pre || function() {
        };
        var post = cb.post || function() {
        };
        _traverse(opts, pre, post, schema, "", schema);
      };
      traverse.keywords = {
        additionalItems: true,
        items: true,
        contains: true,
        additionalProperties: true,
        propertyNames: true,
        not: true
      };
      traverse.arrayKeywords = {
        items: true,
        allOf: true,
        anyOf: true,
        oneOf: true
      };
      traverse.propsKeywords = {
        definitions: true,
        properties: true,
        patternProperties: true,
        dependencies: true
      };
      traverse.skipKeywords = {
        default: true,
        enum: true,
        const: true,
        required: true,
        maximum: true,
        minimum: true,
        exclusiveMaximum: true,
        exclusiveMinimum: true,
        multipleOf: true,
        maxLength: true,
        minLength: true,
        pattern: true,
        format: true,
        maxItems: true,
        minItems: true,
        uniqueItems: true,
        maxProperties: true,
        minProperties: true
      };
      function _traverse(opts, pre, post, schema, jsonPtr, rootSchema, parentJsonPtr, parentKeyword, parentSchema, keyIndex) {
        if (schema && typeof schema == "object" && !Array.isArray(schema)) {
          pre(schema, jsonPtr, rootSchema, parentJsonPtr, parentKeyword, parentSchema, keyIndex);
          for (var key in schema) {
            var sch = schema[key];
            if (Array.isArray(sch)) {
              if (key in traverse.arrayKeywords) {
                for (var i = 0; i < sch.length; i++)
                  _traverse(opts, pre, post, sch[i], jsonPtr + "/" + key + "/" + i, rootSchema, jsonPtr, key, schema, i);
              }
            } else if (key in traverse.propsKeywords) {
              if (sch && typeof sch == "object") {
                for (var prop in sch)
                  _traverse(opts, pre, post, sch[prop], jsonPtr + "/" + key + "/" + escapeJsonPtr(prop), rootSchema, jsonPtr, key, schema, prop);
              }
            } else if (key in traverse.keywords || opts.allKeys && !(key in traverse.skipKeywords)) {
              _traverse(opts, pre, post, sch, jsonPtr + "/" + key, rootSchema, jsonPtr, key, schema);
            }
          }
          post(schema, jsonPtr, rootSchema, parentJsonPtr, parentKeyword, parentSchema, keyIndex);
        }
      }
      function escapeJsonPtr(str) {
        return str.replace(/~/g, "~0").replace(/\//g, "~1");
      }
    }
  });

  // node_modules/ajv/lib/compile/resolve.js
  var require_resolve = __commonJS({
    "node_modules/ajv/lib/compile/resolve.js"(exports, module) {
      "use strict";
      var URI = require_uri_all();
      var equal = require_fast_deep_equal();
      var util = require_util();
      var SchemaObject = require_schema_obj();
      var traverse = require_json_schema_traverse();
      module.exports = resolve;
      resolve.normalizeId = normalizeId;
      resolve.fullPath = getFullPath;
      resolve.url = resolveUrl;
      resolve.ids = resolveIds;
      resolve.inlineRef = inlineRef;
      resolve.schema = resolveSchema;
      function resolve(compile, root, ref) {
        var refVal = this._refs[ref];
        if (typeof refVal == "string") {
          if (this._refs[refVal])
            refVal = this._refs[refVal];
          else
            return resolve.call(this, compile, root, refVal);
        }
        refVal = refVal || this._schemas[ref];
        if (refVal instanceof SchemaObject) {
          return inlineRef(refVal.schema, this._opts.inlineRefs) ? refVal.schema : refVal.validate || this._compile(refVal);
        }
        var res = resolveSchema.call(this, root, ref);
        var schema, v, baseId;
        if (res) {
          schema = res.schema;
          root = res.root;
          baseId = res.baseId;
        }
        if (schema instanceof SchemaObject) {
          v = schema.validate || compile.call(this, schema.schema, root, void 0, baseId);
        } else if (schema !== void 0) {
          v = inlineRef(schema, this._opts.inlineRefs) ? schema : compile.call(this, schema, root, void 0, baseId);
        }
        return v;
      }
      function resolveSchema(root, ref) {
        var p = URI.parse(ref), refPath = _getFullPath(p), baseId = getFullPath(this._getId(root.schema));
        if (Object.keys(root.schema).length === 0 || refPath !== baseId) {
          var id = normalizeId(refPath);
          var refVal = this._refs[id];
          if (typeof refVal == "string") {
            return resolveRecursive.call(this, root, refVal, p);
          } else if (refVal instanceof SchemaObject) {
            if (!refVal.validate)
              this._compile(refVal);
            root = refVal;
          } else {
            refVal = this._schemas[id];
            if (refVal instanceof SchemaObject) {
              if (!refVal.validate)
                this._compile(refVal);
              if (id == normalizeId(ref))
                return { schema: refVal, root, baseId };
              root = refVal;
            } else {
              return;
            }
          }
          if (!root.schema)
            return;
          baseId = getFullPath(this._getId(root.schema));
        }
        return getJsonPointer.call(this, p, baseId, root.schema, root);
      }
      function resolveRecursive(root, ref, parsedRef) {
        var res = resolveSchema.call(this, root, ref);
        if (res) {
          var schema = res.schema;
          var baseId = res.baseId;
          root = res.root;
          var id = this._getId(schema);
          if (id)
            baseId = resolveUrl(baseId, id);
          return getJsonPointer.call(this, parsedRef, baseId, schema, root);
        }
      }
      var PREVENT_SCOPE_CHANGE = util.toHash(["properties", "patternProperties", "enum", "dependencies", "definitions"]);
      function getJsonPointer(parsedRef, baseId, schema, root) {
        parsedRef.fragment = parsedRef.fragment || "";
        if (parsedRef.fragment.slice(0, 1) != "/")
          return;
        var parts = parsedRef.fragment.split("/");
        for (var i = 1; i < parts.length; i++) {
          var part = parts[i];
          if (part) {
            part = util.unescapeFragment(part);
            schema = schema[part];
            if (schema === void 0)
              break;
            var id;
            if (!PREVENT_SCOPE_CHANGE[part]) {
              id = this._getId(schema);
              if (id)
                baseId = resolveUrl(baseId, id);
              if (schema.$ref) {
                var $ref = resolveUrl(baseId, schema.$ref);
                var res = resolveSchema.call(this, root, $ref);
                if (res) {
                  schema = res.schema;
                  root = res.root;
                  baseId = res.baseId;
                }
              }
            }
          }
        }
        if (schema !== void 0 && schema !== root.schema)
          return { schema, root, baseId };
      }
      var SIMPLE_INLINED = util.toHash([
        "type",
        "format",
        "pattern",
        "maxLength",
        "minLength",
        "maxProperties",
        "minProperties",
        "maxItems",
        "minItems",
        "maximum",
        "minimum",
        "uniqueItems",
        "multipleOf",
        "required",
        "enum"
      ]);
      function inlineRef(schema, limit) {
        if (limit === false)
          return false;
        if (limit === void 0 || limit === true)
          return checkNoRef(schema);
        else if (limit)
          return countKeys(schema) <= limit;
      }
      function checkNoRef(schema) {
        var item;
        if (Array.isArray(schema)) {
          for (var i = 0; i < schema.length; i++) {
            item = schema[i];
            if (typeof item == "object" && !checkNoRef(item))
              return false;
          }
        } else {
          for (var key in schema) {
            if (key == "$ref")
              return false;
            item = schema[key];
            if (typeof item == "object" && !checkNoRef(item))
              return false;
          }
        }
        return true;
      }
      function countKeys(schema) {
        var count = 0, item;
        if (Array.isArray(schema)) {
          for (var i = 0; i < schema.length; i++) {
            item = schema[i];
            if (typeof item == "object")
              count += countKeys(item);
            if (count == Infinity)
              return Infinity;
          }
        } else {
          for (var key in schema) {
            if (key == "$ref")
              return Infinity;
            if (SIMPLE_INLINED[key]) {
              count++;
            } else {
              item = schema[key];
              if (typeof item == "object")
                count += countKeys(item) + 1;
              if (count == Infinity)
                return Infinity;
            }
          }
        }
        return count;
      }
      function getFullPath(id, normalize) {
        if (normalize !== false)
          id = normalizeId(id);
        var p = URI.parse(id);
        return _getFullPath(p);
      }
      function _getFullPath(p) {
        return URI.serialize(p).split("#")[0] + "#";
      }
      var TRAILING_SLASH_HASH = /#\/?$/;
      function normalizeId(id) {
        return id ? id.replace(TRAILING_SLASH_HASH, "") : "";
      }
      function resolveUrl(baseId, id) {
        id = normalizeId(id);
        return URI.resolve(baseId, id);
      }
      function resolveIds(schema) {
        var schemaId = normalizeId(this._getId(schema));
        var baseIds = { "": schemaId };
        var fullPaths = { "": getFullPath(schemaId, false) };
        var localRefs = {};
        var self2 = this;
        traverse(schema, { allKeys: true }, function(sch, jsonPtr, rootSchema, parentJsonPtr, parentKeyword, parentSchema, keyIndex) {
          if (jsonPtr === "")
            return;
          var id = self2._getId(sch);
          var baseId = baseIds[parentJsonPtr];
          var fullPath = fullPaths[parentJsonPtr] + "/" + parentKeyword;
          if (keyIndex !== void 0)
            fullPath += "/" + (typeof keyIndex == "number" ? keyIndex : util.escapeFragment(keyIndex));
          if (typeof id == "string") {
            id = baseId = normalizeId(baseId ? URI.resolve(baseId, id) : id);
            var refVal = self2._refs[id];
            if (typeof refVal == "string")
              refVal = self2._refs[refVal];
            if (refVal && refVal.schema) {
              if (!equal(sch, refVal.schema))
                throw new Error('id "' + id + '" resolves to more than one schema');
            } else if (id != normalizeId(fullPath)) {
              if (id[0] == "#") {
                if (localRefs[id] && !equal(sch, localRefs[id]))
                  throw new Error('id "' + id + '" resolves to more than one schema');
                localRefs[id] = sch;
              } else {
                self2._refs[id] = fullPath;
              }
            }
          }
          baseIds[jsonPtr] = baseId;
          fullPaths[jsonPtr] = fullPath;
        });
        return localRefs;
      }
    }
  });

  // node_modules/ajv/lib/compile/error_classes.js
  var require_error_classes = __commonJS({
    "node_modules/ajv/lib/compile/error_classes.js"(exports, module) {
      "use strict";
      var resolve = require_resolve();
      module.exports = {
        Validation: errorSubclass(ValidationError),
        MissingRef: errorSubclass(MissingRefError)
      };
      function ValidationError(errors) {
        this.message = "validation failed";
        this.errors = errors;
        this.ajv = this.validation = true;
      }
      MissingRefError.message = function(baseId, ref) {
        return "can't resolve reference " + ref + " from id " + baseId;
      };
      function MissingRefError(baseId, ref, message) {
        this.message = message || MissingRefError.message(baseId, ref);
        this.missingRef = resolve.url(baseId, ref);
        this.missingSchema = resolve.normalizeId(resolve.fullPath(this.missingRef));
      }
      function errorSubclass(Subclass) {
        Subclass.prototype = Object.create(Error.prototype);
        Subclass.prototype.constructor = Subclass;
        return Subclass;
      }
    }
  });

  // node_modules/fast-json-stable-stringify/index.js
  var require_fast_json_stable_stringify = __commonJS({
    "node_modules/fast-json-stable-stringify/index.js"(exports, module) {
      "use strict";
      module.exports = function(data, opts) {
        if (!opts)
          opts = {};
        if (typeof opts === "function")
          opts = { cmp: opts };
        var cycles = typeof opts.cycles === "boolean" ? opts.cycles : false;
        var cmp = opts.cmp && function(f) {
          return function(node) {
            return function(a3, b) {
              var aobj = { key: a3, value: node[a3] };
              var bobj = { key: b, value: node[b] };
              return f(aobj, bobj);
            };
          };
        }(opts.cmp);
        var seen = [];
        return function stringify(node) {
          if (node && node.toJSON && typeof node.toJSON === "function") {
            node = node.toJSON();
          }
          if (node === void 0)
            return;
          if (typeof node == "number")
            return isFinite(node) ? "" + node : "null";
          if (typeof node !== "object")
            return JSON.stringify(node);
          var i, out;
          if (Array.isArray(node)) {
            out = "[";
            for (i = 0; i < node.length; i++) {
              if (i)
                out += ",";
              out += stringify(node[i]) || "null";
            }
            return out + "]";
          }
          if (node === null)
            return "null";
          if (seen.indexOf(node) !== -1) {
            if (cycles)
              return JSON.stringify("__cycle__");
            throw new TypeError("Converting circular structure to JSON");
          }
          var seenIndex = seen.push(node) - 1;
          var keys = Object.keys(node).sort(cmp && cmp(node));
          out = "";
          for (i = 0; i < keys.length; i++) {
            var key = keys[i];
            var value = stringify(node[key]);
            if (!value)
              continue;
            if (out)
              out += ",";
            out += JSON.stringify(key) + ":" + value;
          }
          seen.splice(seenIndex, 1);
          return "{" + out + "}";
        }(data);
      };
    }
  });

  // node_modules/ajv/lib/dotjs/validate.js
  var require_validate = __commonJS({
    "node_modules/ajv/lib/dotjs/validate.js"(exports, module) {
      "use strict";
      module.exports = function generate_validate(it, $keyword, $ruleType) {
        var out = "";
        var $async = it.schema.$async === true, $refKeywords = it.util.schemaHasRulesExcept(it.schema, it.RULES.all, "$ref"), $id4 = it.self._getId(it.schema);
        if (it.opts.strictKeywords) {
          var $unknownKwd = it.util.schemaUnknownRules(it.schema, it.RULES.keywords);
          if ($unknownKwd) {
            var $keywordsMsg = "unknown keyword: " + $unknownKwd;
            if (it.opts.strictKeywords === "log")
              it.logger.warn($keywordsMsg);
            else
              throw new Error($keywordsMsg);
          }
        }
        if (it.isTop) {
          out += " var validate = ";
          if ($async) {
            it.async = true;
            out += "async ";
          }
          out += "function(data, dataPath, parentData, parentDataProperty, rootData) { 'use strict'; ";
          if ($id4 && (it.opts.sourceCode || it.opts.processCode)) {
            out += " " + ("/*# sourceURL=" + $id4 + " */") + " ";
          }
        }
        if (typeof it.schema == "boolean" || !($refKeywords || it.schema.$ref)) {
          var $keyword = "false schema";
          var $lvl = it.level;
          var $dataLvl = it.dataLevel;
          var $schema = it.schema[$keyword];
          var $schemaPath = it.schemaPath + it.util.getProperty($keyword);
          var $errSchemaPath = it.errSchemaPath + "/" + $keyword;
          var $breakOnError = !it.opts.allErrors;
          var $errorKeyword;
          var $data = "data" + ($dataLvl || "");
          var $valid = "valid" + $lvl;
          if (it.schema === false) {
            if (it.isTop) {
              $breakOnError = true;
            } else {
              out += " var " + $valid + " = false; ";
            }
            var $$outStack = $$outStack || [];
            $$outStack.push(out);
            out = "";
            if (it.createErrors !== false) {
              out += " { keyword: '" + ($errorKeyword || "false schema") + "' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: {} ";
              if (it.opts.messages !== false) {
                out += " , message: 'boolean schema is false' ";
              }
              if (it.opts.verbose) {
                out += " , schema: false , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
              }
              out += " } ";
            } else {
              out += " {} ";
            }
            var __err = out;
            out = $$outStack.pop();
            if (!it.compositeRule && $breakOnError) {
              if (it.async) {
                out += " throw new ValidationError([" + __err + "]); ";
              } else {
                out += " validate.errors = [" + __err + "]; return false; ";
              }
            } else {
              out += " var err = " + __err + ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
            }
          } else {
            if (it.isTop) {
              if ($async) {
                out += " return data; ";
              } else {
                out += " validate.errors = null; return true; ";
              }
            } else {
              out += " var " + $valid + " = true; ";
            }
          }
          if (it.isTop) {
            out += " }; return validate; ";
          }
          return out;
        }
        if (it.isTop) {
          var $top = it.isTop, $lvl = it.level = 0, $dataLvl = it.dataLevel = 0, $data = "data";
          it.rootId = it.resolve.fullPath(it.self._getId(it.root.schema));
          it.baseId = it.baseId || it.rootId;
          delete it.isTop;
          it.dataPathArr = [""];
          if (it.schema.default !== void 0 && it.opts.useDefaults && it.opts.strictDefaults) {
            var $defaultMsg = "default is ignored in the schema root";
            if (it.opts.strictDefaults === "log")
              it.logger.warn($defaultMsg);
            else
              throw new Error($defaultMsg);
          }
          out += " var vErrors = null; ";
          out += " var errors = 0;     ";
          out += " if (rootData === undefined) rootData = data; ";
        } else {
          var $lvl = it.level, $dataLvl = it.dataLevel, $data = "data" + ($dataLvl || "");
          if ($id4)
            it.baseId = it.resolve.url(it.baseId, $id4);
          if ($async && !it.async)
            throw new Error("async schema in sync schema");
          out += " var errs_" + $lvl + " = errors;";
        }
        var $valid = "valid" + $lvl, $breakOnError = !it.opts.allErrors, $closingBraces1 = "", $closingBraces2 = "";
        var $errorKeyword;
        var $typeSchema = it.schema.type, $typeIsArray = Array.isArray($typeSchema);
        if ($typeSchema && it.opts.nullable && it.schema.nullable === true) {
          if ($typeIsArray) {
            if ($typeSchema.indexOf("null") == -1)
              $typeSchema = $typeSchema.concat("null");
          } else if ($typeSchema != "null") {
            $typeSchema = [$typeSchema, "null"];
            $typeIsArray = true;
          }
        }
        if ($typeIsArray && $typeSchema.length == 1) {
          $typeSchema = $typeSchema[0];
          $typeIsArray = false;
        }
        if (it.schema.$ref && $refKeywords) {
          if (it.opts.extendRefs == "fail") {
            throw new Error('$ref: validation keywords used in schema at path "' + it.errSchemaPath + '" (see option extendRefs)');
          } else if (it.opts.extendRefs !== true) {
            $refKeywords = false;
            it.logger.warn('$ref: keywords ignored in schema at path "' + it.errSchemaPath + '"');
          }
        }
        if (it.schema.$comment && it.opts.$comment) {
          out += " " + it.RULES.all.$comment.code(it, "$comment");
        }
        if ($typeSchema) {
          if (it.opts.coerceTypes) {
            var $coerceToTypes = it.util.coerceToTypes(it.opts.coerceTypes, $typeSchema);
          }
          var $rulesGroup = it.RULES.types[$typeSchema];
          if ($coerceToTypes || $typeIsArray || $rulesGroup === true || $rulesGroup && !$shouldUseGroup($rulesGroup)) {
            var $schemaPath = it.schemaPath + ".type", $errSchemaPath = it.errSchemaPath + "/type";
            var $schemaPath = it.schemaPath + ".type", $errSchemaPath = it.errSchemaPath + "/type", $method = $typeIsArray ? "checkDataTypes" : "checkDataType";
            out += " if (" + it.util[$method]($typeSchema, $data, it.opts.strictNumbers, true) + ") { ";
            if ($coerceToTypes) {
              var $dataType = "dataType" + $lvl, $coerced = "coerced" + $lvl;
              out += " var " + $dataType + " = typeof " + $data + "; var " + $coerced + " = undefined; ";
              if (it.opts.coerceTypes == "array") {
                out += " if (" + $dataType + " == 'object' && Array.isArray(" + $data + ") && " + $data + ".length == 1) { " + $data + " = " + $data + "[0]; " + $dataType + " = typeof " + $data + "; if (" + it.util.checkDataType(it.schema.type, $data, it.opts.strictNumbers) + ") " + $coerced + " = " + $data + "; } ";
              }
              out += " if (" + $coerced + " !== undefined) ; ";
              var arr1 = $coerceToTypes;
              if (arr1) {
                var $type, $i = -1, l1 = arr1.length - 1;
                while ($i < l1) {
                  $type = arr1[$i += 1];
                  if ($type == "string") {
                    out += " else if (" + $dataType + " == 'number' || " + $dataType + " == 'boolean') " + $coerced + " = '' + " + $data + "; else if (" + $data + " === null) " + $coerced + " = ''; ";
                  } else if ($type == "number" || $type == "integer") {
                    out += " else if (" + $dataType + " == 'boolean' || " + $data + " === null || (" + $dataType + " == 'string' && " + $data + " && " + $data + " == +" + $data + " ";
                    if ($type == "integer") {
                      out += " && !(" + $data + " % 1)";
                    }
                    out += ")) " + $coerced + " = +" + $data + "; ";
                  } else if ($type == "boolean") {
                    out += " else if (" + $data + " === 'false' || " + $data + " === 0 || " + $data + " === null) " + $coerced + " = false; else if (" + $data + " === 'true' || " + $data + " === 1) " + $coerced + " = true; ";
                  } else if ($type == "null") {
                    out += " else if (" + $data + " === '' || " + $data + " === 0 || " + $data + " === false) " + $coerced + " = null; ";
                  } else if (it.opts.coerceTypes == "array" && $type == "array") {
                    out += " else if (" + $dataType + " == 'string' || " + $dataType + " == 'number' || " + $dataType + " == 'boolean' || " + $data + " == null) " + $coerced + " = [" + $data + "]; ";
                  }
                }
              }
              out += " else {   ";
              var $$outStack = $$outStack || [];
              $$outStack.push(out);
              out = "";
              if (it.createErrors !== false) {
                out += " { keyword: '" + ($errorKeyword || "type") + "' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { type: '";
                if ($typeIsArray) {
                  out += "" + $typeSchema.join(",");
                } else {
                  out += "" + $typeSchema;
                }
                out += "' } ";
                if (it.opts.messages !== false) {
                  out += " , message: 'should be ";
                  if ($typeIsArray) {
                    out += "" + $typeSchema.join(",");
                  } else {
                    out += "" + $typeSchema;
                  }
                  out += "' ";
                }
                if (it.opts.verbose) {
                  out += " , schema: validate.schema" + $schemaPath + " , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
                }
                out += " } ";
              } else {
                out += " {} ";
              }
              var __err = out;
              out = $$outStack.pop();
              if (!it.compositeRule && $breakOnError) {
                if (it.async) {
                  out += " throw new ValidationError([" + __err + "]); ";
                } else {
                  out += " validate.errors = [" + __err + "]; return false; ";
                }
              } else {
                out += " var err = " + __err + ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
              }
              out += " } if (" + $coerced + " !== undefined) {  ";
              var $parentData = $dataLvl ? "data" + ($dataLvl - 1 || "") : "parentData", $parentDataProperty = $dataLvl ? it.dataPathArr[$dataLvl] : "parentDataProperty";
              out += " " + $data + " = " + $coerced + "; ";
              if (!$dataLvl) {
                out += "if (" + $parentData + " !== undefined)";
              }
              out += " " + $parentData + "[" + $parentDataProperty + "] = " + $coerced + "; } ";
            } else {
              var $$outStack = $$outStack || [];
              $$outStack.push(out);
              out = "";
              if (it.createErrors !== false) {
                out += " { keyword: '" + ($errorKeyword || "type") + "' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { type: '";
                if ($typeIsArray) {
                  out += "" + $typeSchema.join(",");
                } else {
                  out += "" + $typeSchema;
                }
                out += "' } ";
                if (it.opts.messages !== false) {
                  out += " , message: 'should be ";
                  if ($typeIsArray) {
                    out += "" + $typeSchema.join(",");
                  } else {
                    out += "" + $typeSchema;
                  }
                  out += "' ";
                }
                if (it.opts.verbose) {
                  out += " , schema: validate.schema" + $schemaPath + " , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
                }
                out += " } ";
              } else {
                out += " {} ";
              }
              var __err = out;
              out = $$outStack.pop();
              if (!it.compositeRule && $breakOnError) {
                if (it.async) {
                  out += " throw new ValidationError([" + __err + "]); ";
                } else {
                  out += " validate.errors = [" + __err + "]; return false; ";
                }
              } else {
                out += " var err = " + __err + ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
              }
            }
            out += " } ";
          }
        }
        if (it.schema.$ref && !$refKeywords) {
          out += " " + it.RULES.all.$ref.code(it, "$ref") + " ";
          if ($breakOnError) {
            out += " } if (errors === ";
            if ($top) {
              out += "0";
            } else {
              out += "errs_" + $lvl;
            }
            out += ") { ";
            $closingBraces2 += "}";
          }
        } else {
          var arr2 = it.RULES;
          if (arr2) {
            var $rulesGroup, i2 = -1, l2 = arr2.length - 1;
            while (i2 < l2) {
              $rulesGroup = arr2[i2 += 1];
              if ($shouldUseGroup($rulesGroup)) {
                if ($rulesGroup.type) {
                  out += " if (" + it.util.checkDataType($rulesGroup.type, $data, it.opts.strictNumbers) + ") { ";
                }
                if (it.opts.useDefaults) {
                  if ($rulesGroup.type == "object" && it.schema.properties) {
                    var $schema = it.schema.properties, $schemaKeys = Object.keys($schema);
                    var arr3 = $schemaKeys;
                    if (arr3) {
                      var $propertyKey, i3 = -1, l3 = arr3.length - 1;
                      while (i3 < l3) {
                        $propertyKey = arr3[i3 += 1];
                        var $sch = $schema[$propertyKey];
                        if ($sch.default !== void 0) {
                          var $passData = $data + it.util.getProperty($propertyKey);
                          if (it.compositeRule) {
                            if (it.opts.strictDefaults) {
                              var $defaultMsg = "default is ignored for: " + $passData;
                              if (it.opts.strictDefaults === "log")
                                it.logger.warn($defaultMsg);
                              else
                                throw new Error($defaultMsg);
                            }
                          } else {
                            out += " if (" + $passData + " === undefined ";
                            if (it.opts.useDefaults == "empty") {
                              out += " || " + $passData + " === null || " + $passData + " === '' ";
                            }
                            out += " ) " + $passData + " = ";
                            if (it.opts.useDefaults == "shared") {
                              out += " " + it.useDefault($sch.default) + " ";
                            } else {
                              out += " " + JSON.stringify($sch.default) + " ";
                            }
                            out += "; ";
                          }
                        }
                      }
                    }
                  } else if ($rulesGroup.type == "array" && Array.isArray(it.schema.items)) {
                    var arr4 = it.schema.items;
                    if (arr4) {
                      var $sch, $i = -1, l4 = arr4.length - 1;
                      while ($i < l4) {
                        $sch = arr4[$i += 1];
                        if ($sch.default !== void 0) {
                          var $passData = $data + "[" + $i + "]";
                          if (it.compositeRule) {
                            if (it.opts.strictDefaults) {
                              var $defaultMsg = "default is ignored for: " + $passData;
                              if (it.opts.strictDefaults === "log")
                                it.logger.warn($defaultMsg);
                              else
                                throw new Error($defaultMsg);
                            }
                          } else {
                            out += " if (" + $passData + " === undefined ";
                            if (it.opts.useDefaults == "empty") {
                              out += " || " + $passData + " === null || " + $passData + " === '' ";
                            }
                            out += " ) " + $passData + " = ";
                            if (it.opts.useDefaults == "shared") {
                              out += " " + it.useDefault($sch.default) + " ";
                            } else {
                              out += " " + JSON.stringify($sch.default) + " ";
                            }
                            out += "; ";
                          }
                        }
                      }
                    }
                  }
                }
                var arr5 = $rulesGroup.rules;
                if (arr5) {
                  var $rule, i5 = -1, l5 = arr5.length - 1;
                  while (i5 < l5) {
                    $rule = arr5[i5 += 1];
                    if ($shouldUseRule($rule)) {
                      var $code = $rule.code(it, $rule.keyword, $rulesGroup.type);
                      if ($code) {
                        out += " " + $code + " ";
                        if ($breakOnError) {
                          $closingBraces1 += "}";
                        }
                      }
                    }
                  }
                }
                if ($breakOnError) {
                  out += " " + $closingBraces1 + " ";
                  $closingBraces1 = "";
                }
                if ($rulesGroup.type) {
                  out += " } ";
                  if ($typeSchema && $typeSchema === $rulesGroup.type && !$coerceToTypes) {
                    out += " else { ";
                    var $schemaPath = it.schemaPath + ".type", $errSchemaPath = it.errSchemaPath + "/type";
                    var $$outStack = $$outStack || [];
                    $$outStack.push(out);
                    out = "";
                    if (it.createErrors !== false) {
                      out += " { keyword: '" + ($errorKeyword || "type") + "' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { type: '";
                      if ($typeIsArray) {
                        out += "" + $typeSchema.join(",");
                      } else {
                        out += "" + $typeSchema;
                      }
                      out += "' } ";
                      if (it.opts.messages !== false) {
                        out += " , message: 'should be ";
                        if ($typeIsArray) {
                          out += "" + $typeSchema.join(",");
                        } else {
                          out += "" + $typeSchema;
                        }
                        out += "' ";
                      }
                      if (it.opts.verbose) {
                        out += " , schema: validate.schema" + $schemaPath + " , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
                      }
                      out += " } ";
                    } else {
                      out += " {} ";
                    }
                    var __err = out;
                    out = $$outStack.pop();
                    if (!it.compositeRule && $breakOnError) {
                      if (it.async) {
                        out += " throw new ValidationError([" + __err + "]); ";
                      } else {
                        out += " validate.errors = [" + __err + "]; return false; ";
                      }
                    } else {
                      out += " var err = " + __err + ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
                    }
                    out += " } ";
                  }
                }
                if ($breakOnError) {
                  out += " if (errors === ";
                  if ($top) {
                    out += "0";
                  } else {
                    out += "errs_" + $lvl;
                  }
                  out += ") { ";
                  $closingBraces2 += "}";
                }
              }
            }
          }
        }
        if ($breakOnError) {
          out += " " + $closingBraces2 + " ";
        }
        if ($top) {
          if ($async) {
            out += " if (errors === 0) return data;           ";
            out += " else throw new ValidationError(vErrors); ";
          } else {
            out += " validate.errors = vErrors; ";
            out += " return errors === 0;       ";
          }
          out += " }; return validate;";
        } else {
          out += " var " + $valid + " = errors === errs_" + $lvl + ";";
        }
        function $shouldUseGroup($rulesGroup2) {
          var rules = $rulesGroup2.rules;
          for (var i = 0; i < rules.length; i++)
            if ($shouldUseRule(rules[i]))
              return true;
        }
        function $shouldUseRule($rule2) {
          return it.schema[$rule2.keyword] !== void 0 || $rule2.implements && $ruleImplementsSomeKeyword($rule2);
        }
        function $ruleImplementsSomeKeyword($rule2) {
          var impl = $rule2.implements;
          for (var i = 0; i < impl.length; i++)
            if (it.schema[impl[i]] !== void 0)
              return true;
        }
        return out;
      };
    }
  });

  // node_modules/ajv/lib/compile/index.js
  var require_compile = __commonJS({
    "node_modules/ajv/lib/compile/index.js"(exports, module) {
      "use strict";
      var resolve = require_resolve();
      var util = require_util();
      var errorClasses = require_error_classes();
      var stableStringify = require_fast_json_stable_stringify();
      var validateGenerator = require_validate();
      var ucs2length = util.ucs2length;
      var equal = require_fast_deep_equal();
      var ValidationError = errorClasses.Validation;
      module.exports = compile;
      function compile(schema, root, localRefs, baseId) {
        var self2 = this, opts = this._opts, refVal = [void 0], refs = {}, patterns = [], patternsHash = {}, defaults = [], defaultsHash = {}, customRules = [];
        root = root || { schema, refVal, refs };
        var c = checkCompiling.call(this, schema, root, baseId);
        var compilation = this._compilations[c.index];
        if (c.compiling)
          return compilation.callValidate = callValidate;
        var formats = this._formats;
        var RULES = this.RULES;
        try {
          var v = localCompile(schema, root, localRefs, baseId);
          compilation.validate = v;
          var cv = compilation.callValidate;
          if (cv) {
            cv.schema = v.schema;
            cv.errors = null;
            cv.refs = v.refs;
            cv.refVal = v.refVal;
            cv.root = v.root;
            cv.$async = v.$async;
            if (opts.sourceCode)
              cv.source = v.source;
          }
          return v;
        } finally {
          endCompiling.call(this, schema, root, baseId);
        }
        function callValidate() {
          var validate = compilation.validate;
          var result = validate.apply(this, arguments);
          callValidate.errors = validate.errors;
          return result;
        }
        function localCompile(_schema, _root, localRefs2, baseId2) {
          var isRoot = !_root || _root && _root.schema == _schema;
          if (_root.schema != root.schema)
            return compile.call(self2, _schema, _root, localRefs2, baseId2);
          var $async = _schema.$async === true;
          var sourceCode = validateGenerator({
            isTop: true,
            schema: _schema,
            isRoot,
            baseId: baseId2,
            root: _root,
            schemaPath: "",
            errSchemaPath: "#",
            errorPath: '""',
            MissingRefError: errorClasses.MissingRef,
            RULES,
            validate: validateGenerator,
            util,
            resolve,
            resolveRef,
            usePattern,
            useDefault,
            useCustomRule,
            opts,
            formats,
            logger: self2.logger,
            self: self2
          });
          sourceCode = vars(refVal, refValCode) + vars(patterns, patternCode) + vars(defaults, defaultCode) + vars(customRules, customRuleCode) + sourceCode;
          if (opts.processCode)
            sourceCode = opts.processCode(sourceCode, _schema);
          var validate;
          try {
            var makeValidate = new Function("self", "RULES", "formats", "root", "refVal", "defaults", "customRules", "equal", "ucs2length", "ValidationError", sourceCode);
            validate = makeValidate(self2, RULES, formats, root, refVal, defaults, customRules, equal, ucs2length, ValidationError);
            refVal[0] = validate;
          } catch (e) {
            self2.logger.error("Error compiling schema, function code:", sourceCode);
            throw e;
          }
          validate.schema = _schema;
          validate.errors = null;
          validate.refs = refs;
          validate.refVal = refVal;
          validate.root = isRoot ? validate : _root;
          if ($async)
            validate.$async = true;
          if (opts.sourceCode === true) {
            validate.source = {
              code: sourceCode,
              patterns,
              defaults
            };
          }
          return validate;
        }
        function resolveRef(baseId2, ref, isRoot) {
          ref = resolve.url(baseId2, ref);
          var refIndex = refs[ref];
          var _refVal, refCode;
          if (refIndex !== void 0) {
            _refVal = refVal[refIndex];
            refCode = "refVal[" + refIndex + "]";
            return resolvedRef(_refVal, refCode);
          }
          if (!isRoot && root.refs) {
            var rootRefId = root.refs[ref];
            if (rootRefId !== void 0) {
              _refVal = root.refVal[rootRefId];
              refCode = addLocalRef(ref, _refVal);
              return resolvedRef(_refVal, refCode);
            }
          }
          refCode = addLocalRef(ref);
          var v2 = resolve.call(self2, localCompile, root, ref);
          if (v2 === void 0) {
            var localSchema = localRefs && localRefs[ref];
            if (localSchema) {
              v2 = resolve.inlineRef(localSchema, opts.inlineRefs) ? localSchema : compile.call(self2, localSchema, root, localRefs, baseId2);
            }
          }
          if (v2 === void 0) {
            removeLocalRef(ref);
          } else {
            replaceLocalRef(ref, v2);
            return resolvedRef(v2, refCode);
          }
        }
        function addLocalRef(ref, v2) {
          var refId = refVal.length;
          refVal[refId] = v2;
          refs[ref] = refId;
          return "refVal" + refId;
        }
        function removeLocalRef(ref) {
          delete refs[ref];
        }
        function replaceLocalRef(ref, v2) {
          var refId = refs[ref];
          refVal[refId] = v2;
        }
        function resolvedRef(refVal2, code) {
          return typeof refVal2 == "object" || typeof refVal2 == "boolean" ? { code, schema: refVal2, inline: true } : { code, $async: refVal2 && !!refVal2.$async };
        }
        function usePattern(regexStr) {
          var index = patternsHash[regexStr];
          if (index === void 0) {
            index = patternsHash[regexStr] = patterns.length;
            patterns[index] = regexStr;
          }
          return "pattern" + index;
        }
        function useDefault(value) {
          switch (typeof value) {
            case "boolean":
            case "number":
              return "" + value;
            case "string":
              return util.toQuotedString(value);
            case "object":
              if (value === null)
                return "null";
              var valueStr = stableStringify(value);
              var index = defaultsHash[valueStr];
              if (index === void 0) {
                index = defaultsHash[valueStr] = defaults.length;
                defaults[index] = value;
              }
              return "default" + index;
          }
        }
        function useCustomRule(rule, schema2, parentSchema, it) {
          if (self2._opts.validateSchema !== false) {
            var deps = rule.definition.dependencies;
            if (deps && !deps.every(function(keyword) {
              return Object.prototype.hasOwnProperty.call(parentSchema, keyword);
            }))
              throw new Error("parent schema must have all required keywords: " + deps.join(","));
            var validateSchema = rule.definition.validateSchema;
            if (validateSchema) {
              var valid = validateSchema(schema2);
              if (!valid) {
                var message = "keyword schema is invalid: " + self2.errorsText(validateSchema.errors);
                if (self2._opts.validateSchema == "log")
                  self2.logger.error(message);
                else
                  throw new Error(message);
              }
            }
          }
          var compile2 = rule.definition.compile, inline = rule.definition.inline, macro = rule.definition.macro;
          var validate;
          if (compile2) {
            validate = compile2.call(self2, schema2, parentSchema, it);
          } else if (macro) {
            validate = macro.call(self2, schema2, parentSchema, it);
            if (opts.validateSchema !== false)
              self2.validateSchema(validate, true);
          } else if (inline) {
            validate = inline.call(self2, it, rule.keyword, schema2, parentSchema);
          } else {
            validate = rule.definition.validate;
            if (!validate)
              return;
          }
          if (validate === void 0)
            throw new Error('custom keyword "' + rule.keyword + '"failed to compile');
          var index = customRules.length;
          customRules[index] = validate;
          return {
            code: "customRule" + index,
            validate
          };
        }
      }
      function checkCompiling(schema, root, baseId) {
        var index = compIndex.call(this, schema, root, baseId);
        if (index >= 0)
          return { index, compiling: true };
        index = this._compilations.length;
        this._compilations[index] = {
          schema,
          root,
          baseId
        };
        return { index, compiling: false };
      }
      function endCompiling(schema, root, baseId) {
        var i = compIndex.call(this, schema, root, baseId);
        if (i >= 0)
          this._compilations.splice(i, 1);
      }
      function compIndex(schema, root, baseId) {
        for (var i = 0; i < this._compilations.length; i++) {
          var c = this._compilations[i];
          if (c.schema == schema && c.root == root && c.baseId == baseId)
            return i;
        }
        return -1;
      }
      function patternCode(i, patterns) {
        return "var pattern" + i + " = new RegExp(" + util.toQuotedString(patterns[i]) + ");";
      }
      function defaultCode(i) {
        return "var default" + i + " = defaults[" + i + "];";
      }
      function refValCode(i, refVal) {
        return refVal[i] === void 0 ? "" : "var refVal" + i + " = refVal[" + i + "];";
      }
      function customRuleCode(i) {
        return "var customRule" + i + " = customRules[" + i + "];";
      }
      function vars(arr, statement) {
        if (!arr.length)
          return "";
        var code = "";
        for (var i = 0; i < arr.length; i++)
          code += statement(i, arr);
        return code;
      }
    }
  });

  // node_modules/ajv/lib/cache.js
  var require_cache = __commonJS({
    "node_modules/ajv/lib/cache.js"(exports, module) {
      "use strict";
      var Cache = module.exports = function Cache2() {
        this._cache = {};
      };
      Cache.prototype.put = function Cache_put(key, value) {
        this._cache[key] = value;
      };
      Cache.prototype.get = function Cache_get(key) {
        return this._cache[key];
      };
      Cache.prototype.del = function Cache_del(key) {
        delete this._cache[key];
      };
      Cache.prototype.clear = function Cache_clear() {
        this._cache = {};
      };
    }
  });

  // node_modules/ajv/lib/compile/formats.js
  var require_formats = __commonJS({
    "node_modules/ajv/lib/compile/formats.js"(exports, module) {
      "use strict";
      var util = require_util();
      var DATE = /^(\d\d\d\d)-(\d\d)-(\d\d)$/;
      var DAYS = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
      var TIME = /^(\d\d):(\d\d):(\d\d)(\.\d+)?(z|[+-]\d\d(?::?\d\d)?)?$/i;
      var HOSTNAME = /^(?=.{1,253}\.?$)[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\.[a-z0-9](?:[-0-9a-z]{0,61}[0-9a-z])?)*\.?$/i;
      var URI = /^(?:[a-z][a-z0-9+\-.]*:)(?:\/?\/(?:(?:[a-z0-9\-._~!$&'()*+,;=:]|%[0-9a-f]{2})*@)?(?:\[(?:(?:(?:(?:[0-9a-f]{1,4}:){6}|::(?:[0-9a-f]{1,4}:){5}|(?:[0-9a-f]{1,4})?::(?:[0-9a-f]{1,4}:){4}|(?:(?:[0-9a-f]{1,4}:){0,1}[0-9a-f]{1,4})?::(?:[0-9a-f]{1,4}:){3}|(?:(?:[0-9a-f]{1,4}:){0,2}[0-9a-f]{1,4})?::(?:[0-9a-f]{1,4}:){2}|(?:(?:[0-9a-f]{1,4}:){0,3}[0-9a-f]{1,4})?::[0-9a-f]{1,4}:|(?:(?:[0-9a-f]{1,4}:){0,4}[0-9a-f]{1,4})?::)(?:[0-9a-f]{1,4}:[0-9a-f]{1,4}|(?:(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d\d?))|(?:(?:[0-9a-f]{1,4}:){0,5}[0-9a-f]{1,4})?::[0-9a-f]{1,4}|(?:(?:[0-9a-f]{1,4}:){0,6}[0-9a-f]{1,4})?::)|[Vv][0-9a-f]+\.[a-z0-9\-._~!$&'()*+,;=:]+)\]|(?:(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d\d?)|(?:[a-z0-9\-._~!$&'()*+,;=]|%[0-9a-f]{2})*)(?::\d*)?(?:\/(?:[a-z0-9\-._~!$&'()*+,;=:@]|%[0-9a-f]{2})*)*|\/(?:(?:[a-z0-9\-._~!$&'()*+,;=:@]|%[0-9a-f]{2})+(?:\/(?:[a-z0-9\-._~!$&'()*+,;=:@]|%[0-9a-f]{2})*)*)?|(?:[a-z0-9\-._~!$&'()*+,;=:@]|%[0-9a-f]{2})+(?:\/(?:[a-z0-9\-._~!$&'()*+,;=:@]|%[0-9a-f]{2})*)*)(?:\?(?:[a-z0-9\-._~!$&'()*+,;=:@/?]|%[0-9a-f]{2})*)?(?:#(?:[a-z0-9\-._~!$&'()*+,;=:@/?]|%[0-9a-f]{2})*)?$/i;
      var URIREF = /^(?:[a-z][a-z0-9+\-.]*:)?(?:\/?\/(?:(?:[a-z0-9\-._~!$&'()*+,;=:]|%[0-9a-f]{2})*@)?(?:\[(?:(?:(?:(?:[0-9a-f]{1,4}:){6}|::(?:[0-9a-f]{1,4}:){5}|(?:[0-9a-f]{1,4})?::(?:[0-9a-f]{1,4}:){4}|(?:(?:[0-9a-f]{1,4}:){0,1}[0-9a-f]{1,4})?::(?:[0-9a-f]{1,4}:){3}|(?:(?:[0-9a-f]{1,4}:){0,2}[0-9a-f]{1,4})?::(?:[0-9a-f]{1,4}:){2}|(?:(?:[0-9a-f]{1,4}:){0,3}[0-9a-f]{1,4})?::[0-9a-f]{1,4}:|(?:(?:[0-9a-f]{1,4}:){0,4}[0-9a-f]{1,4})?::)(?:[0-9a-f]{1,4}:[0-9a-f]{1,4}|(?:(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d\d?))|(?:(?:[0-9a-f]{1,4}:){0,5}[0-9a-f]{1,4})?::[0-9a-f]{1,4}|(?:(?:[0-9a-f]{1,4}:){0,6}[0-9a-f]{1,4})?::)|[Vv][0-9a-f]+\.[a-z0-9\-._~!$&'()*+,;=:]+)\]|(?:(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d\d?)|(?:[a-z0-9\-._~!$&'"()*+,;=]|%[0-9a-f]{2})*)(?::\d*)?(?:\/(?:[a-z0-9\-._~!$&'"()*+,;=:@]|%[0-9a-f]{2})*)*|\/(?:(?:[a-z0-9\-._~!$&'"()*+,;=:@]|%[0-9a-f]{2})+(?:\/(?:[a-z0-9\-._~!$&'"()*+,;=:@]|%[0-9a-f]{2})*)*)?|(?:[a-z0-9\-._~!$&'"()*+,;=:@]|%[0-9a-f]{2})+(?:\/(?:[a-z0-9\-._~!$&'"()*+,;=:@]|%[0-9a-f]{2})*)*)?(?:\?(?:[a-z0-9\-._~!$&'"()*+,;=:@/?]|%[0-9a-f]{2})*)?(?:#(?:[a-z0-9\-._~!$&'"()*+,;=:@/?]|%[0-9a-f]{2})*)?$/i;
      var URITEMPLATE = /^(?:(?:[^\x00-\x20"'<>%\\^`{|}]|%[0-9a-f]{2})|\{[+#./;?&=,!@|]?(?:[a-z0-9_]|%[0-9a-f]{2})+(?::[1-9][0-9]{0,3}|\*)?(?:,(?:[a-z0-9_]|%[0-9a-f]{2})+(?::[1-9][0-9]{0,3}|\*)?)*\})*$/i;
      var URL = /^(?:(?:http[s\u017F]?|ftp):\/\/)(?:(?:[\0-\x08\x0E-\x1F!-\x9F\xA1-\u167F\u1681-\u1FFF\u200B-\u2027\u202A-\u202E\u2030-\u205E\u2060-\u2FFF\u3001-\uD7FF\uE000-\uFEFE\uFF00-\uFFFF]|[\uD800-\uDBFF][\uDC00-\uDFFF]|[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?:[^\uD800-\uDBFF]|^)[\uDC00-\uDFFF])+(?::(?:[\0-\x08\x0E-\x1F!-\x9F\xA1-\u167F\u1681-\u1FFF\u200B-\u2027\u202A-\u202E\u2030-\u205E\u2060-\u2FFF\u3001-\uD7FF\uE000-\uFEFE\uFF00-\uFFFF]|[\uD800-\uDBFF][\uDC00-\uDFFF]|[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?:[^\uD800-\uDBFF]|^)[\uDC00-\uDFFF])*)?@)?(?:(?!10(?:\.[0-9]{1,3}){3})(?!127(?:\.[0-9]{1,3}){3})(?!169\.254(?:\.[0-9]{1,3}){2})(?!192\.168(?:\.[0-9]{1,3}){2})(?!172\.(?:1[6-9]|2[0-9]|3[01])(?:\.[0-9]{1,3}){2})(?:[1-9][0-9]?|1[0-9][0-9]|2[01][0-9]|22[0-3])(?:\.(?:1?[0-9]{1,2}|2[0-4][0-9]|25[0-5])){2}(?:\.(?:[1-9][0-9]?|1[0-9][0-9]|2[0-4][0-9]|25[0-4]))|(?:(?:(?:[0-9a-z\xA1-\uD7FF\uE000-\uFFFF]|[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?:[^\uD800-\uDBFF]|^)[\uDC00-\uDFFF])+-)*(?:[0-9a-z\xA1-\uD7FF\uE000-\uFFFF]|[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?:[^\uD800-\uDBFF]|^)[\uDC00-\uDFFF])+)(?:\.(?:(?:[0-9a-z\xA1-\uD7FF\uE000-\uFFFF]|[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?:[^\uD800-\uDBFF]|^)[\uDC00-\uDFFF])+-)*(?:[0-9a-z\xA1-\uD7FF\uE000-\uFFFF]|[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?:[^\uD800-\uDBFF]|^)[\uDC00-\uDFFF])+)*(?:\.(?:(?:[a-z\xA1-\uD7FF\uE000-\uFFFF]|[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?:[^\uD800-\uDBFF]|^)[\uDC00-\uDFFF]){2,})))(?::[0-9]{2,5})?(?:\/(?:[\0-\x08\x0E-\x1F!-\x9F\xA1-\u167F\u1681-\u1FFF\u200B-\u2027\u202A-\u202E\u2030-\u205E\u2060-\u2FFF\u3001-\uD7FF\uE000-\uFEFE\uFF00-\uFFFF]|[\uD800-\uDBFF][\uDC00-\uDFFF]|[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?:[^\uD800-\uDBFF]|^)[\uDC00-\uDFFF])*)?$/i;
      var UUID = /^(?:urn:uuid:)?[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}$/i;
      var JSON_POINTER = /^(?:\/(?:[^~/]|~0|~1)*)*$/;
      var JSON_POINTER_URI_FRAGMENT = /^#(?:\/(?:[a-z0-9_\-.!$&'()*+,;:=@]|%[0-9a-f]{2}|~0|~1)*)*$/i;
      var RELATIVE_JSON_POINTER = /^(?:0|[1-9][0-9]*)(?:#|(?:\/(?:[^~/]|~0|~1)*)*)$/;
      module.exports = formats;
      function formats(mode) {
        mode = mode == "full" ? "full" : "fast";
        return util.copy(formats[mode]);
      }
      formats.fast = {
        date: /^\d\d\d\d-[0-1]\d-[0-3]\d$/,
        time: /^(?:[0-2]\d:[0-5]\d:[0-5]\d|23:59:60)(?:\.\d+)?(?:z|[+-]\d\d(?::?\d\d)?)?$/i,
        "date-time": /^\d\d\d\d-[0-1]\d-[0-3]\d[t\s](?:[0-2]\d:[0-5]\d:[0-5]\d|23:59:60)(?:\.\d+)?(?:z|[+-]\d\d(?::?\d\d)?)$/i,
        uri: /^(?:[a-z][a-z0-9+\-.]*:)(?:\/?\/)?[^\s]*$/i,
        "uri-reference": /^(?:(?:[a-z][a-z0-9+\-.]*:)?\/?\/)?(?:[^\\\s#][^\s#]*)?(?:#[^\\\s]*)?$/i,
        "uri-template": URITEMPLATE,
        url: URL,
        email: /^[a-z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)*$/i,
        hostname: HOSTNAME,
        ipv4: /^(?:(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d\d?)$/,
        ipv6: /^\s*(?:(?:(?:[0-9a-f]{1,4}:){7}(?:[0-9a-f]{1,4}|:))|(?:(?:[0-9a-f]{1,4}:){6}(?::[0-9a-f]{1,4}|(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(?:(?:[0-9a-f]{1,4}:){5}(?:(?:(?::[0-9a-f]{1,4}){1,2})|:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(?:(?:[0-9a-f]{1,4}:){4}(?:(?:(?::[0-9a-f]{1,4}){1,3})|(?:(?::[0-9a-f]{1,4})?:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(?:(?:[0-9a-f]{1,4}:){3}(?:(?:(?::[0-9a-f]{1,4}){1,4})|(?:(?::[0-9a-f]{1,4}){0,2}:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(?:(?:[0-9a-f]{1,4}:){2}(?:(?:(?::[0-9a-f]{1,4}){1,5})|(?:(?::[0-9a-f]{1,4}){0,3}:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(?:(?:[0-9a-f]{1,4}:){1}(?:(?:(?::[0-9a-f]{1,4}){1,6})|(?:(?::[0-9a-f]{1,4}){0,4}:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(?::(?:(?:(?::[0-9a-f]{1,4}){1,7})|(?:(?::[0-9a-f]{1,4}){0,5}:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(?:%.+)?\s*$/i,
        regex,
        uuid: UUID,
        "json-pointer": JSON_POINTER,
        "json-pointer-uri-fragment": JSON_POINTER_URI_FRAGMENT,
        "relative-json-pointer": RELATIVE_JSON_POINTER
      };
      formats.full = {
        date,
        time,
        "date-time": date_time,
        uri,
        "uri-reference": URIREF,
        "uri-template": URITEMPLATE,
        url: URL,
        email: /^[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$/i,
        hostname: HOSTNAME,
        ipv4: /^(?:(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d\d?)$/,
        ipv6: /^\s*(?:(?:(?:[0-9a-f]{1,4}:){7}(?:[0-9a-f]{1,4}|:))|(?:(?:[0-9a-f]{1,4}:){6}(?::[0-9a-f]{1,4}|(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(?:(?:[0-9a-f]{1,4}:){5}(?:(?:(?::[0-9a-f]{1,4}){1,2})|:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(?:(?:[0-9a-f]{1,4}:){4}(?:(?:(?::[0-9a-f]{1,4}){1,3})|(?:(?::[0-9a-f]{1,4})?:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(?:(?:[0-9a-f]{1,4}:){3}(?:(?:(?::[0-9a-f]{1,4}){1,4})|(?:(?::[0-9a-f]{1,4}){0,2}:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(?:(?:[0-9a-f]{1,4}:){2}(?:(?:(?::[0-9a-f]{1,4}){1,5})|(?:(?::[0-9a-f]{1,4}){0,3}:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(?:(?:[0-9a-f]{1,4}:){1}(?:(?:(?::[0-9a-f]{1,4}){1,6})|(?:(?::[0-9a-f]{1,4}){0,4}:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(?::(?:(?:(?::[0-9a-f]{1,4}){1,7})|(?:(?::[0-9a-f]{1,4}){0,5}:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(?:%.+)?\s*$/i,
        regex,
        uuid: UUID,
        "json-pointer": JSON_POINTER,
        "json-pointer-uri-fragment": JSON_POINTER_URI_FRAGMENT,
        "relative-json-pointer": RELATIVE_JSON_POINTER
      };
      function isLeapYear(year) {
        return year % 4 === 0 && (year % 100 !== 0 || year % 400 === 0);
      }
      function date(str) {
        var matches = str.match(DATE);
        if (!matches)
          return false;
        var year = +matches[1];
        var month = +matches[2];
        var day = +matches[3];
        return month >= 1 && month <= 12 && day >= 1 && day <= (month == 2 && isLeapYear(year) ? 29 : DAYS[month]);
      }
      function time(str, full) {
        var matches = str.match(TIME);
        if (!matches)
          return false;
        var hour = matches[1];
        var minute = matches[2];
        var second = matches[3];
        var timeZone = matches[5];
        return (hour <= 23 && minute <= 59 && second <= 59 || hour == 23 && minute == 59 && second == 60) && (!full || timeZone);
      }
      var DATE_TIME_SEPARATOR = /t|\s/i;
      function date_time(str) {
        var dateTime = str.split(DATE_TIME_SEPARATOR);
        return dateTime.length == 2 && date(dateTime[0]) && time(dateTime[1], true);
      }
      var NOT_URI_FRAGMENT = /\/|:/;
      function uri(str) {
        return NOT_URI_FRAGMENT.test(str) && URI.test(str);
      }
      var Z_ANCHOR = /[^\\]\\Z/;
      function regex(str) {
        if (Z_ANCHOR.test(str))
          return false;
        try {
          new RegExp(str);
          return true;
        } catch (e) {
          return false;
        }
      }
    }
  });

  // node_modules/ajv/lib/dotjs/ref.js
  var require_ref = __commonJS({
    "node_modules/ajv/lib/dotjs/ref.js"(exports, module) {
      "use strict";
      module.exports = function generate_ref(it, $keyword, $ruleType) {
        var out = " ";
        var $lvl = it.level;
        var $dataLvl = it.dataLevel;
        var $schema = it.schema[$keyword];
        var $errSchemaPath = it.errSchemaPath + "/" + $keyword;
        var $breakOnError = !it.opts.allErrors;
        var $data = "data" + ($dataLvl || "");
        var $valid = "valid" + $lvl;
        var $async, $refCode;
        if ($schema == "#" || $schema == "#/") {
          if (it.isRoot) {
            $async = it.async;
            $refCode = "validate";
          } else {
            $async = it.root.schema.$async === true;
            $refCode = "root.refVal[0]";
          }
        } else {
          var $refVal = it.resolveRef(it.baseId, $schema, it.isRoot);
          if ($refVal === void 0) {
            var $message = it.MissingRefError.message(it.baseId, $schema);
            if (it.opts.missingRefs == "fail") {
              it.logger.error($message);
              var $$outStack = $$outStack || [];
              $$outStack.push(out);
              out = "";
              if (it.createErrors !== false) {
                out += " { keyword: '$ref' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { ref: '" + it.util.escapeQuotes($schema) + "' } ";
                if (it.opts.messages !== false) {
                  out += " , message: 'can\\'t resolve reference " + it.util.escapeQuotes($schema) + "' ";
                }
                if (it.opts.verbose) {
                  out += " , schema: " + it.util.toQuotedString($schema) + " , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
                }
                out += " } ";
              } else {
                out += " {} ";
              }
              var __err = out;
              out = $$outStack.pop();
              if (!it.compositeRule && $breakOnError) {
                if (it.async) {
                  out += " throw new ValidationError([" + __err + "]); ";
                } else {
                  out += " validate.errors = [" + __err + "]; return false; ";
                }
              } else {
                out += " var err = " + __err + ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
              }
              if ($breakOnError) {
                out += " if (false) { ";
              }
            } else if (it.opts.missingRefs == "ignore") {
              it.logger.warn($message);
              if ($breakOnError) {
                out += " if (true) { ";
              }
            } else {
              throw new it.MissingRefError(it.baseId, $schema, $message);
            }
          } else if ($refVal.inline) {
            var $it = it.util.copy(it);
            $it.level++;
            var $nextValid = "valid" + $it.level;
            $it.schema = $refVal.schema;
            $it.schemaPath = "";
            $it.errSchemaPath = $schema;
            var $code = it.validate($it).replace(/validate\.schema/g, $refVal.code);
            out += " " + $code + " ";
            if ($breakOnError) {
              out += " if (" + $nextValid + ") { ";
            }
          } else {
            $async = $refVal.$async === true || it.async && $refVal.$async !== false;
            $refCode = $refVal.code;
          }
        }
        if ($refCode) {
          var $$outStack = $$outStack || [];
          $$outStack.push(out);
          out = "";
          if (it.opts.passContext) {
            out += " " + $refCode + ".call(this, ";
          } else {
            out += " " + $refCode + "( ";
          }
          out += " " + $data + ", (dataPath || '')";
          if (it.errorPath != '""') {
            out += " + " + it.errorPath;
          }
          var $parentData = $dataLvl ? "data" + ($dataLvl - 1 || "") : "parentData", $parentDataProperty = $dataLvl ? it.dataPathArr[$dataLvl] : "parentDataProperty";
          out += " , " + $parentData + " , " + $parentDataProperty + ", rootData)  ";
          var __callValidate = out;
          out = $$outStack.pop();
          if ($async) {
            if (!it.async)
              throw new Error("async schema referenced by sync schema");
            if ($breakOnError) {
              out += " var " + $valid + "; ";
            }
            out += " try { await " + __callValidate + "; ";
            if ($breakOnError) {
              out += " " + $valid + " = true; ";
            }
            out += " } catch (e) { if (!(e instanceof ValidationError)) throw e; if (vErrors === null) vErrors = e.errors; else vErrors = vErrors.concat(e.errors); errors = vErrors.length; ";
            if ($breakOnError) {
              out += " " + $valid + " = false; ";
            }
            out += " } ";
            if ($breakOnError) {
              out += " if (" + $valid + ") { ";
            }
          } else {
            out += " if (!" + __callValidate + ") { if (vErrors === null) vErrors = " + $refCode + ".errors; else vErrors = vErrors.concat(" + $refCode + ".errors); errors = vErrors.length; } ";
            if ($breakOnError) {
              out += " else { ";
            }
          }
        }
        return out;
      };
    }
  });

  // node_modules/ajv/lib/dotjs/allOf.js
  var require_allOf = __commonJS({
    "node_modules/ajv/lib/dotjs/allOf.js"(exports, module) {
      "use strict";
      module.exports = function generate_allOf(it, $keyword, $ruleType) {
        var out = " ";
        var $schema = it.schema[$keyword];
        var $schemaPath = it.schemaPath + it.util.getProperty($keyword);
        var $errSchemaPath = it.errSchemaPath + "/" + $keyword;
        var $breakOnError = !it.opts.allErrors;
        var $it = it.util.copy(it);
        var $closingBraces = "";
        $it.level++;
        var $nextValid = "valid" + $it.level;
        var $currentBaseId = $it.baseId, $allSchemasEmpty = true;
        var arr1 = $schema;
        if (arr1) {
          var $sch, $i = -1, l1 = arr1.length - 1;
          while ($i < l1) {
            $sch = arr1[$i += 1];
            if (it.opts.strictKeywords ? typeof $sch == "object" && Object.keys($sch).length > 0 || $sch === false : it.util.schemaHasRules($sch, it.RULES.all)) {
              $allSchemasEmpty = false;
              $it.schema = $sch;
              $it.schemaPath = $schemaPath + "[" + $i + "]";
              $it.errSchemaPath = $errSchemaPath + "/" + $i;
              out += "  " + it.validate($it) + " ";
              $it.baseId = $currentBaseId;
              if ($breakOnError) {
                out += " if (" + $nextValid + ") { ";
                $closingBraces += "}";
              }
            }
          }
        }
        if ($breakOnError) {
          if ($allSchemasEmpty) {
            out += " if (true) { ";
          } else {
            out += " " + $closingBraces.slice(0, -1) + " ";
          }
        }
        return out;
      };
    }
  });

  // node_modules/ajv/lib/dotjs/anyOf.js
  var require_anyOf = __commonJS({
    "node_modules/ajv/lib/dotjs/anyOf.js"(exports, module) {
      "use strict";
      module.exports = function generate_anyOf(it, $keyword, $ruleType) {
        var out = " ";
        var $lvl = it.level;
        var $dataLvl = it.dataLevel;
        var $schema = it.schema[$keyword];
        var $schemaPath = it.schemaPath + it.util.getProperty($keyword);
        var $errSchemaPath = it.errSchemaPath + "/" + $keyword;
        var $breakOnError = !it.opts.allErrors;
        var $data = "data" + ($dataLvl || "");
        var $valid = "valid" + $lvl;
        var $errs = "errs__" + $lvl;
        var $it = it.util.copy(it);
        var $closingBraces = "";
        $it.level++;
        var $nextValid = "valid" + $it.level;
        var $noEmptySchema = $schema.every(function($sch2) {
          return it.opts.strictKeywords ? typeof $sch2 == "object" && Object.keys($sch2).length > 0 || $sch2 === false : it.util.schemaHasRules($sch2, it.RULES.all);
        });
        if ($noEmptySchema) {
          var $currentBaseId = $it.baseId;
          out += " var " + $errs + " = errors; var " + $valid + " = false;  ";
          var $wasComposite = it.compositeRule;
          it.compositeRule = $it.compositeRule = true;
          var arr1 = $schema;
          if (arr1) {
            var $sch, $i = -1, l1 = arr1.length - 1;
            while ($i < l1) {
              $sch = arr1[$i += 1];
              $it.schema = $sch;
              $it.schemaPath = $schemaPath + "[" + $i + "]";
              $it.errSchemaPath = $errSchemaPath + "/" + $i;
              out += "  " + it.validate($it) + " ";
              $it.baseId = $currentBaseId;
              out += " " + $valid + " = " + $valid + " || " + $nextValid + "; if (!" + $valid + ") { ";
              $closingBraces += "}";
            }
          }
          it.compositeRule = $it.compositeRule = $wasComposite;
          out += " " + $closingBraces + " if (!" + $valid + ") {   var err =   ";
          if (it.createErrors !== false) {
            out += " { keyword: 'anyOf' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: {} ";
            if (it.opts.messages !== false) {
              out += " , message: 'should match some schema in anyOf' ";
            }
            if (it.opts.verbose) {
              out += " , schema: validate.schema" + $schemaPath + " , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
            }
            out += " } ";
          } else {
            out += " {} ";
          }
          out += ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
          if (!it.compositeRule && $breakOnError) {
            if (it.async) {
              out += " throw new ValidationError(vErrors); ";
            } else {
              out += " validate.errors = vErrors; return false; ";
            }
          }
          out += " } else {  errors = " + $errs + "; if (vErrors !== null) { if (" + $errs + ") vErrors.length = " + $errs + "; else vErrors = null; } ";
          if (it.opts.allErrors) {
            out += " } ";
          }
        } else {
          if ($breakOnError) {
            out += " if (true) { ";
          }
        }
        return out;
      };
    }
  });

  // node_modules/ajv/lib/dotjs/comment.js
  var require_comment = __commonJS({
    "node_modules/ajv/lib/dotjs/comment.js"(exports, module) {
      "use strict";
      module.exports = function generate_comment(it, $keyword, $ruleType) {
        var out = " ";
        var $schema = it.schema[$keyword];
        var $errSchemaPath = it.errSchemaPath + "/" + $keyword;
        var $breakOnError = !it.opts.allErrors;
        var $comment = it.util.toQuotedString($schema);
        if (it.opts.$comment === true) {
          out += " console.log(" + $comment + ");";
        } else if (typeof it.opts.$comment == "function") {
          out += " self._opts.$comment(" + $comment + ", " + it.util.toQuotedString($errSchemaPath) + ", validate.root.schema);";
        }
        return out;
      };
    }
  });

  // node_modules/ajv/lib/dotjs/const.js
  var require_const = __commonJS({
    "node_modules/ajv/lib/dotjs/const.js"(exports, module) {
      "use strict";
      module.exports = function generate_const(it, $keyword, $ruleType) {
        var out = " ";
        var $lvl = it.level;
        var $dataLvl = it.dataLevel;
        var $schema = it.schema[$keyword];
        var $schemaPath = it.schemaPath + it.util.getProperty($keyword);
        var $errSchemaPath = it.errSchemaPath + "/" + $keyword;
        var $breakOnError = !it.opts.allErrors;
        var $data = "data" + ($dataLvl || "");
        var $valid = "valid" + $lvl;
        var $isData = it.opts.$data && $schema && $schema.$data, $schemaValue;
        if ($isData) {
          out += " var schema" + $lvl + " = " + it.util.getData($schema.$data, $dataLvl, it.dataPathArr) + "; ";
          $schemaValue = "schema" + $lvl;
        } else {
          $schemaValue = $schema;
        }
        if (!$isData) {
          out += " var schema" + $lvl + " = validate.schema" + $schemaPath + ";";
        }
        out += "var " + $valid + " = equal(" + $data + ", schema" + $lvl + "); if (!" + $valid + ") {   ";
        var $$outStack = $$outStack || [];
        $$outStack.push(out);
        out = "";
        if (it.createErrors !== false) {
          out += " { keyword: 'const' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { allowedValue: schema" + $lvl + " } ";
          if (it.opts.messages !== false) {
            out += " , message: 'should be equal to constant' ";
          }
          if (it.opts.verbose) {
            out += " , schema: validate.schema" + $schemaPath + " , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
          }
          out += " } ";
        } else {
          out += " {} ";
        }
        var __err = out;
        out = $$outStack.pop();
        if (!it.compositeRule && $breakOnError) {
          if (it.async) {
            out += " throw new ValidationError([" + __err + "]); ";
          } else {
            out += " validate.errors = [" + __err + "]; return false; ";
          }
        } else {
          out += " var err = " + __err + ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
        }
        out += " }";
        if ($breakOnError) {
          out += " else { ";
        }
        return out;
      };
    }
  });

  // node_modules/ajv/lib/dotjs/contains.js
  var require_contains = __commonJS({
    "node_modules/ajv/lib/dotjs/contains.js"(exports, module) {
      "use strict";
      module.exports = function generate_contains(it, $keyword, $ruleType) {
        var out = " ";
        var $lvl = it.level;
        var $dataLvl = it.dataLevel;
        var $schema = it.schema[$keyword];
        var $schemaPath = it.schemaPath + it.util.getProperty($keyword);
        var $errSchemaPath = it.errSchemaPath + "/" + $keyword;
        var $breakOnError = !it.opts.allErrors;
        var $data = "data" + ($dataLvl || "");
        var $valid = "valid" + $lvl;
        var $errs = "errs__" + $lvl;
        var $it = it.util.copy(it);
        var $closingBraces = "";
        $it.level++;
        var $nextValid = "valid" + $it.level;
        var $idx = "i" + $lvl, $dataNxt = $it.dataLevel = it.dataLevel + 1, $nextData = "data" + $dataNxt, $currentBaseId = it.baseId, $nonEmptySchema = it.opts.strictKeywords ? typeof $schema == "object" && Object.keys($schema).length > 0 || $schema === false : it.util.schemaHasRules($schema, it.RULES.all);
        out += "var " + $errs + " = errors;var " + $valid + ";";
        if ($nonEmptySchema) {
          var $wasComposite = it.compositeRule;
          it.compositeRule = $it.compositeRule = true;
          $it.schema = $schema;
          $it.schemaPath = $schemaPath;
          $it.errSchemaPath = $errSchemaPath;
          out += " var " + $nextValid + " = false; for (var " + $idx + " = 0; " + $idx + " < " + $data + ".length; " + $idx + "++) { ";
          $it.errorPath = it.util.getPathExpr(it.errorPath, $idx, it.opts.jsonPointers, true);
          var $passData = $data + "[" + $idx + "]";
          $it.dataPathArr[$dataNxt] = $idx;
          var $code = it.validate($it);
          $it.baseId = $currentBaseId;
          if (it.util.varOccurences($code, $nextData) < 2) {
            out += " " + it.util.varReplace($code, $nextData, $passData) + " ";
          } else {
            out += " var " + $nextData + " = " + $passData + "; " + $code + " ";
          }
          out += " if (" + $nextValid + ") break; }  ";
          it.compositeRule = $it.compositeRule = $wasComposite;
          out += " " + $closingBraces + " if (!" + $nextValid + ") {";
        } else {
          out += " if (" + $data + ".length == 0) {";
        }
        var $$outStack = $$outStack || [];
        $$outStack.push(out);
        out = "";
        if (it.createErrors !== false) {
          out += " { keyword: 'contains' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: {} ";
          if (it.opts.messages !== false) {
            out += " , message: 'should contain a valid item' ";
          }
          if (it.opts.verbose) {
            out += " , schema: validate.schema" + $schemaPath + " , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
          }
          out += " } ";
        } else {
          out += " {} ";
        }
        var __err = out;
        out = $$outStack.pop();
        if (!it.compositeRule && $breakOnError) {
          if (it.async) {
            out += " throw new ValidationError([" + __err + "]); ";
          } else {
            out += " validate.errors = [" + __err + "]; return false; ";
          }
        } else {
          out += " var err = " + __err + ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
        }
        out += " } else { ";
        if ($nonEmptySchema) {
          out += "  errors = " + $errs + "; if (vErrors !== null) { if (" + $errs + ") vErrors.length = " + $errs + "; else vErrors = null; } ";
        }
        if (it.opts.allErrors) {
          out += " } ";
        }
        return out;
      };
    }
  });

  // node_modules/ajv/lib/dotjs/dependencies.js
  var require_dependencies = __commonJS({
    "node_modules/ajv/lib/dotjs/dependencies.js"(exports, module) {
      "use strict";
      module.exports = function generate_dependencies(it, $keyword, $ruleType) {
        var out = " ";
        var $lvl = it.level;
        var $dataLvl = it.dataLevel;
        var $schema = it.schema[$keyword];
        var $schemaPath = it.schemaPath + it.util.getProperty($keyword);
        var $errSchemaPath = it.errSchemaPath + "/" + $keyword;
        var $breakOnError = !it.opts.allErrors;
        var $data = "data" + ($dataLvl || "");
        var $errs = "errs__" + $lvl;
        var $it = it.util.copy(it);
        var $closingBraces = "";
        $it.level++;
        var $nextValid = "valid" + $it.level;
        var $schemaDeps = {}, $propertyDeps = {}, $ownProperties = it.opts.ownProperties;
        for ($property in $schema) {
          if ($property == "__proto__")
            continue;
          var $sch = $schema[$property];
          var $deps = Array.isArray($sch) ? $propertyDeps : $schemaDeps;
          $deps[$property] = $sch;
        }
        out += "var " + $errs + " = errors;";
        var $currentErrorPath = it.errorPath;
        out += "var missing" + $lvl + ";";
        for (var $property in $propertyDeps) {
          $deps = $propertyDeps[$property];
          if ($deps.length) {
            out += " if ( " + $data + it.util.getProperty($property) + " !== undefined ";
            if ($ownProperties) {
              out += " && Object.prototype.hasOwnProperty.call(" + $data + ", '" + it.util.escapeQuotes($property) + "') ";
            }
            if ($breakOnError) {
              out += " && ( ";
              var arr1 = $deps;
              if (arr1) {
                var $propertyKey, $i = -1, l1 = arr1.length - 1;
                while ($i < l1) {
                  $propertyKey = arr1[$i += 1];
                  if ($i) {
                    out += " || ";
                  }
                  var $prop = it.util.getProperty($propertyKey), $useData = $data + $prop;
                  out += " ( ( " + $useData + " === undefined ";
                  if ($ownProperties) {
                    out += " || ! Object.prototype.hasOwnProperty.call(" + $data + ", '" + it.util.escapeQuotes($propertyKey) + "') ";
                  }
                  out += ") && (missing" + $lvl + " = " + it.util.toQuotedString(it.opts.jsonPointers ? $propertyKey : $prop) + ") ) ";
                }
              }
              out += ")) {  ";
              var $propertyPath = "missing" + $lvl, $missingProperty = "' + " + $propertyPath + " + '";
              if (it.opts._errorDataPathProperty) {
                it.errorPath = it.opts.jsonPointers ? it.util.getPathExpr($currentErrorPath, $propertyPath, true) : $currentErrorPath + " + " + $propertyPath;
              }
              var $$outStack = $$outStack || [];
              $$outStack.push(out);
              out = "";
              if (it.createErrors !== false) {
                out += " { keyword: 'dependencies' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { property: '" + it.util.escapeQuotes($property) + "', missingProperty: '" + $missingProperty + "', depsCount: " + $deps.length + ", deps: '" + it.util.escapeQuotes($deps.length == 1 ? $deps[0] : $deps.join(", ")) + "' } ";
                if (it.opts.messages !== false) {
                  out += " , message: 'should have ";
                  if ($deps.length == 1) {
                    out += "property " + it.util.escapeQuotes($deps[0]);
                  } else {
                    out += "properties " + it.util.escapeQuotes($deps.join(", "));
                  }
                  out += " when property " + it.util.escapeQuotes($property) + " is present' ";
                }
                if (it.opts.verbose) {
                  out += " , schema: validate.schema" + $schemaPath + " , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
                }
                out += " } ";
              } else {
                out += " {} ";
              }
              var __err = out;
              out = $$outStack.pop();
              if (!it.compositeRule && $breakOnError) {
                if (it.async) {
                  out += " throw new ValidationError([" + __err + "]); ";
                } else {
                  out += " validate.errors = [" + __err + "]; return false; ";
                }
              } else {
                out += " var err = " + __err + ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
              }
            } else {
              out += " ) { ";
              var arr2 = $deps;
              if (arr2) {
                var $propertyKey, i2 = -1, l2 = arr2.length - 1;
                while (i2 < l2) {
                  $propertyKey = arr2[i2 += 1];
                  var $prop = it.util.getProperty($propertyKey), $missingProperty = it.util.escapeQuotes($propertyKey), $useData = $data + $prop;
                  if (it.opts._errorDataPathProperty) {
                    it.errorPath = it.util.getPath($currentErrorPath, $propertyKey, it.opts.jsonPointers);
                  }
                  out += " if ( " + $useData + " === undefined ";
                  if ($ownProperties) {
                    out += " || ! Object.prototype.hasOwnProperty.call(" + $data + ", '" + it.util.escapeQuotes($propertyKey) + "') ";
                  }
                  out += ") {  var err =   ";
                  if (it.createErrors !== false) {
                    out += " { keyword: 'dependencies' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { property: '" + it.util.escapeQuotes($property) + "', missingProperty: '" + $missingProperty + "', depsCount: " + $deps.length + ", deps: '" + it.util.escapeQuotes($deps.length == 1 ? $deps[0] : $deps.join(", ")) + "' } ";
                    if (it.opts.messages !== false) {
                      out += " , message: 'should have ";
                      if ($deps.length == 1) {
                        out += "property " + it.util.escapeQuotes($deps[0]);
                      } else {
                        out += "properties " + it.util.escapeQuotes($deps.join(", "));
                      }
                      out += " when property " + it.util.escapeQuotes($property) + " is present' ";
                    }
                    if (it.opts.verbose) {
                      out += " , schema: validate.schema" + $schemaPath + " , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
                    }
                    out += " } ";
                  } else {
                    out += " {} ";
                  }
                  out += ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; } ";
                }
              }
            }
            out += " }   ";
            if ($breakOnError) {
              $closingBraces += "}";
              out += " else { ";
            }
          }
        }
        it.errorPath = $currentErrorPath;
        var $currentBaseId = $it.baseId;
        for (var $property in $schemaDeps) {
          var $sch = $schemaDeps[$property];
          if (it.opts.strictKeywords ? typeof $sch == "object" && Object.keys($sch).length > 0 || $sch === false : it.util.schemaHasRules($sch, it.RULES.all)) {
            out += " " + $nextValid + " = true; if ( " + $data + it.util.getProperty($property) + " !== undefined ";
            if ($ownProperties) {
              out += " && Object.prototype.hasOwnProperty.call(" + $data + ", '" + it.util.escapeQuotes($property) + "') ";
            }
            out += ") { ";
            $it.schema = $sch;
            $it.schemaPath = $schemaPath + it.util.getProperty($property);
            $it.errSchemaPath = $errSchemaPath + "/" + it.util.escapeFragment($property);
            out += "  " + it.validate($it) + " ";
            $it.baseId = $currentBaseId;
            out += " }  ";
            if ($breakOnError) {
              out += " if (" + $nextValid + ") { ";
              $closingBraces += "}";
            }
          }
        }
        if ($breakOnError) {
          out += "   " + $closingBraces + " if (" + $errs + " == errors) {";
        }
        return out;
      };
    }
  });

  // node_modules/ajv/lib/dotjs/enum.js
  var require_enum = __commonJS({
    "node_modules/ajv/lib/dotjs/enum.js"(exports, module) {
      "use strict";
      module.exports = function generate_enum(it, $keyword, $ruleType) {
        var out = " ";
        var $lvl = it.level;
        var $dataLvl = it.dataLevel;
        var $schema = it.schema[$keyword];
        var $schemaPath = it.schemaPath + it.util.getProperty($keyword);
        var $errSchemaPath = it.errSchemaPath + "/" + $keyword;
        var $breakOnError = !it.opts.allErrors;
        var $data = "data" + ($dataLvl || "");
        var $valid = "valid" + $lvl;
        var $isData = it.opts.$data && $schema && $schema.$data, $schemaValue;
        if ($isData) {
          out += " var schema" + $lvl + " = " + it.util.getData($schema.$data, $dataLvl, it.dataPathArr) + "; ";
          $schemaValue = "schema" + $lvl;
        } else {
          $schemaValue = $schema;
        }
        var $i = "i" + $lvl, $vSchema = "schema" + $lvl;
        if (!$isData) {
          out += " var " + $vSchema + " = validate.schema" + $schemaPath + ";";
        }
        out += "var " + $valid + ";";
        if ($isData) {
          out += " if (schema" + $lvl + " === undefined) " + $valid + " = true; else if (!Array.isArray(schema" + $lvl + ")) " + $valid + " = false; else {";
        }
        out += "" + $valid + " = false;for (var " + $i + "=0; " + $i + "<" + $vSchema + ".length; " + $i + "++) if (equal(" + $data + ", " + $vSchema + "[" + $i + "])) { " + $valid + " = true; break; }";
        if ($isData) {
          out += "  }  ";
        }
        out += " if (!" + $valid + ") {   ";
        var $$outStack = $$outStack || [];
        $$outStack.push(out);
        out = "";
        if (it.createErrors !== false) {
          out += " { keyword: 'enum' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { allowedValues: schema" + $lvl + " } ";
          if (it.opts.messages !== false) {
            out += " , message: 'should be equal to one of the allowed values' ";
          }
          if (it.opts.verbose) {
            out += " , schema: validate.schema" + $schemaPath + " , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
          }
          out += " } ";
        } else {
          out += " {} ";
        }
        var __err = out;
        out = $$outStack.pop();
        if (!it.compositeRule && $breakOnError) {
          if (it.async) {
            out += " throw new ValidationError([" + __err + "]); ";
          } else {
            out += " validate.errors = [" + __err + "]; return false; ";
          }
        } else {
          out += " var err = " + __err + ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
        }
        out += " }";
        if ($breakOnError) {
          out += " else { ";
        }
        return out;
      };
    }
  });

  // node_modules/ajv/lib/dotjs/format.js
  var require_format = __commonJS({
    "node_modules/ajv/lib/dotjs/format.js"(exports, module) {
      "use strict";
      module.exports = function generate_format(it, $keyword, $ruleType) {
        var out = " ";
        var $lvl = it.level;
        var $dataLvl = it.dataLevel;
        var $schema = it.schema[$keyword];
        var $schemaPath = it.schemaPath + it.util.getProperty($keyword);
        var $errSchemaPath = it.errSchemaPath + "/" + $keyword;
        var $breakOnError = !it.opts.allErrors;
        var $data = "data" + ($dataLvl || "");
        if (it.opts.format === false) {
          if ($breakOnError) {
            out += " if (true) { ";
          }
          return out;
        }
        var $isData = it.opts.$data && $schema && $schema.$data, $schemaValue;
        if ($isData) {
          out += " var schema" + $lvl + " = " + it.util.getData($schema.$data, $dataLvl, it.dataPathArr) + "; ";
          $schemaValue = "schema" + $lvl;
        } else {
          $schemaValue = $schema;
        }
        var $unknownFormats = it.opts.unknownFormats, $allowUnknown = Array.isArray($unknownFormats);
        if ($isData) {
          var $format = "format" + $lvl, $isObject = "isObject" + $lvl, $formatType = "formatType" + $lvl;
          out += " var " + $format + " = formats[" + $schemaValue + "]; var " + $isObject + " = typeof " + $format + " == 'object' && !(" + $format + " instanceof RegExp) && " + $format + ".validate; var " + $formatType + " = " + $isObject + " && " + $format + ".type || 'string'; if (" + $isObject + ") { ";
          if (it.async) {
            out += " var async" + $lvl + " = " + $format + ".async; ";
          }
          out += " " + $format + " = " + $format + ".validate; } if (  ";
          if ($isData) {
            out += " (" + $schemaValue + " !== undefined && typeof " + $schemaValue + " != 'string') || ";
          }
          out += " (";
          if ($unknownFormats != "ignore") {
            out += " (" + $schemaValue + " && !" + $format + " ";
            if ($allowUnknown) {
              out += " && self._opts.unknownFormats.indexOf(" + $schemaValue + ") == -1 ";
            }
            out += ") || ";
          }
          out += " (" + $format + " && " + $formatType + " == '" + $ruleType + "' && !(typeof " + $format + " == 'function' ? ";
          if (it.async) {
            out += " (async" + $lvl + " ? await " + $format + "(" + $data + ") : " + $format + "(" + $data + ")) ";
          } else {
            out += " " + $format + "(" + $data + ") ";
          }
          out += " : " + $format + ".test(" + $data + "))))) {";
        } else {
          var $format = it.formats[$schema];
          if (!$format) {
            if ($unknownFormats == "ignore") {
              it.logger.warn('unknown format "' + $schema + '" ignored in schema at path "' + it.errSchemaPath + '"');
              if ($breakOnError) {
                out += " if (true) { ";
              }
              return out;
            } else if ($allowUnknown && $unknownFormats.indexOf($schema) >= 0) {
              if ($breakOnError) {
                out += " if (true) { ";
              }
              return out;
            } else {
              throw new Error('unknown format "' + $schema + '" is used in schema at path "' + it.errSchemaPath + '"');
            }
          }
          var $isObject = typeof $format == "object" && !($format instanceof RegExp) && $format.validate;
          var $formatType = $isObject && $format.type || "string";
          if ($isObject) {
            var $async = $format.async === true;
            $format = $format.validate;
          }
          if ($formatType != $ruleType) {
            if ($breakOnError) {
              out += " if (true) { ";
            }
            return out;
          }
          if ($async) {
            if (!it.async)
              throw new Error("async format in sync schema");
            var $formatRef = "formats" + it.util.getProperty($schema) + ".validate";
            out += " if (!(await " + $formatRef + "(" + $data + "))) { ";
          } else {
            out += " if (! ";
            var $formatRef = "formats" + it.util.getProperty($schema);
            if ($isObject)
              $formatRef += ".validate";
            if (typeof $format == "function") {
              out += " " + $formatRef + "(" + $data + ") ";
            } else {
              out += " " + $formatRef + ".test(" + $data + ") ";
            }
            out += ") { ";
          }
        }
        var $$outStack = $$outStack || [];
        $$outStack.push(out);
        out = "";
        if (it.createErrors !== false) {
          out += " { keyword: 'format' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { format:  ";
          if ($isData) {
            out += "" + $schemaValue;
          } else {
            out += "" + it.util.toQuotedString($schema);
          }
          out += "  } ";
          if (it.opts.messages !== false) {
            out += ` , message: 'should match format "`;
            if ($isData) {
              out += "' + " + $schemaValue + " + '";
            } else {
              out += "" + it.util.escapeQuotes($schema);
            }
            out += `"' `;
          }
          if (it.opts.verbose) {
            out += " , schema:  ";
            if ($isData) {
              out += "validate.schema" + $schemaPath;
            } else {
              out += "" + it.util.toQuotedString($schema);
            }
            out += "         , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
          }
          out += " } ";
        } else {
          out += " {} ";
        }
        var __err = out;
        out = $$outStack.pop();
        if (!it.compositeRule && $breakOnError) {
          if (it.async) {
            out += " throw new ValidationError([" + __err + "]); ";
          } else {
            out += " validate.errors = [" + __err + "]; return false; ";
          }
        } else {
          out += " var err = " + __err + ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
        }
        out += " } ";
        if ($breakOnError) {
          out += " else { ";
        }
        return out;
      };
    }
  });

  // node_modules/ajv/lib/dotjs/if.js
  var require_if = __commonJS({
    "node_modules/ajv/lib/dotjs/if.js"(exports, module) {
      "use strict";
      module.exports = function generate_if(it, $keyword, $ruleType) {
        var out = " ";
        var $lvl = it.level;
        var $dataLvl = it.dataLevel;
        var $schema = it.schema[$keyword];
        var $schemaPath = it.schemaPath + it.util.getProperty($keyword);
        var $errSchemaPath = it.errSchemaPath + "/" + $keyword;
        var $breakOnError = !it.opts.allErrors;
        var $data = "data" + ($dataLvl || "");
        var $valid = "valid" + $lvl;
        var $errs = "errs__" + $lvl;
        var $it = it.util.copy(it);
        $it.level++;
        var $nextValid = "valid" + $it.level;
        var $thenSch = it.schema["then"], $elseSch = it.schema["else"], $thenPresent = $thenSch !== void 0 && (it.opts.strictKeywords ? typeof $thenSch == "object" && Object.keys($thenSch).length > 0 || $thenSch === false : it.util.schemaHasRules($thenSch, it.RULES.all)), $elsePresent = $elseSch !== void 0 && (it.opts.strictKeywords ? typeof $elseSch == "object" && Object.keys($elseSch).length > 0 || $elseSch === false : it.util.schemaHasRules($elseSch, it.RULES.all)), $currentBaseId = $it.baseId;
        if ($thenPresent || $elsePresent) {
          var $ifClause;
          $it.createErrors = false;
          $it.schema = $schema;
          $it.schemaPath = $schemaPath;
          $it.errSchemaPath = $errSchemaPath;
          out += " var " + $errs + " = errors; var " + $valid + " = true;  ";
          var $wasComposite = it.compositeRule;
          it.compositeRule = $it.compositeRule = true;
          out += "  " + it.validate($it) + " ";
          $it.baseId = $currentBaseId;
          $it.createErrors = true;
          out += "  errors = " + $errs + "; if (vErrors !== null) { if (" + $errs + ") vErrors.length = " + $errs + "; else vErrors = null; }  ";
          it.compositeRule = $it.compositeRule = $wasComposite;
          if ($thenPresent) {
            out += " if (" + $nextValid + ") {  ";
            $it.schema = it.schema["then"];
            $it.schemaPath = it.schemaPath + ".then";
            $it.errSchemaPath = it.errSchemaPath + "/then";
            out += "  " + it.validate($it) + " ";
            $it.baseId = $currentBaseId;
            out += " " + $valid + " = " + $nextValid + "; ";
            if ($thenPresent && $elsePresent) {
              $ifClause = "ifClause" + $lvl;
              out += " var " + $ifClause + " = 'then'; ";
            } else {
              $ifClause = "'then'";
            }
            out += " } ";
            if ($elsePresent) {
              out += " else { ";
            }
          } else {
            out += " if (!" + $nextValid + ") { ";
          }
          if ($elsePresent) {
            $it.schema = it.schema["else"];
            $it.schemaPath = it.schemaPath + ".else";
            $it.errSchemaPath = it.errSchemaPath + "/else";
            out += "  " + it.validate($it) + " ";
            $it.baseId = $currentBaseId;
            out += " " + $valid + " = " + $nextValid + "; ";
            if ($thenPresent && $elsePresent) {
              $ifClause = "ifClause" + $lvl;
              out += " var " + $ifClause + " = 'else'; ";
            } else {
              $ifClause = "'else'";
            }
            out += " } ";
          }
          out += " if (!" + $valid + ") {   var err =   ";
          if (it.createErrors !== false) {
            out += " { keyword: 'if' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { failingKeyword: " + $ifClause + " } ";
            if (it.opts.messages !== false) {
              out += ` , message: 'should match "' + ` + $ifClause + ` + '" schema' `;
            }
            if (it.opts.verbose) {
              out += " , schema: validate.schema" + $schemaPath + " , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
            }
            out += " } ";
          } else {
            out += " {} ";
          }
          out += ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
          if (!it.compositeRule && $breakOnError) {
            if (it.async) {
              out += " throw new ValidationError(vErrors); ";
            } else {
              out += " validate.errors = vErrors; return false; ";
            }
          }
          out += " }   ";
          if ($breakOnError) {
            out += " else { ";
          }
        } else {
          if ($breakOnError) {
            out += " if (true) { ";
          }
        }
        return out;
      };
    }
  });

  // node_modules/ajv/lib/dotjs/items.js
  var require_items = __commonJS({
    "node_modules/ajv/lib/dotjs/items.js"(exports, module) {
      "use strict";
      module.exports = function generate_items(it, $keyword, $ruleType) {
        var out = " ";
        var $lvl = it.level;
        var $dataLvl = it.dataLevel;
        var $schema = it.schema[$keyword];
        var $schemaPath = it.schemaPath + it.util.getProperty($keyword);
        var $errSchemaPath = it.errSchemaPath + "/" + $keyword;
        var $breakOnError = !it.opts.allErrors;
        var $data = "data" + ($dataLvl || "");
        var $valid = "valid" + $lvl;
        var $errs = "errs__" + $lvl;
        var $it = it.util.copy(it);
        var $closingBraces = "";
        $it.level++;
        var $nextValid = "valid" + $it.level;
        var $idx = "i" + $lvl, $dataNxt = $it.dataLevel = it.dataLevel + 1, $nextData = "data" + $dataNxt, $currentBaseId = it.baseId;
        out += "var " + $errs + " = errors;var " + $valid + ";";
        if (Array.isArray($schema)) {
          var $additionalItems = it.schema.additionalItems;
          if ($additionalItems === false) {
            out += " " + $valid + " = " + $data + ".length <= " + $schema.length + "; ";
            var $currErrSchemaPath = $errSchemaPath;
            $errSchemaPath = it.errSchemaPath + "/additionalItems";
            out += "  if (!" + $valid + ") {   ";
            var $$outStack = $$outStack || [];
            $$outStack.push(out);
            out = "";
            if (it.createErrors !== false) {
              out += " { keyword: 'additionalItems' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { limit: " + $schema.length + " } ";
              if (it.opts.messages !== false) {
                out += " , message: 'should NOT have more than " + $schema.length + " items' ";
              }
              if (it.opts.verbose) {
                out += " , schema: false , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
              }
              out += " } ";
            } else {
              out += " {} ";
            }
            var __err = out;
            out = $$outStack.pop();
            if (!it.compositeRule && $breakOnError) {
              if (it.async) {
                out += " throw new ValidationError([" + __err + "]); ";
              } else {
                out += " validate.errors = [" + __err + "]; return false; ";
              }
            } else {
              out += " var err = " + __err + ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
            }
            out += " } ";
            $errSchemaPath = $currErrSchemaPath;
            if ($breakOnError) {
              $closingBraces += "}";
              out += " else { ";
            }
          }
          var arr1 = $schema;
          if (arr1) {
            var $sch, $i = -1, l1 = arr1.length - 1;
            while ($i < l1) {
              $sch = arr1[$i += 1];
              if (it.opts.strictKeywords ? typeof $sch == "object" && Object.keys($sch).length > 0 || $sch === false : it.util.schemaHasRules($sch, it.RULES.all)) {
                out += " " + $nextValid + " = true; if (" + $data + ".length > " + $i + ") { ";
                var $passData = $data + "[" + $i + "]";
                $it.schema = $sch;
                $it.schemaPath = $schemaPath + "[" + $i + "]";
                $it.errSchemaPath = $errSchemaPath + "/" + $i;
                $it.errorPath = it.util.getPathExpr(it.errorPath, $i, it.opts.jsonPointers, true);
                $it.dataPathArr[$dataNxt] = $i;
                var $code = it.validate($it);
                $it.baseId = $currentBaseId;
                if (it.util.varOccurences($code, $nextData) < 2) {
                  out += " " + it.util.varReplace($code, $nextData, $passData) + " ";
                } else {
                  out += " var " + $nextData + " = " + $passData + "; " + $code + " ";
                }
                out += " }  ";
                if ($breakOnError) {
                  out += " if (" + $nextValid + ") { ";
                  $closingBraces += "}";
                }
              }
            }
          }
          if (typeof $additionalItems == "object" && (it.opts.strictKeywords ? typeof $additionalItems == "object" && Object.keys($additionalItems).length > 0 || $additionalItems === false : it.util.schemaHasRules($additionalItems, it.RULES.all))) {
            $it.schema = $additionalItems;
            $it.schemaPath = it.schemaPath + ".additionalItems";
            $it.errSchemaPath = it.errSchemaPath + "/additionalItems";
            out += " " + $nextValid + " = true; if (" + $data + ".length > " + $schema.length + ") {  for (var " + $idx + " = " + $schema.length + "; " + $idx + " < " + $data + ".length; " + $idx + "++) { ";
            $it.errorPath = it.util.getPathExpr(it.errorPath, $idx, it.opts.jsonPointers, true);
            var $passData = $data + "[" + $idx + "]";
            $it.dataPathArr[$dataNxt] = $idx;
            var $code = it.validate($it);
            $it.baseId = $currentBaseId;
            if (it.util.varOccurences($code, $nextData) < 2) {
              out += " " + it.util.varReplace($code, $nextData, $passData) + " ";
            } else {
              out += " var " + $nextData + " = " + $passData + "; " + $code + " ";
            }
            if ($breakOnError) {
              out += " if (!" + $nextValid + ") break; ";
            }
            out += " } }  ";
            if ($breakOnError) {
              out += " if (" + $nextValid + ") { ";
              $closingBraces += "}";
            }
          }
        } else if (it.opts.strictKeywords ? typeof $schema == "object" && Object.keys($schema).length > 0 || $schema === false : it.util.schemaHasRules($schema, it.RULES.all)) {
          $it.schema = $schema;
          $it.schemaPath = $schemaPath;
          $it.errSchemaPath = $errSchemaPath;
          out += "  for (var " + $idx + " = " + 0 + "; " + $idx + " < " + $data + ".length; " + $idx + "++) { ";
          $it.errorPath = it.util.getPathExpr(it.errorPath, $idx, it.opts.jsonPointers, true);
          var $passData = $data + "[" + $idx + "]";
          $it.dataPathArr[$dataNxt] = $idx;
          var $code = it.validate($it);
          $it.baseId = $currentBaseId;
          if (it.util.varOccurences($code, $nextData) < 2) {
            out += " " + it.util.varReplace($code, $nextData, $passData) + " ";
          } else {
            out += " var " + $nextData + " = " + $passData + "; " + $code + " ";
          }
          if ($breakOnError) {
            out += " if (!" + $nextValid + ") break; ";
          }
          out += " }";
        }
        if ($breakOnError) {
          out += " " + $closingBraces + " if (" + $errs + " == errors) {";
        }
        return out;
      };
    }
  });

  // node_modules/ajv/lib/dotjs/_limit.js
  var require_limit = __commonJS({
    "node_modules/ajv/lib/dotjs/_limit.js"(exports, module) {
      "use strict";
      module.exports = function generate__limit(it, $keyword, $ruleType) {
        var out = " ";
        var $lvl = it.level;
        var $dataLvl = it.dataLevel;
        var $schema = it.schema[$keyword];
        var $schemaPath = it.schemaPath + it.util.getProperty($keyword);
        var $errSchemaPath = it.errSchemaPath + "/" + $keyword;
        var $breakOnError = !it.opts.allErrors;
        var $errorKeyword;
        var $data = "data" + ($dataLvl || "");
        var $isData = it.opts.$data && $schema && $schema.$data, $schemaValue;
        if ($isData) {
          out += " var schema" + $lvl + " = " + it.util.getData($schema.$data, $dataLvl, it.dataPathArr) + "; ";
          $schemaValue = "schema" + $lvl;
        } else {
          $schemaValue = $schema;
        }
        var $isMax = $keyword == "maximum", $exclusiveKeyword = $isMax ? "exclusiveMaximum" : "exclusiveMinimum", $schemaExcl = it.schema[$exclusiveKeyword], $isDataExcl = it.opts.$data && $schemaExcl && $schemaExcl.$data, $op = $isMax ? "<" : ">", $notOp = $isMax ? ">" : "<", $errorKeyword = void 0;
        if (!($isData || typeof $schema == "number" || $schema === void 0)) {
          throw new Error($keyword + " must be number");
        }
        if (!($isDataExcl || $schemaExcl === void 0 || typeof $schemaExcl == "number" || typeof $schemaExcl == "boolean")) {
          throw new Error($exclusiveKeyword + " must be number or boolean");
        }
        if ($isDataExcl) {
          var $schemaValueExcl = it.util.getData($schemaExcl.$data, $dataLvl, it.dataPathArr), $exclusive = "exclusive" + $lvl, $exclType = "exclType" + $lvl, $exclIsNumber = "exclIsNumber" + $lvl, $opExpr = "op" + $lvl, $opStr = "' + " + $opExpr + " + '";
          out += " var schemaExcl" + $lvl + " = " + $schemaValueExcl + "; ";
          $schemaValueExcl = "schemaExcl" + $lvl;
          out += " var " + $exclusive + "; var " + $exclType + " = typeof " + $schemaValueExcl + "; if (" + $exclType + " != 'boolean' && " + $exclType + " != 'undefined' && " + $exclType + " != 'number') { ";
          var $errorKeyword = $exclusiveKeyword;
          var $$outStack = $$outStack || [];
          $$outStack.push(out);
          out = "";
          if (it.createErrors !== false) {
            out += " { keyword: '" + ($errorKeyword || "_exclusiveLimit") + "' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: {} ";
            if (it.opts.messages !== false) {
              out += " , message: '" + $exclusiveKeyword + " should be boolean' ";
            }
            if (it.opts.verbose) {
              out += " , schema: validate.schema" + $schemaPath + " , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
            }
            out += " } ";
          } else {
            out += " {} ";
          }
          var __err = out;
          out = $$outStack.pop();
          if (!it.compositeRule && $breakOnError) {
            if (it.async) {
              out += " throw new ValidationError([" + __err + "]); ";
            } else {
              out += " validate.errors = [" + __err + "]; return false; ";
            }
          } else {
            out += " var err = " + __err + ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
          }
          out += " } else if ( ";
          if ($isData) {
            out += " (" + $schemaValue + " !== undefined && typeof " + $schemaValue + " != 'number') || ";
          }
          out += " " + $exclType + " == 'number' ? ( (" + $exclusive + " = " + $schemaValue + " === undefined || " + $schemaValueExcl + " " + $op + "= " + $schemaValue + ") ? " + $data + " " + $notOp + "= " + $schemaValueExcl + " : " + $data + " " + $notOp + " " + $schemaValue + " ) : ( (" + $exclusive + " = " + $schemaValueExcl + " === true) ? " + $data + " " + $notOp + "= " + $schemaValue + " : " + $data + " " + $notOp + " " + $schemaValue + " ) || " + $data + " !== " + $data + ") { var op" + $lvl + " = " + $exclusive + " ? '" + $op + "' : '" + $op + "='; ";
          if ($schema === void 0) {
            $errorKeyword = $exclusiveKeyword;
            $errSchemaPath = it.errSchemaPath + "/" + $exclusiveKeyword;
            $schemaValue = $schemaValueExcl;
            $isData = $isDataExcl;
          }
        } else {
          var $exclIsNumber = typeof $schemaExcl == "number", $opStr = $op;
          if ($exclIsNumber && $isData) {
            var $opExpr = "'" + $opStr + "'";
            out += " if ( ";
            if ($isData) {
              out += " (" + $schemaValue + " !== undefined && typeof " + $schemaValue + " != 'number') || ";
            }
            out += " ( " + $schemaValue + " === undefined || " + $schemaExcl + " " + $op + "= " + $schemaValue + " ? " + $data + " " + $notOp + "= " + $schemaExcl + " : " + $data + " " + $notOp + " " + $schemaValue + " ) || " + $data + " !== " + $data + ") { ";
          } else {
            if ($exclIsNumber && $schema === void 0) {
              $exclusive = true;
              $errorKeyword = $exclusiveKeyword;
              $errSchemaPath = it.errSchemaPath + "/" + $exclusiveKeyword;
              $schemaValue = $schemaExcl;
              $notOp += "=";
            } else {
              if ($exclIsNumber)
                $schemaValue = Math[$isMax ? "min" : "max"]($schemaExcl, $schema);
              if ($schemaExcl === ($exclIsNumber ? $schemaValue : true)) {
                $exclusive = true;
                $errorKeyword = $exclusiveKeyword;
                $errSchemaPath = it.errSchemaPath + "/" + $exclusiveKeyword;
                $notOp += "=";
              } else {
                $exclusive = false;
                $opStr += "=";
              }
            }
            var $opExpr = "'" + $opStr + "'";
            out += " if ( ";
            if ($isData) {
              out += " (" + $schemaValue + " !== undefined && typeof " + $schemaValue + " != 'number') || ";
            }
            out += " " + $data + " " + $notOp + " " + $schemaValue + " || " + $data + " !== " + $data + ") { ";
          }
        }
        $errorKeyword = $errorKeyword || $keyword;
        var $$outStack = $$outStack || [];
        $$outStack.push(out);
        out = "";
        if (it.createErrors !== false) {
          out += " { keyword: '" + ($errorKeyword || "_limit") + "' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { comparison: " + $opExpr + ", limit: " + $schemaValue + ", exclusive: " + $exclusive + " } ";
          if (it.opts.messages !== false) {
            out += " , message: 'should be " + $opStr + " ";
            if ($isData) {
              out += "' + " + $schemaValue;
            } else {
              out += "" + $schemaValue + "'";
            }
          }
          if (it.opts.verbose) {
            out += " , schema:  ";
            if ($isData) {
              out += "validate.schema" + $schemaPath;
            } else {
              out += "" + $schema;
            }
            out += "         , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
          }
          out += " } ";
        } else {
          out += " {} ";
        }
        var __err = out;
        out = $$outStack.pop();
        if (!it.compositeRule && $breakOnError) {
          if (it.async) {
            out += " throw new ValidationError([" + __err + "]); ";
          } else {
            out += " validate.errors = [" + __err + "]; return false; ";
          }
        } else {
          out += " var err = " + __err + ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
        }
        out += " } ";
        if ($breakOnError) {
          out += " else { ";
        }
        return out;
      };
    }
  });

  // node_modules/ajv/lib/dotjs/_limitItems.js
  var require_limitItems = __commonJS({
    "node_modules/ajv/lib/dotjs/_limitItems.js"(exports, module) {
      "use strict";
      module.exports = function generate__limitItems(it, $keyword, $ruleType) {
        var out = " ";
        var $lvl = it.level;
        var $dataLvl = it.dataLevel;
        var $schema = it.schema[$keyword];
        var $schemaPath = it.schemaPath + it.util.getProperty($keyword);
        var $errSchemaPath = it.errSchemaPath + "/" + $keyword;
        var $breakOnError = !it.opts.allErrors;
        var $errorKeyword;
        var $data = "data" + ($dataLvl || "");
        var $isData = it.opts.$data && $schema && $schema.$data, $schemaValue;
        if ($isData) {
          out += " var schema" + $lvl + " = " + it.util.getData($schema.$data, $dataLvl, it.dataPathArr) + "; ";
          $schemaValue = "schema" + $lvl;
        } else {
          $schemaValue = $schema;
        }
        if (!($isData || typeof $schema == "number")) {
          throw new Error($keyword + " must be number");
        }
        var $op = $keyword == "maxItems" ? ">" : "<";
        out += "if ( ";
        if ($isData) {
          out += " (" + $schemaValue + " !== undefined && typeof " + $schemaValue + " != 'number') || ";
        }
        out += " " + $data + ".length " + $op + " " + $schemaValue + ") { ";
        var $errorKeyword = $keyword;
        var $$outStack = $$outStack || [];
        $$outStack.push(out);
        out = "";
        if (it.createErrors !== false) {
          out += " { keyword: '" + ($errorKeyword || "_limitItems") + "' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { limit: " + $schemaValue + " } ";
          if (it.opts.messages !== false) {
            out += " , message: 'should NOT have ";
            if ($keyword == "maxItems") {
              out += "more";
            } else {
              out += "fewer";
            }
            out += " than ";
            if ($isData) {
              out += "' + " + $schemaValue + " + '";
            } else {
              out += "" + $schema;
            }
            out += " items' ";
          }
          if (it.opts.verbose) {
            out += " , schema:  ";
            if ($isData) {
              out += "validate.schema" + $schemaPath;
            } else {
              out += "" + $schema;
            }
            out += "         , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
          }
          out += " } ";
        } else {
          out += " {} ";
        }
        var __err = out;
        out = $$outStack.pop();
        if (!it.compositeRule && $breakOnError) {
          if (it.async) {
            out += " throw new ValidationError([" + __err + "]); ";
          } else {
            out += " validate.errors = [" + __err + "]; return false; ";
          }
        } else {
          out += " var err = " + __err + ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
        }
        out += "} ";
        if ($breakOnError) {
          out += " else { ";
        }
        return out;
      };
    }
  });

  // node_modules/ajv/lib/dotjs/_limitLength.js
  var require_limitLength = __commonJS({
    "node_modules/ajv/lib/dotjs/_limitLength.js"(exports, module) {
      "use strict";
      module.exports = function generate__limitLength(it, $keyword, $ruleType) {
        var out = " ";
        var $lvl = it.level;
        var $dataLvl = it.dataLevel;
        var $schema = it.schema[$keyword];
        var $schemaPath = it.schemaPath + it.util.getProperty($keyword);
        var $errSchemaPath = it.errSchemaPath + "/" + $keyword;
        var $breakOnError = !it.opts.allErrors;
        var $errorKeyword;
        var $data = "data" + ($dataLvl || "");
        var $isData = it.opts.$data && $schema && $schema.$data, $schemaValue;
        if ($isData) {
          out += " var schema" + $lvl + " = " + it.util.getData($schema.$data, $dataLvl, it.dataPathArr) + "; ";
          $schemaValue = "schema" + $lvl;
        } else {
          $schemaValue = $schema;
        }
        if (!($isData || typeof $schema == "number")) {
          throw new Error($keyword + " must be number");
        }
        var $op = $keyword == "maxLength" ? ">" : "<";
        out += "if ( ";
        if ($isData) {
          out += " (" + $schemaValue + " !== undefined && typeof " + $schemaValue + " != 'number') || ";
        }
        if (it.opts.unicode === false) {
          out += " " + $data + ".length ";
        } else {
          out += " ucs2length(" + $data + ") ";
        }
        out += " " + $op + " " + $schemaValue + ") { ";
        var $errorKeyword = $keyword;
        var $$outStack = $$outStack || [];
        $$outStack.push(out);
        out = "";
        if (it.createErrors !== false) {
          out += " { keyword: '" + ($errorKeyword || "_limitLength") + "' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { limit: " + $schemaValue + " } ";
          if (it.opts.messages !== false) {
            out += " , message: 'should NOT be ";
            if ($keyword == "maxLength") {
              out += "longer";
            } else {
              out += "shorter";
            }
            out += " than ";
            if ($isData) {
              out += "' + " + $schemaValue + " + '";
            } else {
              out += "" + $schema;
            }
            out += " characters' ";
          }
          if (it.opts.verbose) {
            out += " , schema:  ";
            if ($isData) {
              out += "validate.schema" + $schemaPath;
            } else {
              out += "" + $schema;
            }
            out += "         , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
          }
          out += " } ";
        } else {
          out += " {} ";
        }
        var __err = out;
        out = $$outStack.pop();
        if (!it.compositeRule && $breakOnError) {
          if (it.async) {
            out += " throw new ValidationError([" + __err + "]); ";
          } else {
            out += " validate.errors = [" + __err + "]; return false; ";
          }
        } else {
          out += " var err = " + __err + ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
        }
        out += "} ";
        if ($breakOnError) {
          out += " else { ";
        }
        return out;
      };
    }
  });

  // node_modules/ajv/lib/dotjs/_limitProperties.js
  var require_limitProperties = __commonJS({
    "node_modules/ajv/lib/dotjs/_limitProperties.js"(exports, module) {
      "use strict";
      module.exports = function generate__limitProperties(it, $keyword, $ruleType) {
        var out = " ";
        var $lvl = it.level;
        var $dataLvl = it.dataLevel;
        var $schema = it.schema[$keyword];
        var $schemaPath = it.schemaPath + it.util.getProperty($keyword);
        var $errSchemaPath = it.errSchemaPath + "/" + $keyword;
        var $breakOnError = !it.opts.allErrors;
        var $errorKeyword;
        var $data = "data" + ($dataLvl || "");
        var $isData = it.opts.$data && $schema && $schema.$data, $schemaValue;
        if ($isData) {
          out += " var schema" + $lvl + " = " + it.util.getData($schema.$data, $dataLvl, it.dataPathArr) + "; ";
          $schemaValue = "schema" + $lvl;
        } else {
          $schemaValue = $schema;
        }
        if (!($isData || typeof $schema == "number")) {
          throw new Error($keyword + " must be number");
        }
        var $op = $keyword == "maxProperties" ? ">" : "<";
        out += "if ( ";
        if ($isData) {
          out += " (" + $schemaValue + " !== undefined && typeof " + $schemaValue + " != 'number') || ";
        }
        out += " Object.keys(" + $data + ").length " + $op + " " + $schemaValue + ") { ";
        var $errorKeyword = $keyword;
        var $$outStack = $$outStack || [];
        $$outStack.push(out);
        out = "";
        if (it.createErrors !== false) {
          out += " { keyword: '" + ($errorKeyword || "_limitProperties") + "' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { limit: " + $schemaValue + " } ";
          if (it.opts.messages !== false) {
            out += " , message: 'should NOT have ";
            if ($keyword == "maxProperties") {
              out += "more";
            } else {
              out += "fewer";
            }
            out += " than ";
            if ($isData) {
              out += "' + " + $schemaValue + " + '";
            } else {
              out += "" + $schema;
            }
            out += " properties' ";
          }
          if (it.opts.verbose) {
            out += " , schema:  ";
            if ($isData) {
              out += "validate.schema" + $schemaPath;
            } else {
              out += "" + $schema;
            }
            out += "         , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
          }
          out += " } ";
        } else {
          out += " {} ";
        }
        var __err = out;
        out = $$outStack.pop();
        if (!it.compositeRule && $breakOnError) {
          if (it.async) {
            out += " throw new ValidationError([" + __err + "]); ";
          } else {
            out += " validate.errors = [" + __err + "]; return false; ";
          }
        } else {
          out += " var err = " + __err + ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
        }
        out += "} ";
        if ($breakOnError) {
          out += " else { ";
        }
        return out;
      };
    }
  });

  // node_modules/ajv/lib/dotjs/multipleOf.js
  var require_multipleOf = __commonJS({
    "node_modules/ajv/lib/dotjs/multipleOf.js"(exports, module) {
      "use strict";
      module.exports = function generate_multipleOf(it, $keyword, $ruleType) {
        var out = " ";
        var $lvl = it.level;
        var $dataLvl = it.dataLevel;
        var $schema = it.schema[$keyword];
        var $schemaPath = it.schemaPath + it.util.getProperty($keyword);
        var $errSchemaPath = it.errSchemaPath + "/" + $keyword;
        var $breakOnError = !it.opts.allErrors;
        var $data = "data" + ($dataLvl || "");
        var $isData = it.opts.$data && $schema && $schema.$data, $schemaValue;
        if ($isData) {
          out += " var schema" + $lvl + " = " + it.util.getData($schema.$data, $dataLvl, it.dataPathArr) + "; ";
          $schemaValue = "schema" + $lvl;
        } else {
          $schemaValue = $schema;
        }
        if (!($isData || typeof $schema == "number")) {
          throw new Error($keyword + " must be number");
        }
        out += "var division" + $lvl + ";if (";
        if ($isData) {
          out += " " + $schemaValue + " !== undefined && ( typeof " + $schemaValue + " != 'number' || ";
        }
        out += " (division" + $lvl + " = " + $data + " / " + $schemaValue + ", ";
        if (it.opts.multipleOfPrecision) {
          out += " Math.abs(Math.round(division" + $lvl + ") - division" + $lvl + ") > 1e-" + it.opts.multipleOfPrecision + " ";
        } else {
          out += " division" + $lvl + " !== parseInt(division" + $lvl + ") ";
        }
        out += " ) ";
        if ($isData) {
          out += "  )  ";
        }
        out += " ) {   ";
        var $$outStack = $$outStack || [];
        $$outStack.push(out);
        out = "";
        if (it.createErrors !== false) {
          out += " { keyword: 'multipleOf' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { multipleOf: " + $schemaValue + " } ";
          if (it.opts.messages !== false) {
            out += " , message: 'should be multiple of ";
            if ($isData) {
              out += "' + " + $schemaValue;
            } else {
              out += "" + $schemaValue + "'";
            }
          }
          if (it.opts.verbose) {
            out += " , schema:  ";
            if ($isData) {
              out += "validate.schema" + $schemaPath;
            } else {
              out += "" + $schema;
            }
            out += "         , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
          }
          out += " } ";
        } else {
          out += " {} ";
        }
        var __err = out;
        out = $$outStack.pop();
        if (!it.compositeRule && $breakOnError) {
          if (it.async) {
            out += " throw new ValidationError([" + __err + "]); ";
          } else {
            out += " validate.errors = [" + __err + "]; return false; ";
          }
        } else {
          out += " var err = " + __err + ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
        }
        out += "} ";
        if ($breakOnError) {
          out += " else { ";
        }
        return out;
      };
    }
  });

  // node_modules/ajv/lib/dotjs/not.js
  var require_not = __commonJS({
    "node_modules/ajv/lib/dotjs/not.js"(exports, module) {
      "use strict";
      module.exports = function generate_not(it, $keyword, $ruleType) {
        var out = " ";
        var $lvl = it.level;
        var $dataLvl = it.dataLevel;
        var $schema = it.schema[$keyword];
        var $schemaPath = it.schemaPath + it.util.getProperty($keyword);
        var $errSchemaPath = it.errSchemaPath + "/" + $keyword;
        var $breakOnError = !it.opts.allErrors;
        var $data = "data" + ($dataLvl || "");
        var $errs = "errs__" + $lvl;
        var $it = it.util.copy(it);
        $it.level++;
        var $nextValid = "valid" + $it.level;
        if (it.opts.strictKeywords ? typeof $schema == "object" && Object.keys($schema).length > 0 || $schema === false : it.util.schemaHasRules($schema, it.RULES.all)) {
          $it.schema = $schema;
          $it.schemaPath = $schemaPath;
          $it.errSchemaPath = $errSchemaPath;
          out += " var " + $errs + " = errors;  ";
          var $wasComposite = it.compositeRule;
          it.compositeRule = $it.compositeRule = true;
          $it.createErrors = false;
          var $allErrorsOption;
          if ($it.opts.allErrors) {
            $allErrorsOption = $it.opts.allErrors;
            $it.opts.allErrors = false;
          }
          out += " " + it.validate($it) + " ";
          $it.createErrors = true;
          if ($allErrorsOption)
            $it.opts.allErrors = $allErrorsOption;
          it.compositeRule = $it.compositeRule = $wasComposite;
          out += " if (" + $nextValid + ") {   ";
          var $$outStack = $$outStack || [];
          $$outStack.push(out);
          out = "";
          if (it.createErrors !== false) {
            out += " { keyword: 'not' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: {} ";
            if (it.opts.messages !== false) {
              out += " , message: 'should NOT be valid' ";
            }
            if (it.opts.verbose) {
              out += " , schema: validate.schema" + $schemaPath + " , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
            }
            out += " } ";
          } else {
            out += " {} ";
          }
          var __err = out;
          out = $$outStack.pop();
          if (!it.compositeRule && $breakOnError) {
            if (it.async) {
              out += " throw new ValidationError([" + __err + "]); ";
            } else {
              out += " validate.errors = [" + __err + "]; return false; ";
            }
          } else {
            out += " var err = " + __err + ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
          }
          out += " } else {  errors = " + $errs + "; if (vErrors !== null) { if (" + $errs + ") vErrors.length = " + $errs + "; else vErrors = null; } ";
          if (it.opts.allErrors) {
            out += " } ";
          }
        } else {
          out += "  var err =   ";
          if (it.createErrors !== false) {
            out += " { keyword: 'not' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: {} ";
            if (it.opts.messages !== false) {
              out += " , message: 'should NOT be valid' ";
            }
            if (it.opts.verbose) {
              out += " , schema: validate.schema" + $schemaPath + " , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
            }
            out += " } ";
          } else {
            out += " {} ";
          }
          out += ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
          if ($breakOnError) {
            out += " if (false) { ";
          }
        }
        return out;
      };
    }
  });

  // node_modules/ajv/lib/dotjs/oneOf.js
  var require_oneOf = __commonJS({
    "node_modules/ajv/lib/dotjs/oneOf.js"(exports, module) {
      "use strict";
      module.exports = function generate_oneOf(it, $keyword, $ruleType) {
        var out = " ";
        var $lvl = it.level;
        var $dataLvl = it.dataLevel;
        var $schema = it.schema[$keyword];
        var $schemaPath = it.schemaPath + it.util.getProperty($keyword);
        var $errSchemaPath = it.errSchemaPath + "/" + $keyword;
        var $breakOnError = !it.opts.allErrors;
        var $data = "data" + ($dataLvl || "");
        var $valid = "valid" + $lvl;
        var $errs = "errs__" + $lvl;
        var $it = it.util.copy(it);
        var $closingBraces = "";
        $it.level++;
        var $nextValid = "valid" + $it.level;
        var $currentBaseId = $it.baseId, $prevValid = "prevValid" + $lvl, $passingSchemas = "passingSchemas" + $lvl;
        out += "var " + $errs + " = errors , " + $prevValid + " = false , " + $valid + " = false , " + $passingSchemas + " = null; ";
        var $wasComposite = it.compositeRule;
        it.compositeRule = $it.compositeRule = true;
        var arr1 = $schema;
        if (arr1) {
          var $sch, $i = -1, l1 = arr1.length - 1;
          while ($i < l1) {
            $sch = arr1[$i += 1];
            if (it.opts.strictKeywords ? typeof $sch == "object" && Object.keys($sch).length > 0 || $sch === false : it.util.schemaHasRules($sch, it.RULES.all)) {
              $it.schema = $sch;
              $it.schemaPath = $schemaPath + "[" + $i + "]";
              $it.errSchemaPath = $errSchemaPath + "/" + $i;
              out += "  " + it.validate($it) + " ";
              $it.baseId = $currentBaseId;
            } else {
              out += " var " + $nextValid + " = true; ";
            }
            if ($i) {
              out += " if (" + $nextValid + " && " + $prevValid + ") { " + $valid + " = false; " + $passingSchemas + " = [" + $passingSchemas + ", " + $i + "]; } else { ";
              $closingBraces += "}";
            }
            out += " if (" + $nextValid + ") { " + $valid + " = " + $prevValid + " = true; " + $passingSchemas + " = " + $i + "; }";
          }
        }
        it.compositeRule = $it.compositeRule = $wasComposite;
        out += "" + $closingBraces + "if (!" + $valid + ") {   var err =   ";
        if (it.createErrors !== false) {
          out += " { keyword: 'oneOf' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { passingSchemas: " + $passingSchemas + " } ";
          if (it.opts.messages !== false) {
            out += " , message: 'should match exactly one schema in oneOf' ";
          }
          if (it.opts.verbose) {
            out += " , schema: validate.schema" + $schemaPath + " , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
          }
          out += " } ";
        } else {
          out += " {} ";
        }
        out += ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
        if (!it.compositeRule && $breakOnError) {
          if (it.async) {
            out += " throw new ValidationError(vErrors); ";
          } else {
            out += " validate.errors = vErrors; return false; ";
          }
        }
        out += "} else {  errors = " + $errs + "; if (vErrors !== null) { if (" + $errs + ") vErrors.length = " + $errs + "; else vErrors = null; }";
        if (it.opts.allErrors) {
          out += " } ";
        }
        return out;
      };
    }
  });

  // node_modules/ajv/lib/dotjs/pattern.js
  var require_pattern = __commonJS({
    "node_modules/ajv/lib/dotjs/pattern.js"(exports, module) {
      "use strict";
      module.exports = function generate_pattern(it, $keyword, $ruleType) {
        var out = " ";
        var $lvl = it.level;
        var $dataLvl = it.dataLevel;
        var $schema = it.schema[$keyword];
        var $schemaPath = it.schemaPath + it.util.getProperty($keyword);
        var $errSchemaPath = it.errSchemaPath + "/" + $keyword;
        var $breakOnError = !it.opts.allErrors;
        var $data = "data" + ($dataLvl || "");
        var $isData = it.opts.$data && $schema && $schema.$data, $schemaValue;
        if ($isData) {
          out += " var schema" + $lvl + " = " + it.util.getData($schema.$data, $dataLvl, it.dataPathArr) + "; ";
          $schemaValue = "schema" + $lvl;
        } else {
          $schemaValue = $schema;
        }
        var $regexp = $isData ? "(new RegExp(" + $schemaValue + "))" : it.usePattern($schema);
        out += "if ( ";
        if ($isData) {
          out += " (" + $schemaValue + " !== undefined && typeof " + $schemaValue + " != 'string') || ";
        }
        out += " !" + $regexp + ".test(" + $data + ") ) {   ";
        var $$outStack = $$outStack || [];
        $$outStack.push(out);
        out = "";
        if (it.createErrors !== false) {
          out += " { keyword: 'pattern' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { pattern:  ";
          if ($isData) {
            out += "" + $schemaValue;
          } else {
            out += "" + it.util.toQuotedString($schema);
          }
          out += "  } ";
          if (it.opts.messages !== false) {
            out += ` , message: 'should match pattern "`;
            if ($isData) {
              out += "' + " + $schemaValue + " + '";
            } else {
              out += "" + it.util.escapeQuotes($schema);
            }
            out += `"' `;
          }
          if (it.opts.verbose) {
            out += " , schema:  ";
            if ($isData) {
              out += "validate.schema" + $schemaPath;
            } else {
              out += "" + it.util.toQuotedString($schema);
            }
            out += "         , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
          }
          out += " } ";
        } else {
          out += " {} ";
        }
        var __err = out;
        out = $$outStack.pop();
        if (!it.compositeRule && $breakOnError) {
          if (it.async) {
            out += " throw new ValidationError([" + __err + "]); ";
          } else {
            out += " validate.errors = [" + __err + "]; return false; ";
          }
        } else {
          out += " var err = " + __err + ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
        }
        out += "} ";
        if ($breakOnError) {
          out += " else { ";
        }
        return out;
      };
    }
  });

  // node_modules/ajv/lib/dotjs/properties.js
  var require_properties = __commonJS({
    "node_modules/ajv/lib/dotjs/properties.js"(exports, module) {
      "use strict";
      module.exports = function generate_properties(it, $keyword, $ruleType) {
        var out = " ";
        var $lvl = it.level;
        var $dataLvl = it.dataLevel;
        var $schema = it.schema[$keyword];
        var $schemaPath = it.schemaPath + it.util.getProperty($keyword);
        var $errSchemaPath = it.errSchemaPath + "/" + $keyword;
        var $breakOnError = !it.opts.allErrors;
        var $data = "data" + ($dataLvl || "");
        var $errs = "errs__" + $lvl;
        var $it = it.util.copy(it);
        var $closingBraces = "";
        $it.level++;
        var $nextValid = "valid" + $it.level;
        var $key = "key" + $lvl, $idx = "idx" + $lvl, $dataNxt = $it.dataLevel = it.dataLevel + 1, $nextData = "data" + $dataNxt, $dataProperties = "dataProperties" + $lvl;
        var $schemaKeys = Object.keys($schema || {}).filter(notProto), $pProperties = it.schema.patternProperties || {}, $pPropertyKeys = Object.keys($pProperties).filter(notProto), $aProperties = it.schema.additionalProperties, $someProperties = $schemaKeys.length || $pPropertyKeys.length, $noAdditional = $aProperties === false, $additionalIsSchema = typeof $aProperties == "object" && Object.keys($aProperties).length, $removeAdditional = it.opts.removeAdditional, $checkAdditional = $noAdditional || $additionalIsSchema || $removeAdditional, $ownProperties = it.opts.ownProperties, $currentBaseId = it.baseId;
        var $required = it.schema.required;
        if ($required && !(it.opts.$data && $required.$data) && $required.length < it.opts.loopRequired) {
          var $requiredHash = it.util.toHash($required);
        }
        function notProto(p) {
          return p !== "__proto__";
        }
        out += "var " + $errs + " = errors;var " + $nextValid + " = true;";
        if ($ownProperties) {
          out += " var " + $dataProperties + " = undefined;";
        }
        if ($checkAdditional) {
          if ($ownProperties) {
            out += " " + $dataProperties + " = " + $dataProperties + " || Object.keys(" + $data + "); for (var " + $idx + "=0; " + $idx + "<" + $dataProperties + ".length; " + $idx + "++) { var " + $key + " = " + $dataProperties + "[" + $idx + "]; ";
          } else {
            out += " for (var " + $key + " in " + $data + ") { ";
          }
          if ($someProperties) {
            out += " var isAdditional" + $lvl + " = !(false ";
            if ($schemaKeys.length) {
              if ($schemaKeys.length > 8) {
                out += " || validate.schema" + $schemaPath + ".hasOwnProperty(" + $key + ") ";
              } else {
                var arr1 = $schemaKeys;
                if (arr1) {
                  var $propertyKey, i1 = -1, l1 = arr1.length - 1;
                  while (i1 < l1) {
                    $propertyKey = arr1[i1 += 1];
                    out += " || " + $key + " == " + it.util.toQuotedString($propertyKey) + " ";
                  }
                }
              }
            }
            if ($pPropertyKeys.length) {
              var arr2 = $pPropertyKeys;
              if (arr2) {
                var $pProperty, $i = -1, l2 = arr2.length - 1;
                while ($i < l2) {
                  $pProperty = arr2[$i += 1];
                  out += " || " + it.usePattern($pProperty) + ".test(" + $key + ") ";
                }
              }
            }
            out += " ); if (isAdditional" + $lvl + ") { ";
          }
          if ($removeAdditional == "all") {
            out += " delete " + $data + "[" + $key + "]; ";
          } else {
            var $currentErrorPath = it.errorPath;
            var $additionalProperty = "' + " + $key + " + '";
            if (it.opts._errorDataPathProperty) {
              it.errorPath = it.util.getPathExpr(it.errorPath, $key, it.opts.jsonPointers);
            }
            if ($noAdditional) {
              if ($removeAdditional) {
                out += " delete " + $data + "[" + $key + "]; ";
              } else {
                out += " " + $nextValid + " = false; ";
                var $currErrSchemaPath = $errSchemaPath;
                $errSchemaPath = it.errSchemaPath + "/additionalProperties";
                var $$outStack = $$outStack || [];
                $$outStack.push(out);
                out = "";
                if (it.createErrors !== false) {
                  out += " { keyword: 'additionalProperties' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { additionalProperty: '" + $additionalProperty + "' } ";
                  if (it.opts.messages !== false) {
                    out += " , message: '";
                    if (it.opts._errorDataPathProperty) {
                      out += "is an invalid additional property";
                    } else {
                      out += "should NOT have additional properties";
                    }
                    out += "' ";
                  }
                  if (it.opts.verbose) {
                    out += " , schema: false , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
                  }
                  out += " } ";
                } else {
                  out += " {} ";
                }
                var __err = out;
                out = $$outStack.pop();
                if (!it.compositeRule && $breakOnError) {
                  if (it.async) {
                    out += " throw new ValidationError([" + __err + "]); ";
                  } else {
                    out += " validate.errors = [" + __err + "]; return false; ";
                  }
                } else {
                  out += " var err = " + __err + ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
                }
                $errSchemaPath = $currErrSchemaPath;
                if ($breakOnError) {
                  out += " break; ";
                }
              }
            } else if ($additionalIsSchema) {
              if ($removeAdditional == "failing") {
                out += " var " + $errs + " = errors;  ";
                var $wasComposite = it.compositeRule;
                it.compositeRule = $it.compositeRule = true;
                $it.schema = $aProperties;
                $it.schemaPath = it.schemaPath + ".additionalProperties";
                $it.errSchemaPath = it.errSchemaPath + "/additionalProperties";
                $it.errorPath = it.opts._errorDataPathProperty ? it.errorPath : it.util.getPathExpr(it.errorPath, $key, it.opts.jsonPointers);
                var $passData = $data + "[" + $key + "]";
                $it.dataPathArr[$dataNxt] = $key;
                var $code = it.validate($it);
                $it.baseId = $currentBaseId;
                if (it.util.varOccurences($code, $nextData) < 2) {
                  out += " " + it.util.varReplace($code, $nextData, $passData) + " ";
                } else {
                  out += " var " + $nextData + " = " + $passData + "; " + $code + " ";
                }
                out += " if (!" + $nextValid + ") { errors = " + $errs + "; if (validate.errors !== null) { if (errors) validate.errors.length = errors; else validate.errors = null; } delete " + $data + "[" + $key + "]; }  ";
                it.compositeRule = $it.compositeRule = $wasComposite;
              } else {
                $it.schema = $aProperties;
                $it.schemaPath = it.schemaPath + ".additionalProperties";
                $it.errSchemaPath = it.errSchemaPath + "/additionalProperties";
                $it.errorPath = it.opts._errorDataPathProperty ? it.errorPath : it.util.getPathExpr(it.errorPath, $key, it.opts.jsonPointers);
                var $passData = $data + "[" + $key + "]";
                $it.dataPathArr[$dataNxt] = $key;
                var $code = it.validate($it);
                $it.baseId = $currentBaseId;
                if (it.util.varOccurences($code, $nextData) < 2) {
                  out += " " + it.util.varReplace($code, $nextData, $passData) + " ";
                } else {
                  out += " var " + $nextData + " = " + $passData + "; " + $code + " ";
                }
                if ($breakOnError) {
                  out += " if (!" + $nextValid + ") break; ";
                }
              }
            }
            it.errorPath = $currentErrorPath;
          }
          if ($someProperties) {
            out += " } ";
          }
          out += " }  ";
          if ($breakOnError) {
            out += " if (" + $nextValid + ") { ";
            $closingBraces += "}";
          }
        }
        var $useDefaults = it.opts.useDefaults && !it.compositeRule;
        if ($schemaKeys.length) {
          var arr3 = $schemaKeys;
          if (arr3) {
            var $propertyKey, i3 = -1, l3 = arr3.length - 1;
            while (i3 < l3) {
              $propertyKey = arr3[i3 += 1];
              var $sch = $schema[$propertyKey];
              if (it.opts.strictKeywords ? typeof $sch == "object" && Object.keys($sch).length > 0 || $sch === false : it.util.schemaHasRules($sch, it.RULES.all)) {
                var $prop = it.util.getProperty($propertyKey), $passData = $data + $prop, $hasDefault = $useDefaults && $sch.default !== void 0;
                $it.schema = $sch;
                $it.schemaPath = $schemaPath + $prop;
                $it.errSchemaPath = $errSchemaPath + "/" + it.util.escapeFragment($propertyKey);
                $it.errorPath = it.util.getPath(it.errorPath, $propertyKey, it.opts.jsonPointers);
                $it.dataPathArr[$dataNxt] = it.util.toQuotedString($propertyKey);
                var $code = it.validate($it);
                $it.baseId = $currentBaseId;
                if (it.util.varOccurences($code, $nextData) < 2) {
                  $code = it.util.varReplace($code, $nextData, $passData);
                  var $useData = $passData;
                } else {
                  var $useData = $nextData;
                  out += " var " + $nextData + " = " + $passData + "; ";
                }
                if ($hasDefault) {
                  out += " " + $code + " ";
                } else {
                  if ($requiredHash && $requiredHash[$propertyKey]) {
                    out += " if ( " + $useData + " === undefined ";
                    if ($ownProperties) {
                      out += " || ! Object.prototype.hasOwnProperty.call(" + $data + ", '" + it.util.escapeQuotes($propertyKey) + "') ";
                    }
                    out += ") { " + $nextValid + " = false; ";
                    var $currentErrorPath = it.errorPath, $currErrSchemaPath = $errSchemaPath, $missingProperty = it.util.escapeQuotes($propertyKey);
                    if (it.opts._errorDataPathProperty) {
                      it.errorPath = it.util.getPath($currentErrorPath, $propertyKey, it.opts.jsonPointers);
                    }
                    $errSchemaPath = it.errSchemaPath + "/required";
                    var $$outStack = $$outStack || [];
                    $$outStack.push(out);
                    out = "";
                    if (it.createErrors !== false) {
                      out += " { keyword: 'required' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { missingProperty: '" + $missingProperty + "' } ";
                      if (it.opts.messages !== false) {
                        out += " , message: '";
                        if (it.opts._errorDataPathProperty) {
                          out += "is a required property";
                        } else {
                          out += "should have required property \\'" + $missingProperty + "\\'";
                        }
                        out += "' ";
                      }
                      if (it.opts.verbose) {
                        out += " , schema: validate.schema" + $schemaPath + " , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
                      }
                      out += " } ";
                    } else {
                      out += " {} ";
                    }
                    var __err = out;
                    out = $$outStack.pop();
                    if (!it.compositeRule && $breakOnError) {
                      if (it.async) {
                        out += " throw new ValidationError([" + __err + "]); ";
                      } else {
                        out += " validate.errors = [" + __err + "]; return false; ";
                      }
                    } else {
                      out += " var err = " + __err + ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
                    }
                    $errSchemaPath = $currErrSchemaPath;
                    it.errorPath = $currentErrorPath;
                    out += " } else { ";
                  } else {
                    if ($breakOnError) {
                      out += " if ( " + $useData + " === undefined ";
                      if ($ownProperties) {
                        out += " || ! Object.prototype.hasOwnProperty.call(" + $data + ", '" + it.util.escapeQuotes($propertyKey) + "') ";
                      }
                      out += ") { " + $nextValid + " = true; } else { ";
                    } else {
                      out += " if (" + $useData + " !== undefined ";
                      if ($ownProperties) {
                        out += " &&   Object.prototype.hasOwnProperty.call(" + $data + ", '" + it.util.escapeQuotes($propertyKey) + "') ";
                      }
                      out += " ) { ";
                    }
                  }
                  out += " " + $code + " } ";
                }
              }
              if ($breakOnError) {
                out += " if (" + $nextValid + ") { ";
                $closingBraces += "}";
              }
            }
          }
        }
        if ($pPropertyKeys.length) {
          var arr4 = $pPropertyKeys;
          if (arr4) {
            var $pProperty, i4 = -1, l4 = arr4.length - 1;
            while (i4 < l4) {
              $pProperty = arr4[i4 += 1];
              var $sch = $pProperties[$pProperty];
              if (it.opts.strictKeywords ? typeof $sch == "object" && Object.keys($sch).length > 0 || $sch === false : it.util.schemaHasRules($sch, it.RULES.all)) {
                $it.schema = $sch;
                $it.schemaPath = it.schemaPath + ".patternProperties" + it.util.getProperty($pProperty);
                $it.errSchemaPath = it.errSchemaPath + "/patternProperties/" + it.util.escapeFragment($pProperty);
                if ($ownProperties) {
                  out += " " + $dataProperties + " = " + $dataProperties + " || Object.keys(" + $data + "); for (var " + $idx + "=0; " + $idx + "<" + $dataProperties + ".length; " + $idx + "++) { var " + $key + " = " + $dataProperties + "[" + $idx + "]; ";
                } else {
                  out += " for (var " + $key + " in " + $data + ") { ";
                }
                out += " if (" + it.usePattern($pProperty) + ".test(" + $key + ")) { ";
                $it.errorPath = it.util.getPathExpr(it.errorPath, $key, it.opts.jsonPointers);
                var $passData = $data + "[" + $key + "]";
                $it.dataPathArr[$dataNxt] = $key;
                var $code = it.validate($it);
                $it.baseId = $currentBaseId;
                if (it.util.varOccurences($code, $nextData) < 2) {
                  out += " " + it.util.varReplace($code, $nextData, $passData) + " ";
                } else {
                  out += " var " + $nextData + " = " + $passData + "; " + $code + " ";
                }
                if ($breakOnError) {
                  out += " if (!" + $nextValid + ") break; ";
                }
                out += " } ";
                if ($breakOnError) {
                  out += " else " + $nextValid + " = true; ";
                }
                out += " }  ";
                if ($breakOnError) {
                  out += " if (" + $nextValid + ") { ";
                  $closingBraces += "}";
                }
              }
            }
          }
        }
        if ($breakOnError) {
          out += " " + $closingBraces + " if (" + $errs + " == errors) {";
        }
        return out;
      };
    }
  });

  // node_modules/ajv/lib/dotjs/propertyNames.js
  var require_propertyNames = __commonJS({
    "node_modules/ajv/lib/dotjs/propertyNames.js"(exports, module) {
      "use strict";
      module.exports = function generate_propertyNames(it, $keyword, $ruleType) {
        var out = " ";
        var $lvl = it.level;
        var $dataLvl = it.dataLevel;
        var $schema = it.schema[$keyword];
        var $schemaPath = it.schemaPath + it.util.getProperty($keyword);
        var $errSchemaPath = it.errSchemaPath + "/" + $keyword;
        var $breakOnError = !it.opts.allErrors;
        var $data = "data" + ($dataLvl || "");
        var $errs = "errs__" + $lvl;
        var $it = it.util.copy(it);
        var $closingBraces = "";
        $it.level++;
        var $nextValid = "valid" + $it.level;
        out += "var " + $errs + " = errors;";
        if (it.opts.strictKeywords ? typeof $schema == "object" && Object.keys($schema).length > 0 || $schema === false : it.util.schemaHasRules($schema, it.RULES.all)) {
          $it.schema = $schema;
          $it.schemaPath = $schemaPath;
          $it.errSchemaPath = $errSchemaPath;
          var $key = "key" + $lvl, $idx = "idx" + $lvl, $i = "i" + $lvl, $invalidName = "' + " + $key + " + '", $dataNxt = $it.dataLevel = it.dataLevel + 1, $nextData = "data" + $dataNxt, $dataProperties = "dataProperties" + $lvl, $ownProperties = it.opts.ownProperties, $currentBaseId = it.baseId;
          if ($ownProperties) {
            out += " var " + $dataProperties + " = undefined; ";
          }
          if ($ownProperties) {
            out += " " + $dataProperties + " = " + $dataProperties + " || Object.keys(" + $data + "); for (var " + $idx + "=0; " + $idx + "<" + $dataProperties + ".length; " + $idx + "++) { var " + $key + " = " + $dataProperties + "[" + $idx + "]; ";
          } else {
            out += " for (var " + $key + " in " + $data + ") { ";
          }
          out += " var startErrs" + $lvl + " = errors; ";
          var $passData = $key;
          var $wasComposite = it.compositeRule;
          it.compositeRule = $it.compositeRule = true;
          var $code = it.validate($it);
          $it.baseId = $currentBaseId;
          if (it.util.varOccurences($code, $nextData) < 2) {
            out += " " + it.util.varReplace($code, $nextData, $passData) + " ";
          } else {
            out += " var " + $nextData + " = " + $passData + "; " + $code + " ";
          }
          it.compositeRule = $it.compositeRule = $wasComposite;
          out += " if (!" + $nextValid + ") { for (var " + $i + "=startErrs" + $lvl + "; " + $i + "<errors; " + $i + "++) { vErrors[" + $i + "].propertyName = " + $key + "; }   var err =   ";
          if (it.createErrors !== false) {
            out += " { keyword: 'propertyNames' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { propertyName: '" + $invalidName + "' } ";
            if (it.opts.messages !== false) {
              out += " , message: 'property name \\'" + $invalidName + "\\' is invalid' ";
            }
            if (it.opts.verbose) {
              out += " , schema: validate.schema" + $schemaPath + " , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
            }
            out += " } ";
          } else {
            out += " {} ";
          }
          out += ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
          if (!it.compositeRule && $breakOnError) {
            if (it.async) {
              out += " throw new ValidationError(vErrors); ";
            } else {
              out += " validate.errors = vErrors; return false; ";
            }
          }
          if ($breakOnError) {
            out += " break; ";
          }
          out += " } }";
        }
        if ($breakOnError) {
          out += " " + $closingBraces + " if (" + $errs + " == errors) {";
        }
        return out;
      };
    }
  });

  // node_modules/ajv/lib/dotjs/required.js
  var require_required = __commonJS({
    "node_modules/ajv/lib/dotjs/required.js"(exports, module) {
      "use strict";
      module.exports = function generate_required(it, $keyword, $ruleType) {
        var out = " ";
        var $lvl = it.level;
        var $dataLvl = it.dataLevel;
        var $schema = it.schema[$keyword];
        var $schemaPath = it.schemaPath + it.util.getProperty($keyword);
        var $errSchemaPath = it.errSchemaPath + "/" + $keyword;
        var $breakOnError = !it.opts.allErrors;
        var $data = "data" + ($dataLvl || "");
        var $valid = "valid" + $lvl;
        var $isData = it.opts.$data && $schema && $schema.$data, $schemaValue;
        if ($isData) {
          out += " var schema" + $lvl + " = " + it.util.getData($schema.$data, $dataLvl, it.dataPathArr) + "; ";
          $schemaValue = "schema" + $lvl;
        } else {
          $schemaValue = $schema;
        }
        var $vSchema = "schema" + $lvl;
        if (!$isData) {
          if ($schema.length < it.opts.loopRequired && it.schema.properties && Object.keys(it.schema.properties).length) {
            var $required = [];
            var arr1 = $schema;
            if (arr1) {
              var $property, i1 = -1, l1 = arr1.length - 1;
              while (i1 < l1) {
                $property = arr1[i1 += 1];
                var $propertySch = it.schema.properties[$property];
                if (!($propertySch && (it.opts.strictKeywords ? typeof $propertySch == "object" && Object.keys($propertySch).length > 0 || $propertySch === false : it.util.schemaHasRules($propertySch, it.RULES.all)))) {
                  $required[$required.length] = $property;
                }
              }
            }
          } else {
            var $required = $schema;
          }
        }
        if ($isData || $required.length) {
          var $currentErrorPath = it.errorPath, $loopRequired = $isData || $required.length >= it.opts.loopRequired, $ownProperties = it.opts.ownProperties;
          if ($breakOnError) {
            out += " var missing" + $lvl + "; ";
            if ($loopRequired) {
              if (!$isData) {
                out += " var " + $vSchema + " = validate.schema" + $schemaPath + "; ";
              }
              var $i = "i" + $lvl, $propertyPath = "schema" + $lvl + "[" + $i + "]", $missingProperty = "' + " + $propertyPath + " + '";
              if (it.opts._errorDataPathProperty) {
                it.errorPath = it.util.getPathExpr($currentErrorPath, $propertyPath, it.opts.jsonPointers);
              }
              out += " var " + $valid + " = true; ";
              if ($isData) {
                out += " if (schema" + $lvl + " === undefined) " + $valid + " = true; else if (!Array.isArray(schema" + $lvl + ")) " + $valid + " = false; else {";
              }
              out += " for (var " + $i + " = 0; " + $i + " < " + $vSchema + ".length; " + $i + "++) { " + $valid + " = " + $data + "[" + $vSchema + "[" + $i + "]] !== undefined ";
              if ($ownProperties) {
                out += " &&   Object.prototype.hasOwnProperty.call(" + $data + ", " + $vSchema + "[" + $i + "]) ";
              }
              out += "; if (!" + $valid + ") break; } ";
              if ($isData) {
                out += "  }  ";
              }
              out += "  if (!" + $valid + ") {   ";
              var $$outStack = $$outStack || [];
              $$outStack.push(out);
              out = "";
              if (it.createErrors !== false) {
                out += " { keyword: 'required' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { missingProperty: '" + $missingProperty + "' } ";
                if (it.opts.messages !== false) {
                  out += " , message: '";
                  if (it.opts._errorDataPathProperty) {
                    out += "is a required property";
                  } else {
                    out += "should have required property \\'" + $missingProperty + "\\'";
                  }
                  out += "' ";
                }
                if (it.opts.verbose) {
                  out += " , schema: validate.schema" + $schemaPath + " , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
                }
                out += " } ";
              } else {
                out += " {} ";
              }
              var __err = out;
              out = $$outStack.pop();
              if (!it.compositeRule && $breakOnError) {
                if (it.async) {
                  out += " throw new ValidationError([" + __err + "]); ";
                } else {
                  out += " validate.errors = [" + __err + "]; return false; ";
                }
              } else {
                out += " var err = " + __err + ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
              }
              out += " } else { ";
            } else {
              out += " if ( ";
              var arr2 = $required;
              if (arr2) {
                var $propertyKey, $i = -1, l2 = arr2.length - 1;
                while ($i < l2) {
                  $propertyKey = arr2[$i += 1];
                  if ($i) {
                    out += " || ";
                  }
                  var $prop = it.util.getProperty($propertyKey), $useData = $data + $prop;
                  out += " ( ( " + $useData + " === undefined ";
                  if ($ownProperties) {
                    out += " || ! Object.prototype.hasOwnProperty.call(" + $data + ", '" + it.util.escapeQuotes($propertyKey) + "') ";
                  }
                  out += ") && (missing" + $lvl + " = " + it.util.toQuotedString(it.opts.jsonPointers ? $propertyKey : $prop) + ") ) ";
                }
              }
              out += ") {  ";
              var $propertyPath = "missing" + $lvl, $missingProperty = "' + " + $propertyPath + " + '";
              if (it.opts._errorDataPathProperty) {
                it.errorPath = it.opts.jsonPointers ? it.util.getPathExpr($currentErrorPath, $propertyPath, true) : $currentErrorPath + " + " + $propertyPath;
              }
              var $$outStack = $$outStack || [];
              $$outStack.push(out);
              out = "";
              if (it.createErrors !== false) {
                out += " { keyword: 'required' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { missingProperty: '" + $missingProperty + "' } ";
                if (it.opts.messages !== false) {
                  out += " , message: '";
                  if (it.opts._errorDataPathProperty) {
                    out += "is a required property";
                  } else {
                    out += "should have required property \\'" + $missingProperty + "\\'";
                  }
                  out += "' ";
                }
                if (it.opts.verbose) {
                  out += " , schema: validate.schema" + $schemaPath + " , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
                }
                out += " } ";
              } else {
                out += " {} ";
              }
              var __err = out;
              out = $$outStack.pop();
              if (!it.compositeRule && $breakOnError) {
                if (it.async) {
                  out += " throw new ValidationError([" + __err + "]); ";
                } else {
                  out += " validate.errors = [" + __err + "]; return false; ";
                }
              } else {
                out += " var err = " + __err + ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
              }
              out += " } else { ";
            }
          } else {
            if ($loopRequired) {
              if (!$isData) {
                out += " var " + $vSchema + " = validate.schema" + $schemaPath + "; ";
              }
              var $i = "i" + $lvl, $propertyPath = "schema" + $lvl + "[" + $i + "]", $missingProperty = "' + " + $propertyPath + " + '";
              if (it.opts._errorDataPathProperty) {
                it.errorPath = it.util.getPathExpr($currentErrorPath, $propertyPath, it.opts.jsonPointers);
              }
              if ($isData) {
                out += " if (" + $vSchema + " && !Array.isArray(" + $vSchema + ")) {  var err =   ";
                if (it.createErrors !== false) {
                  out += " { keyword: 'required' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { missingProperty: '" + $missingProperty + "' } ";
                  if (it.opts.messages !== false) {
                    out += " , message: '";
                    if (it.opts._errorDataPathProperty) {
                      out += "is a required property";
                    } else {
                      out += "should have required property \\'" + $missingProperty + "\\'";
                    }
                    out += "' ";
                  }
                  if (it.opts.verbose) {
                    out += " , schema: validate.schema" + $schemaPath + " , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
                  }
                  out += " } ";
                } else {
                  out += " {} ";
                }
                out += ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; } else if (" + $vSchema + " !== undefined) { ";
              }
              out += " for (var " + $i + " = 0; " + $i + " < " + $vSchema + ".length; " + $i + "++) { if (" + $data + "[" + $vSchema + "[" + $i + "]] === undefined ";
              if ($ownProperties) {
                out += " || ! Object.prototype.hasOwnProperty.call(" + $data + ", " + $vSchema + "[" + $i + "]) ";
              }
              out += ") {  var err =   ";
              if (it.createErrors !== false) {
                out += " { keyword: 'required' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { missingProperty: '" + $missingProperty + "' } ";
                if (it.opts.messages !== false) {
                  out += " , message: '";
                  if (it.opts._errorDataPathProperty) {
                    out += "is a required property";
                  } else {
                    out += "should have required property \\'" + $missingProperty + "\\'";
                  }
                  out += "' ";
                }
                if (it.opts.verbose) {
                  out += " , schema: validate.schema" + $schemaPath + " , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
                }
                out += " } ";
              } else {
                out += " {} ";
              }
              out += ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; } } ";
              if ($isData) {
                out += "  }  ";
              }
            } else {
              var arr3 = $required;
              if (arr3) {
                var $propertyKey, i3 = -1, l3 = arr3.length - 1;
                while (i3 < l3) {
                  $propertyKey = arr3[i3 += 1];
                  var $prop = it.util.getProperty($propertyKey), $missingProperty = it.util.escapeQuotes($propertyKey), $useData = $data + $prop;
                  if (it.opts._errorDataPathProperty) {
                    it.errorPath = it.util.getPath($currentErrorPath, $propertyKey, it.opts.jsonPointers);
                  }
                  out += " if ( " + $useData + " === undefined ";
                  if ($ownProperties) {
                    out += " || ! Object.prototype.hasOwnProperty.call(" + $data + ", '" + it.util.escapeQuotes($propertyKey) + "') ";
                  }
                  out += ") {  var err =   ";
                  if (it.createErrors !== false) {
                    out += " { keyword: 'required' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { missingProperty: '" + $missingProperty + "' } ";
                    if (it.opts.messages !== false) {
                      out += " , message: '";
                      if (it.opts._errorDataPathProperty) {
                        out += "is a required property";
                      } else {
                        out += "should have required property \\'" + $missingProperty + "\\'";
                      }
                      out += "' ";
                    }
                    if (it.opts.verbose) {
                      out += " , schema: validate.schema" + $schemaPath + " , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
                    }
                    out += " } ";
                  } else {
                    out += " {} ";
                  }
                  out += ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; } ";
                }
              }
            }
          }
          it.errorPath = $currentErrorPath;
        } else if ($breakOnError) {
          out += " if (true) {";
        }
        return out;
      };
    }
  });

  // node_modules/ajv/lib/dotjs/uniqueItems.js
  var require_uniqueItems = __commonJS({
    "node_modules/ajv/lib/dotjs/uniqueItems.js"(exports, module) {
      "use strict";
      module.exports = function generate_uniqueItems(it, $keyword, $ruleType) {
        var out = " ";
        var $lvl = it.level;
        var $dataLvl = it.dataLevel;
        var $schema = it.schema[$keyword];
        var $schemaPath = it.schemaPath + it.util.getProperty($keyword);
        var $errSchemaPath = it.errSchemaPath + "/" + $keyword;
        var $breakOnError = !it.opts.allErrors;
        var $data = "data" + ($dataLvl || "");
        var $valid = "valid" + $lvl;
        var $isData = it.opts.$data && $schema && $schema.$data, $schemaValue;
        if ($isData) {
          out += " var schema" + $lvl + " = " + it.util.getData($schema.$data, $dataLvl, it.dataPathArr) + "; ";
          $schemaValue = "schema" + $lvl;
        } else {
          $schemaValue = $schema;
        }
        if (($schema || $isData) && it.opts.uniqueItems !== false) {
          if ($isData) {
            out += " var " + $valid + "; if (" + $schemaValue + " === false || " + $schemaValue + " === undefined) " + $valid + " = true; else if (typeof " + $schemaValue + " != 'boolean') " + $valid + " = false; else { ";
          }
          out += " var i = " + $data + ".length , " + $valid + " = true , j; if (i > 1) { ";
          var $itemType = it.schema.items && it.schema.items.type, $typeIsArray = Array.isArray($itemType);
          if (!$itemType || $itemType == "object" || $itemType == "array" || $typeIsArray && ($itemType.indexOf("object") >= 0 || $itemType.indexOf("array") >= 0)) {
            out += " outer: for (;i--;) { for (j = i; j--;) { if (equal(" + $data + "[i], " + $data + "[j])) { " + $valid + " = false; break outer; } } } ";
          } else {
            out += " var itemIndices = {}, item; for (;i--;) { var item = " + $data + "[i]; ";
            var $method = "checkDataType" + ($typeIsArray ? "s" : "");
            out += " if (" + it.util[$method]($itemType, "item", it.opts.strictNumbers, true) + ") continue; ";
            if ($typeIsArray) {
              out += ` if (typeof item == 'string') item = '"' + item; `;
            }
            out += " if (typeof itemIndices[item] == 'number') { " + $valid + " = false; j = itemIndices[item]; break; } itemIndices[item] = i; } ";
          }
          out += " } ";
          if ($isData) {
            out += "  }  ";
          }
          out += " if (!" + $valid + ") {   ";
          var $$outStack = $$outStack || [];
          $$outStack.push(out);
          out = "";
          if (it.createErrors !== false) {
            out += " { keyword: 'uniqueItems' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { i: i, j: j } ";
            if (it.opts.messages !== false) {
              out += " , message: 'should NOT have duplicate items (items ## ' + j + ' and ' + i + ' are identical)' ";
            }
            if (it.opts.verbose) {
              out += " , schema:  ";
              if ($isData) {
                out += "validate.schema" + $schemaPath;
              } else {
                out += "" + $schema;
              }
              out += "         , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
            }
            out += " } ";
          } else {
            out += " {} ";
          }
          var __err = out;
          out = $$outStack.pop();
          if (!it.compositeRule && $breakOnError) {
            if (it.async) {
              out += " throw new ValidationError([" + __err + "]); ";
            } else {
              out += " validate.errors = [" + __err + "]; return false; ";
            }
          } else {
            out += " var err = " + __err + ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
          }
          out += " } ";
          if ($breakOnError) {
            out += " else { ";
          }
        } else {
          if ($breakOnError) {
            out += " if (true) { ";
          }
        }
        return out;
      };
    }
  });

  // node_modules/ajv/lib/dotjs/index.js
  var require_dotjs = __commonJS({
    "node_modules/ajv/lib/dotjs/index.js"(exports, module) {
      "use strict";
      module.exports = {
        "$ref": require_ref(),
        allOf: require_allOf(),
        anyOf: require_anyOf(),
        "$comment": require_comment(),
        const: require_const(),
        contains: require_contains(),
        dependencies: require_dependencies(),
        "enum": require_enum(),
        format: require_format(),
        "if": require_if(),
        items: require_items(),
        maximum: require_limit(),
        minimum: require_limit(),
        maxItems: require_limitItems(),
        minItems: require_limitItems(),
        maxLength: require_limitLength(),
        minLength: require_limitLength(),
        maxProperties: require_limitProperties(),
        minProperties: require_limitProperties(),
        multipleOf: require_multipleOf(),
        not: require_not(),
        oneOf: require_oneOf(),
        pattern: require_pattern(),
        properties: require_properties(),
        propertyNames: require_propertyNames(),
        required: require_required(),
        uniqueItems: require_uniqueItems(),
        validate: require_validate()
      };
    }
  });

  // node_modules/ajv/lib/compile/rules.js
  var require_rules = __commonJS({
    "node_modules/ajv/lib/compile/rules.js"(exports, module) {
      "use strict";
      var ruleModules = require_dotjs();
      var toHash = require_util().toHash;
      module.exports = function rules() {
        var RULES = [
          {
            type: "number",
            rules: [
              { "maximum": ["exclusiveMaximum"] },
              { "minimum": ["exclusiveMinimum"] },
              "multipleOf",
              "format"
            ]
          },
          {
            type: "string",
            rules: ["maxLength", "minLength", "pattern", "format"]
          },
          {
            type: "array",
            rules: ["maxItems", "minItems", "items", "contains", "uniqueItems"]
          },
          {
            type: "object",
            rules: [
              "maxProperties",
              "minProperties",
              "required",
              "dependencies",
              "propertyNames",
              { "properties": ["additionalProperties", "patternProperties"] }
            ]
          },
          { rules: ["$ref", "const", "enum", "not", "anyOf", "oneOf", "allOf", "if"] }
        ];
        var ALL = ["type", "$comment"];
        var KEYWORDS = [
          "$schema",
          "$id",
          "id",
          "$data",
          "$async",
          "title",
          "description",
          "default",
          "definitions",
          "examples",
          "readOnly",
          "writeOnly",
          "contentMediaType",
          "contentEncoding",
          "additionalItems",
          "then",
          "else"
        ];
        var TYPES = ["number", "integer", "string", "array", "object", "boolean", "null"];
        RULES.all = toHash(ALL);
        RULES.types = toHash(TYPES);
        RULES.forEach(function(group) {
          group.rules = group.rules.map(function(keyword) {
            var implKeywords;
            if (typeof keyword == "object") {
              var key = Object.keys(keyword)[0];
              implKeywords = keyword[key];
              keyword = key;
              implKeywords.forEach(function(k) {
                ALL.push(k);
                RULES.all[k] = true;
              });
            }
            ALL.push(keyword);
            var rule = RULES.all[keyword] = {
              keyword,
              code: ruleModules[keyword],
              implements: implKeywords
            };
            return rule;
          });
          RULES.all.$comment = {
            keyword: "$comment",
            code: ruleModules.$comment
          };
          if (group.type)
            RULES.types[group.type] = group;
        });
        RULES.keywords = toHash(ALL.concat(KEYWORDS));
        RULES.custom = {};
        return RULES;
      };
    }
  });

  // node_modules/ajv/lib/data.js
  var require_data = __commonJS({
    "node_modules/ajv/lib/data.js"(exports, module) {
      "use strict";
      var KEYWORDS = [
        "multipleOf",
        "maximum",
        "exclusiveMaximum",
        "minimum",
        "exclusiveMinimum",
        "maxLength",
        "minLength",
        "pattern",
        "additionalItems",
        "maxItems",
        "minItems",
        "uniqueItems",
        "maxProperties",
        "minProperties",
        "required",
        "additionalProperties",
        "enum",
        "format",
        "const"
      ];
      module.exports = function(metaSchema, keywordsJsonPointers) {
        for (var i = 0; i < keywordsJsonPointers.length; i++) {
          metaSchema = JSON.parse(JSON.stringify(metaSchema));
          var segments = keywordsJsonPointers[i].split("/");
          var keywords = metaSchema;
          var j;
          for (j = 1; j < segments.length; j++)
            keywords = keywords[segments[j]];
          for (j = 0; j < KEYWORDS.length; j++) {
            var key = KEYWORDS[j];
            var schema = keywords[key];
            if (schema) {
              keywords[key] = {
                anyOf: [
                  schema,
                  { $ref: "https://raw.githubusercontent.com/ajv-validator/ajv/master/lib/refs/data.json#" }
                ]
              };
            }
          }
        }
        return metaSchema;
      };
    }
  });

  // node_modules/ajv/lib/compile/async.js
  var require_async = __commonJS({
    "node_modules/ajv/lib/compile/async.js"(exports, module) {
      "use strict";
      var MissingRefError = require_error_classes().MissingRef;
      module.exports = compileAsync;
      function compileAsync(schema, meta, callback) {
        var self2 = this;
        if (typeof this._opts.loadSchema != "function")
          throw new Error("options.loadSchema should be a function");
        if (typeof meta == "function") {
          callback = meta;
          meta = void 0;
        }
        var p = loadMetaSchemaOf(schema).then(function() {
          var schemaObj = self2._addSchema(schema, void 0, meta);
          return schemaObj.validate || _compileAsync(schemaObj);
        });
        if (callback) {
          p.then(function(v) {
            callback(null, v);
          }, callback);
        }
        return p;
        function loadMetaSchemaOf(sch) {
          var $schema = sch.$schema;
          return $schema && !self2.getSchema($schema) ? compileAsync.call(self2, { $ref: $schema }, true) : Promise.resolve();
        }
        function _compileAsync(schemaObj) {
          try {
            return self2._compile(schemaObj);
          } catch (e) {
            if (e instanceof MissingRefError)
              return loadMissingSchema(e);
            throw e;
          }
          function loadMissingSchema(e) {
            var ref = e.missingSchema;
            if (added(ref))
              throw new Error("Schema " + ref + " is loaded but " + e.missingRef + " cannot be resolved");
            var schemaPromise = self2._loadingSchemas[ref];
            if (!schemaPromise) {
              schemaPromise = self2._loadingSchemas[ref] = self2._opts.loadSchema(ref);
              schemaPromise.then(removePromise, removePromise);
            }
            return schemaPromise.then(function(sch) {
              if (!added(ref)) {
                return loadMetaSchemaOf(sch).then(function() {
                  if (!added(ref))
                    self2.addSchema(sch, ref, void 0, meta);
                });
              }
            }).then(function() {
              return _compileAsync(schemaObj);
            });
            function removePromise() {
              delete self2._loadingSchemas[ref];
            }
            function added(ref2) {
              return self2._refs[ref2] || self2._schemas[ref2];
            }
          }
        }
      }
    }
  });

  // node_modules/ajv/lib/dotjs/custom.js
  var require_custom = __commonJS({
    "node_modules/ajv/lib/dotjs/custom.js"(exports, module) {
      "use strict";
      module.exports = function generate_custom(it, $keyword, $ruleType) {
        var out = " ";
        var $lvl = it.level;
        var $dataLvl = it.dataLevel;
        var $schema = it.schema[$keyword];
        var $schemaPath = it.schemaPath + it.util.getProperty($keyword);
        var $errSchemaPath = it.errSchemaPath + "/" + $keyword;
        var $breakOnError = !it.opts.allErrors;
        var $errorKeyword;
        var $data = "data" + ($dataLvl || "");
        var $valid = "valid" + $lvl;
        var $errs = "errs__" + $lvl;
        var $isData = it.opts.$data && $schema && $schema.$data, $schemaValue;
        if ($isData) {
          out += " var schema" + $lvl + " = " + it.util.getData($schema.$data, $dataLvl, it.dataPathArr) + "; ";
          $schemaValue = "schema" + $lvl;
        } else {
          $schemaValue = $schema;
        }
        var $rule = this, $definition = "definition" + $lvl, $rDef = $rule.definition, $closingBraces = "";
        var $compile, $inline, $macro, $ruleValidate, $validateCode;
        if ($isData && $rDef.$data) {
          $validateCode = "keywordValidate" + $lvl;
          var $validateSchema = $rDef.validateSchema;
          out += " var " + $definition + " = RULES.custom['" + $keyword + "'].definition; var " + $validateCode + " = " + $definition + ".validate;";
        } else {
          $ruleValidate = it.useCustomRule($rule, $schema, it.schema, it);
          if (!$ruleValidate)
            return;
          $schemaValue = "validate.schema" + $schemaPath;
          $validateCode = $ruleValidate.code;
          $compile = $rDef.compile;
          $inline = $rDef.inline;
          $macro = $rDef.macro;
        }
        var $ruleErrs = $validateCode + ".errors", $i = "i" + $lvl, $ruleErr = "ruleErr" + $lvl, $asyncKeyword = $rDef.async;
        if ($asyncKeyword && !it.async)
          throw new Error("async keyword in sync schema");
        if (!($inline || $macro)) {
          out += "" + $ruleErrs + " = null;";
        }
        out += "var " + $errs + " = errors;var " + $valid + ";";
        if ($isData && $rDef.$data) {
          $closingBraces += "}";
          out += " if (" + $schemaValue + " === undefined) { " + $valid + " = true; } else { ";
          if ($validateSchema) {
            $closingBraces += "}";
            out += " " + $valid + " = " + $definition + ".validateSchema(" + $schemaValue + "); if (" + $valid + ") { ";
          }
        }
        if ($inline) {
          if ($rDef.statements) {
            out += " " + $ruleValidate.validate + " ";
          } else {
            out += " " + $valid + " = " + $ruleValidate.validate + "; ";
          }
        } else if ($macro) {
          var $it = it.util.copy(it);
          var $closingBraces = "";
          $it.level++;
          var $nextValid = "valid" + $it.level;
          $it.schema = $ruleValidate.validate;
          $it.schemaPath = "";
          var $wasComposite = it.compositeRule;
          it.compositeRule = $it.compositeRule = true;
          var $code = it.validate($it).replace(/validate\.schema/g, $validateCode);
          it.compositeRule = $it.compositeRule = $wasComposite;
          out += " " + $code;
        } else {
          var $$outStack = $$outStack || [];
          $$outStack.push(out);
          out = "";
          out += "  " + $validateCode + ".call( ";
          if (it.opts.passContext) {
            out += "this";
          } else {
            out += "self";
          }
          if ($compile || $rDef.schema === false) {
            out += " , " + $data + " ";
          } else {
            out += " , " + $schemaValue + " , " + $data + " , validate.schema" + it.schemaPath + " ";
          }
          out += " , (dataPath || '')";
          if (it.errorPath != '""') {
            out += " + " + it.errorPath;
          }
          var $parentData = $dataLvl ? "data" + ($dataLvl - 1 || "") : "parentData", $parentDataProperty = $dataLvl ? it.dataPathArr[$dataLvl] : "parentDataProperty";
          out += " , " + $parentData + " , " + $parentDataProperty + " , rootData )  ";
          var def_callRuleValidate = out;
          out = $$outStack.pop();
          if ($rDef.errors === false) {
            out += " " + $valid + " = ";
            if ($asyncKeyword) {
              out += "await ";
            }
            out += "" + def_callRuleValidate + "; ";
          } else {
            if ($asyncKeyword) {
              $ruleErrs = "customErrors" + $lvl;
              out += " var " + $ruleErrs + " = null; try { " + $valid + " = await " + def_callRuleValidate + "; } catch (e) { " + $valid + " = false; if (e instanceof ValidationError) " + $ruleErrs + " = e.errors; else throw e; } ";
            } else {
              out += " " + $ruleErrs + " = null; " + $valid + " = " + def_callRuleValidate + "; ";
            }
          }
        }
        if ($rDef.modifying) {
          out += " if (" + $parentData + ") " + $data + " = " + $parentData + "[" + $parentDataProperty + "];";
        }
        out += "" + $closingBraces;
        if ($rDef.valid) {
          if ($breakOnError) {
            out += " if (true) { ";
          }
        } else {
          out += " if ( ";
          if ($rDef.valid === void 0) {
            out += " !";
            if ($macro) {
              out += "" + $nextValid;
            } else {
              out += "" + $valid;
            }
          } else {
            out += " " + !$rDef.valid + " ";
          }
          out += ") { ";
          $errorKeyword = $rule.keyword;
          var $$outStack = $$outStack || [];
          $$outStack.push(out);
          out = "";
          var $$outStack = $$outStack || [];
          $$outStack.push(out);
          out = "";
          if (it.createErrors !== false) {
            out += " { keyword: '" + ($errorKeyword || "custom") + "' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { keyword: '" + $rule.keyword + "' } ";
            if (it.opts.messages !== false) {
              out += ` , message: 'should pass "` + $rule.keyword + `" keyword validation' `;
            }
            if (it.opts.verbose) {
              out += " , schema: validate.schema" + $schemaPath + " , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
            }
            out += " } ";
          } else {
            out += " {} ";
          }
          var __err = out;
          out = $$outStack.pop();
          if (!it.compositeRule && $breakOnError) {
            if (it.async) {
              out += " throw new ValidationError([" + __err + "]); ";
            } else {
              out += " validate.errors = [" + __err + "]; return false; ";
            }
          } else {
            out += " var err = " + __err + ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
          }
          var def_customError = out;
          out = $$outStack.pop();
          if ($inline) {
            if ($rDef.errors) {
              if ($rDef.errors != "full") {
                out += "  for (var " + $i + "=" + $errs + "; " + $i + "<errors; " + $i + "++) { var " + $ruleErr + " = vErrors[" + $i + "]; if (" + $ruleErr + ".dataPath === undefined) " + $ruleErr + ".dataPath = (dataPath || '') + " + it.errorPath + "; if (" + $ruleErr + ".schemaPath === undefined) { " + $ruleErr + '.schemaPath = "' + $errSchemaPath + '"; } ';
                if (it.opts.verbose) {
                  out += " " + $ruleErr + ".schema = " + $schemaValue + "; " + $ruleErr + ".data = " + $data + "; ";
                }
                out += " } ";
              }
            } else {
              if ($rDef.errors === false) {
                out += " " + def_customError + " ";
              } else {
                out += " if (" + $errs + " == errors) { " + def_customError + " } else {  for (var " + $i + "=" + $errs + "; " + $i + "<errors; " + $i + "++) { var " + $ruleErr + " = vErrors[" + $i + "]; if (" + $ruleErr + ".dataPath === undefined) " + $ruleErr + ".dataPath = (dataPath || '') + " + it.errorPath + "; if (" + $ruleErr + ".schemaPath === undefined) { " + $ruleErr + '.schemaPath = "' + $errSchemaPath + '"; } ';
                if (it.opts.verbose) {
                  out += " " + $ruleErr + ".schema = " + $schemaValue + "; " + $ruleErr + ".data = " + $data + "; ";
                }
                out += " } } ";
              }
            }
          } else if ($macro) {
            out += "   var err =   ";
            if (it.createErrors !== false) {
              out += " { keyword: '" + ($errorKeyword || "custom") + "' , dataPath: (dataPath || '') + " + it.errorPath + " , schemaPath: " + it.util.toQuotedString($errSchemaPath) + " , params: { keyword: '" + $rule.keyword + "' } ";
              if (it.opts.messages !== false) {
                out += ` , message: 'should pass "` + $rule.keyword + `" keyword validation' `;
              }
              if (it.opts.verbose) {
                out += " , schema: validate.schema" + $schemaPath + " , parentSchema: validate.schema" + it.schemaPath + " , data: " + $data + " ";
              }
              out += " } ";
            } else {
              out += " {} ";
            }
            out += ";  if (vErrors === null) vErrors = [err]; else vErrors.push(err); errors++; ";
            if (!it.compositeRule && $breakOnError) {
              if (it.async) {
                out += " throw new ValidationError(vErrors); ";
              } else {
                out += " validate.errors = vErrors; return false; ";
              }
            }
          } else {
            if ($rDef.errors === false) {
              out += " " + def_customError + " ";
            } else {
              out += " if (Array.isArray(" + $ruleErrs + ")) { if (vErrors === null) vErrors = " + $ruleErrs + "; else vErrors = vErrors.concat(" + $ruleErrs + "); errors = vErrors.length;  for (var " + $i + "=" + $errs + "; " + $i + "<errors; " + $i + "++) { var " + $ruleErr + " = vErrors[" + $i + "]; if (" + $ruleErr + ".dataPath === undefined) " + $ruleErr + ".dataPath = (dataPath || '') + " + it.errorPath + ";  " + $ruleErr + '.schemaPath = "' + $errSchemaPath + '";  ';
              if (it.opts.verbose) {
                out += " " + $ruleErr + ".schema = " + $schemaValue + "; " + $ruleErr + ".data = " + $data + "; ";
              }
              out += " } } else { " + def_customError + " } ";
            }
          }
          out += " } ";
          if ($breakOnError) {
            out += " else { ";
          }
        }
        return out;
      };
    }
  });

  // node_modules/ajv/lib/refs/json-schema-draft-07.json
  var require_json_schema_draft_07 = __commonJS({
    "node_modules/ajv/lib/refs/json-schema-draft-07.json"(exports, module) {
      module.exports = {
        $schema: "http://json-schema.org/draft-07/schema#",
        $id: "http://json-schema.org/draft-07/schema#",
        title: "Core schema meta-schema",
        definitions: {
          schemaArray: {
            type: "array",
            minItems: 1,
            items: { $ref: "#" }
          },
          nonNegativeInteger: {
            type: "integer",
            minimum: 0
          },
          nonNegativeIntegerDefault0: {
            allOf: [
              { $ref: "#/definitions/nonNegativeInteger" },
              { default: 0 }
            ]
          },
          simpleTypes: {
            enum: [
              "array",
              "boolean",
              "integer",
              "null",
              "number",
              "object",
              "string"
            ]
          },
          stringArray: {
            type: "array",
            items: { type: "string" },
            uniqueItems: true,
            default: []
          }
        },
        type: ["object", "boolean"],
        properties: {
          $id: {
            type: "string",
            format: "uri-reference"
          },
          $schema: {
            type: "string",
            format: "uri"
          },
          $ref: {
            type: "string",
            format: "uri-reference"
          },
          $comment: {
            type: "string"
          },
          title: {
            type: "string"
          },
          description: {
            type: "string"
          },
          default: true,
          readOnly: {
            type: "boolean",
            default: false
          },
          examples: {
            type: "array",
            items: true
          },
          multipleOf: {
            type: "number",
            exclusiveMinimum: 0
          },
          maximum: {
            type: "number"
          },
          exclusiveMaximum: {
            type: "number"
          },
          minimum: {
            type: "number"
          },
          exclusiveMinimum: {
            type: "number"
          },
          maxLength: { $ref: "#/definitions/nonNegativeInteger" },
          minLength: { $ref: "#/definitions/nonNegativeIntegerDefault0" },
          pattern: {
            type: "string",
            format: "regex"
          },
          additionalItems: { $ref: "#" },
          items: {
            anyOf: [
              { $ref: "#" },
              { $ref: "#/definitions/schemaArray" }
            ],
            default: true
          },
          maxItems: { $ref: "#/definitions/nonNegativeInteger" },
          minItems: { $ref: "#/definitions/nonNegativeIntegerDefault0" },
          uniqueItems: {
            type: "boolean",
            default: false
          },
          contains: { $ref: "#" },
          maxProperties: { $ref: "#/definitions/nonNegativeInteger" },
          minProperties: { $ref: "#/definitions/nonNegativeIntegerDefault0" },
          required: { $ref: "#/definitions/stringArray" },
          additionalProperties: { $ref: "#" },
          definitions: {
            type: "object",
            additionalProperties: { $ref: "#" },
            default: {}
          },
          properties: {
            type: "object",
            additionalProperties: { $ref: "#" },
            default: {}
          },
          patternProperties: {
            type: "object",
            additionalProperties: { $ref: "#" },
            propertyNames: { format: "regex" },
            default: {}
          },
          dependencies: {
            type: "object",
            additionalProperties: {
              anyOf: [
                { $ref: "#" },
                { $ref: "#/definitions/stringArray" }
              ]
            }
          },
          propertyNames: { $ref: "#" },
          const: true,
          enum: {
            type: "array",
            items: true,
            minItems: 1,
            uniqueItems: true
          },
          type: {
            anyOf: [
              { $ref: "#/definitions/simpleTypes" },
              {
                type: "array",
                items: { $ref: "#/definitions/simpleTypes" },
                minItems: 1,
                uniqueItems: true
              }
            ]
          },
          format: { type: "string" },
          contentMediaType: { type: "string" },
          contentEncoding: { type: "string" },
          if: { $ref: "#" },
          then: { $ref: "#" },
          else: { $ref: "#" },
          allOf: { $ref: "#/definitions/schemaArray" },
          anyOf: { $ref: "#/definitions/schemaArray" },
          oneOf: { $ref: "#/definitions/schemaArray" },
          not: { $ref: "#" }
        },
        default: true
      };
    }
  });

  // node_modules/ajv/lib/definition_schema.js
  var require_definition_schema = __commonJS({
    "node_modules/ajv/lib/definition_schema.js"(exports, module) {
      "use strict";
      var metaSchema = require_json_schema_draft_07();
      module.exports = {
        $id: "https://github.com/ajv-validator/ajv/blob/master/lib/definition_schema.js",
        definitions: {
          simpleTypes: metaSchema.definitions.simpleTypes
        },
        type: "object",
        dependencies: {
          schema: ["validate"],
          $data: ["validate"],
          statements: ["inline"],
          valid: { not: { required: ["macro"] } }
        },
        properties: {
          type: metaSchema.properties.type,
          schema: { type: "boolean" },
          statements: { type: "boolean" },
          dependencies: {
            type: "array",
            items: { type: "string" }
          },
          metaSchema: { type: "object" },
          modifying: { type: "boolean" },
          valid: { type: "boolean" },
          $data: { type: "boolean" },
          async: { type: "boolean" },
          errors: {
            anyOf: [
              { type: "boolean" },
              { const: "full" }
            ]
          }
        }
      };
    }
  });

  // node_modules/ajv/lib/keyword.js
  var require_keyword = __commonJS({
    "node_modules/ajv/lib/keyword.js"(exports, module) {
      "use strict";
      var IDENTIFIER = /^[a-z_$][a-z0-9_$-]*$/i;
      var customRuleCode = require_custom();
      var definitionSchema = require_definition_schema();
      module.exports = {
        add: addKeyword,
        get: getKeyword,
        remove: removeKeyword,
        validate: validateKeyword
      };
      function addKeyword(keyword, definition) {
        var RULES = this.RULES;
        if (RULES.keywords[keyword])
          throw new Error("Keyword " + keyword + " is already defined");
        if (!IDENTIFIER.test(keyword))
          throw new Error("Keyword " + keyword + " is not a valid identifier");
        if (definition) {
          this.validateKeyword(definition, true);
          var dataType = definition.type;
          if (Array.isArray(dataType)) {
            for (var i = 0; i < dataType.length; i++)
              _addRule(keyword, dataType[i], definition);
          } else {
            _addRule(keyword, dataType, definition);
          }
          var metaSchema = definition.metaSchema;
          if (metaSchema) {
            if (definition.$data && this._opts.$data) {
              metaSchema = {
                anyOf: [
                  metaSchema,
                  { "$ref": "https://raw.githubusercontent.com/ajv-validator/ajv/master/lib/refs/data.json#" }
                ]
              };
            }
            definition.validateSchema = this.compile(metaSchema, true);
          }
        }
        RULES.keywords[keyword] = RULES.all[keyword] = true;
        function _addRule(keyword2, dataType2, definition2) {
          var ruleGroup;
          for (var i2 = 0; i2 < RULES.length; i2++) {
            var rg = RULES[i2];
            if (rg.type == dataType2) {
              ruleGroup = rg;
              break;
            }
          }
          if (!ruleGroup) {
            ruleGroup = { type: dataType2, rules: [] };
            RULES.push(ruleGroup);
          }
          var rule = {
            keyword: keyword2,
            definition: definition2,
            custom: true,
            code: customRuleCode,
            implements: definition2.implements
          };
          ruleGroup.rules.push(rule);
          RULES.custom[keyword2] = rule;
        }
        return this;
      }
      function getKeyword(keyword) {
        var rule = this.RULES.custom[keyword];
        return rule ? rule.definition : this.RULES.keywords[keyword] || false;
      }
      function removeKeyword(keyword) {
        var RULES = this.RULES;
        delete RULES.keywords[keyword];
        delete RULES.all[keyword];
        delete RULES.custom[keyword];
        for (var i = 0; i < RULES.length; i++) {
          var rules = RULES[i].rules;
          for (var j = 0; j < rules.length; j++) {
            if (rules[j].keyword == keyword) {
              rules.splice(j, 1);
              break;
            }
          }
        }
        return this;
      }
      function validateKeyword(definition, throwError) {
        validateKeyword.errors = null;
        var v = this._validateKeyword = this._validateKeyword || this.compile(definitionSchema, true);
        if (v(definition))
          return true;
        validateKeyword.errors = v.errors;
        if (throwError)
          throw new Error("custom keyword definition is invalid: " + this.errorsText(v.errors));
        else
          return false;
      }
    }
  });

  // node_modules/ajv/lib/refs/data.json
  var require_data2 = __commonJS({
    "node_modules/ajv/lib/refs/data.json"(exports, module) {
      module.exports = {
        $schema: "http://json-schema.org/draft-07/schema#",
        $id: "https://raw.githubusercontent.com/ajv-validator/ajv/master/lib/refs/data.json#",
        description: "Meta-schema for $data reference (JSON Schema extension proposal)",
        type: "object",
        required: ["$data"],
        properties: {
          $data: {
            type: "string",
            anyOf: [
              { format: "relative-json-pointer" },
              { format: "json-pointer" }
            ]
          }
        },
        additionalProperties: false
      };
    }
  });

  // node_modules/ajv/lib/ajv.js
  var require_ajv = __commonJS({
    "node_modules/ajv/lib/ajv.js"(exports, module) {
      "use strict";
      var compileSchema = require_compile();
      var resolve = require_resolve();
      var Cache = require_cache();
      var SchemaObject = require_schema_obj();
      var stableStringify = require_fast_json_stable_stringify();
      var formats = require_formats();
      var rules = require_rules();
      var $dataMetaSchema = require_data();
      var util = require_util();
      module.exports = Ajv2;
      Ajv2.prototype.validate = validate;
      Ajv2.prototype.compile = compile;
      Ajv2.prototype.addSchema = addSchema;
      Ajv2.prototype.addMetaSchema = addMetaSchema;
      Ajv2.prototype.validateSchema = validateSchema;
      Ajv2.prototype.getSchema = getSchema;
      Ajv2.prototype.removeSchema = removeSchema;
      Ajv2.prototype.addFormat = addFormat;
      Ajv2.prototype.errorsText = errorsText;
      Ajv2.prototype._addSchema = _addSchema;
      Ajv2.prototype._compile = _compile;
      Ajv2.prototype.compileAsync = require_async();
      var customKeyword = require_keyword();
      Ajv2.prototype.addKeyword = customKeyword.add;
      Ajv2.prototype.getKeyword = customKeyword.get;
      Ajv2.prototype.removeKeyword = customKeyword.remove;
      Ajv2.prototype.validateKeyword = customKeyword.validate;
      var errorClasses = require_error_classes();
      Ajv2.ValidationError = errorClasses.Validation;
      Ajv2.MissingRefError = errorClasses.MissingRef;
      Ajv2.$dataMetaSchema = $dataMetaSchema;
      var META_SCHEMA_ID = "http://json-schema.org/draft-07/schema";
      var META_IGNORE_OPTIONS = ["removeAdditional", "useDefaults", "coerceTypes", "strictDefaults"];
      var META_SUPPORT_DATA = ["/properties"];
      function Ajv2(opts) {
        if (!(this instanceof Ajv2))
          return new Ajv2(opts);
        opts = this._opts = util.copy(opts) || {};
        setLogger(this);
        this._schemas = {};
        this._refs = {};
        this._fragments = {};
        this._formats = formats(opts.format);
        this._cache = opts.cache || new Cache();
        this._loadingSchemas = {};
        this._compilations = [];
        this.RULES = rules();
        this._getId = chooseGetId(opts);
        opts.loopRequired = opts.loopRequired || Infinity;
        if (opts.errorDataPath == "property")
          opts._errorDataPathProperty = true;
        if (opts.serialize === void 0)
          opts.serialize = stableStringify;
        this._metaOpts = getMetaSchemaOptions(this);
        if (opts.formats)
          addInitialFormats(this);
        if (opts.keywords)
          addInitialKeywords(this);
        addDefaultMetaSchema(this);
        if (typeof opts.meta == "object")
          this.addMetaSchema(opts.meta);
        if (opts.nullable)
          this.addKeyword("nullable", { metaSchema: { type: "boolean" } });
        addInitialSchemas(this);
      }
      function validate(schemaKeyRef, data) {
        var v;
        if (typeof schemaKeyRef == "string") {
          v = this.getSchema(schemaKeyRef);
          if (!v)
            throw new Error('no schema with key or ref "' + schemaKeyRef + '"');
        } else {
          var schemaObj = this._addSchema(schemaKeyRef);
          v = schemaObj.validate || this._compile(schemaObj);
        }
        var valid = v(data);
        if (v.$async !== true)
          this.errors = v.errors;
        return valid;
      }
      function compile(schema, _meta) {
        var schemaObj = this._addSchema(schema, void 0, _meta);
        return schemaObj.validate || this._compile(schemaObj);
      }
      function addSchema(schema, key, _skipValidation, _meta) {
        if (Array.isArray(schema)) {
          for (var i = 0; i < schema.length; i++)
            this.addSchema(schema[i], void 0, _skipValidation, _meta);
          return this;
        }
        var id = this._getId(schema);
        if (id !== void 0 && typeof id != "string")
          throw new Error("schema id must be string");
        key = resolve.normalizeId(key || id);
        checkUnique(this, key);
        this._schemas[key] = this._addSchema(schema, _skipValidation, _meta, true);
        return this;
      }
      function addMetaSchema(schema, key, skipValidation) {
        this.addSchema(schema, key, skipValidation, true);
        return this;
      }
      function validateSchema(schema, throwOrLogError) {
        var $schema = schema.$schema;
        if ($schema !== void 0 && typeof $schema != "string")
          throw new Error("$schema must be a string");
        $schema = $schema || this._opts.defaultMeta || defaultMeta(this);
        if (!$schema) {
          this.logger.warn("meta-schema not available");
          this.errors = null;
          return true;
        }
        var valid = this.validate($schema, schema);
        if (!valid && throwOrLogError) {
          var message = "schema is invalid: " + this.errorsText();
          if (this._opts.validateSchema == "log")
            this.logger.error(message);
          else
            throw new Error(message);
        }
        return valid;
      }
      function defaultMeta(self2) {
        var meta = self2._opts.meta;
        self2._opts.defaultMeta = typeof meta == "object" ? self2._getId(meta) || meta : self2.getSchema(META_SCHEMA_ID) ? META_SCHEMA_ID : void 0;
        return self2._opts.defaultMeta;
      }
      function getSchema(keyRef) {
        var schemaObj = _getSchemaObj(this, keyRef);
        switch (typeof schemaObj) {
          case "object":
            return schemaObj.validate || this._compile(schemaObj);
          case "string":
            return this.getSchema(schemaObj);
          case "undefined":
            return _getSchemaFragment(this, keyRef);
        }
      }
      function _getSchemaFragment(self2, ref) {
        var res = resolve.schema.call(self2, { schema: {} }, ref);
        if (res) {
          var schema = res.schema, root = res.root, baseId = res.baseId;
          var v = compileSchema.call(self2, schema, root, void 0, baseId);
          self2._fragments[ref] = new SchemaObject({
            ref,
            fragment: true,
            schema,
            root,
            baseId,
            validate: v
          });
          return v;
        }
      }
      function _getSchemaObj(self2, keyRef) {
        keyRef = resolve.normalizeId(keyRef);
        return self2._schemas[keyRef] || self2._refs[keyRef] || self2._fragments[keyRef];
      }
      function removeSchema(schemaKeyRef) {
        if (schemaKeyRef instanceof RegExp) {
          _removeAllSchemas(this, this._schemas, schemaKeyRef);
          _removeAllSchemas(this, this._refs, schemaKeyRef);
          return this;
        }
        switch (typeof schemaKeyRef) {
          case "undefined":
            _removeAllSchemas(this, this._schemas);
            _removeAllSchemas(this, this._refs);
            this._cache.clear();
            return this;
          case "string":
            var schemaObj = _getSchemaObj(this, schemaKeyRef);
            if (schemaObj)
              this._cache.del(schemaObj.cacheKey);
            delete this._schemas[schemaKeyRef];
            delete this._refs[schemaKeyRef];
            return this;
          case "object":
            var serialize = this._opts.serialize;
            var cacheKey = serialize ? serialize(schemaKeyRef) : schemaKeyRef;
            this._cache.del(cacheKey);
            var id = this._getId(schemaKeyRef);
            if (id) {
              id = resolve.normalizeId(id);
              delete this._schemas[id];
              delete this._refs[id];
            }
        }
        return this;
      }
      function _removeAllSchemas(self2, schemas, regex) {
        for (var keyRef in schemas) {
          var schemaObj = schemas[keyRef];
          if (!schemaObj.meta && (!regex || regex.test(keyRef))) {
            self2._cache.del(schemaObj.cacheKey);
            delete schemas[keyRef];
          }
        }
      }
      function _addSchema(schema, skipValidation, meta, shouldAddSchema) {
        if (typeof schema != "object" && typeof schema != "boolean")
          throw new Error("schema should be object or boolean");
        var serialize = this._opts.serialize;
        var cacheKey = serialize ? serialize(schema) : schema;
        var cached = this._cache.get(cacheKey);
        if (cached)
          return cached;
        shouldAddSchema = shouldAddSchema || this._opts.addUsedSchema !== false;
        var id = resolve.normalizeId(this._getId(schema));
        if (id && shouldAddSchema)
          checkUnique(this, id);
        var willValidate = this._opts.validateSchema !== false && !skipValidation;
        var recursiveMeta;
        if (willValidate && !(recursiveMeta = id && id == resolve.normalizeId(schema.$schema)))
          this.validateSchema(schema, true);
        var localRefs = resolve.ids.call(this, schema);
        var schemaObj = new SchemaObject({
          id,
          schema,
          localRefs,
          cacheKey,
          meta
        });
        if (id[0] != "#" && shouldAddSchema)
          this._refs[id] = schemaObj;
        this._cache.put(cacheKey, schemaObj);
        if (willValidate && recursiveMeta)
          this.validateSchema(schema, true);
        return schemaObj;
      }
      function _compile(schemaObj, root) {
        if (schemaObj.compiling) {
          schemaObj.validate = callValidate;
          callValidate.schema = schemaObj.schema;
          callValidate.errors = null;
          callValidate.root = root ? root : callValidate;
          if (schemaObj.schema.$async === true)
            callValidate.$async = true;
          return callValidate;
        }
        schemaObj.compiling = true;
        var currentOpts;
        if (schemaObj.meta) {
          currentOpts = this._opts;
          this._opts = this._metaOpts;
        }
        var v;
        try {
          v = compileSchema.call(this, schemaObj.schema, root, schemaObj.localRefs);
        } catch (e) {
          delete schemaObj.validate;
          throw e;
        } finally {
          schemaObj.compiling = false;
          if (schemaObj.meta)
            this._opts = currentOpts;
        }
        schemaObj.validate = v;
        schemaObj.refs = v.refs;
        schemaObj.refVal = v.refVal;
        schemaObj.root = v.root;
        return v;
        function callValidate() {
          var _validate = schemaObj.validate;
          var result = _validate.apply(this, arguments);
          callValidate.errors = _validate.errors;
          return result;
        }
      }
      function chooseGetId(opts) {
        switch (opts.schemaId) {
          case "auto":
            return _get$IdOrId;
          case "id":
            return _getId;
          default:
            return _get$Id;
        }
      }
      function _getId(schema) {
        if (schema.$id)
          this.logger.warn("schema $id ignored", schema.$id);
        return schema.id;
      }
      function _get$Id(schema) {
        if (schema.id)
          this.logger.warn("schema id ignored", schema.id);
        return schema.$id;
      }
      function _get$IdOrId(schema) {
        if (schema.$id && schema.id && schema.$id != schema.id)
          throw new Error("schema $id is different from id");
        return schema.$id || schema.id;
      }
      function errorsText(errors, options) {
        errors = errors || this.errors;
        if (!errors)
          return "No errors";
        options = options || {};
        var separator = options.separator === void 0 ? ", " : options.separator;
        var dataVar = options.dataVar === void 0 ? "data" : options.dataVar;
        var text = "";
        for (var i = 0; i < errors.length; i++) {
          var e = errors[i];
          if (e)
            text += dataVar + e.dataPath + " " + e.message + separator;
        }
        return text.slice(0, -separator.length);
      }
      function addFormat(name, format) {
        if (typeof format == "string")
          format = new RegExp(format);
        this._formats[name] = format;
        return this;
      }
      function addDefaultMetaSchema(self2) {
        var $dataSchema;
        if (self2._opts.$data) {
          $dataSchema = require_data2();
          self2.addMetaSchema($dataSchema, $dataSchema.$id, true);
        }
        if (self2._opts.meta === false)
          return;
        var metaSchema = require_json_schema_draft_07();
        if (self2._opts.$data)
          metaSchema = $dataMetaSchema(metaSchema, META_SUPPORT_DATA);
        self2.addMetaSchema(metaSchema, META_SCHEMA_ID, true);
        self2._refs["http://json-schema.org/schema"] = META_SCHEMA_ID;
      }
      function addInitialSchemas(self2) {
        var optsSchemas = self2._opts.schemas;
        if (!optsSchemas)
          return;
        if (Array.isArray(optsSchemas))
          self2.addSchema(optsSchemas);
        else
          for (var key in optsSchemas)
            self2.addSchema(optsSchemas[key], key);
      }
      function addInitialFormats(self2) {
        for (var name in self2._opts.formats) {
          var format = self2._opts.formats[name];
          self2.addFormat(name, format);
        }
      }
      function addInitialKeywords(self2) {
        for (var name in self2._opts.keywords) {
          var keyword = self2._opts.keywords[name];
          self2.addKeyword(name, keyword);
        }
      }
      function checkUnique(self2, id) {
        if (self2._schemas[id] || self2._refs[id])
          throw new Error('schema with key or id "' + id + '" already exists');
      }
      function getMetaSchemaOptions(self2) {
        var metaOpts = util.copy(self2._opts);
        for (var i = 0; i < META_IGNORE_OPTIONS.length; i++)
          delete metaOpts[META_IGNORE_OPTIONS[i]];
        return metaOpts;
      }
      function setLogger(self2) {
        var logger = self2._opts.logger;
        if (logger === false) {
          self2.logger = { log: noop, warn: noop, error: noop };
        } else {
          if (logger === void 0)
            logger = console;
          if (!(typeof logger == "object" && logger.log && logger.warn && logger.error))
            throw new Error("logger must implement log, warn and error methods");
          self2.logger = logger;
        }
      }
      function noop() {
      }
    }
  });

  // node_modules/lodash/_listCacheClear.js
  var require_listCacheClear = __commonJS({
    "node_modules/lodash/_listCacheClear.js"(exports, module) {
      function listCacheClear() {
        this.__data__ = [];
        this.size = 0;
      }
      module.exports = listCacheClear;
    }
  });

  // node_modules/lodash/eq.js
  var require_eq = __commonJS({
    "node_modules/lodash/eq.js"(exports, module) {
      function eq(value, other) {
        return value === other || value !== value && other !== other;
      }
      module.exports = eq;
    }
  });

  // node_modules/lodash/_assocIndexOf.js
  var require_assocIndexOf = __commonJS({
    "node_modules/lodash/_assocIndexOf.js"(exports, module) {
      var eq = require_eq();
      function assocIndexOf(array, key) {
        var length = array.length;
        while (length--) {
          if (eq(array[length][0], key)) {
            return length;
          }
        }
        return -1;
      }
      module.exports = assocIndexOf;
    }
  });

  // node_modules/lodash/_listCacheDelete.js
  var require_listCacheDelete = __commonJS({
    "node_modules/lodash/_listCacheDelete.js"(exports, module) {
      var assocIndexOf = require_assocIndexOf();
      var arrayProto = Array.prototype;
      var splice = arrayProto.splice;
      function listCacheDelete(key) {
        var data = this.__data__, index = assocIndexOf(data, key);
        if (index < 0) {
          return false;
        }
        var lastIndex = data.length - 1;
        if (index == lastIndex) {
          data.pop();
        } else {
          splice.call(data, index, 1);
        }
        --this.size;
        return true;
      }
      module.exports = listCacheDelete;
    }
  });

  // node_modules/lodash/_listCacheGet.js
  var require_listCacheGet = __commonJS({
    "node_modules/lodash/_listCacheGet.js"(exports, module) {
      var assocIndexOf = require_assocIndexOf();
      function listCacheGet(key) {
        var data = this.__data__, index = assocIndexOf(data, key);
        return index < 0 ? void 0 : data[index][1];
      }
      module.exports = listCacheGet;
    }
  });

  // node_modules/lodash/_listCacheHas.js
  var require_listCacheHas = __commonJS({
    "node_modules/lodash/_listCacheHas.js"(exports, module) {
      var assocIndexOf = require_assocIndexOf();
      function listCacheHas(key) {
        return assocIndexOf(this.__data__, key) > -1;
      }
      module.exports = listCacheHas;
    }
  });

  // node_modules/lodash/_listCacheSet.js
  var require_listCacheSet = __commonJS({
    "node_modules/lodash/_listCacheSet.js"(exports, module) {
      var assocIndexOf = require_assocIndexOf();
      function listCacheSet(key, value) {
        var data = this.__data__, index = assocIndexOf(data, key);
        if (index < 0) {
          ++this.size;
          data.push([key, value]);
        } else {
          data[index][1] = value;
        }
        return this;
      }
      module.exports = listCacheSet;
    }
  });

  // node_modules/lodash/_ListCache.js
  var require_ListCache = __commonJS({
    "node_modules/lodash/_ListCache.js"(exports, module) {
      var listCacheClear = require_listCacheClear();
      var listCacheDelete = require_listCacheDelete();
      var listCacheGet = require_listCacheGet();
      var listCacheHas = require_listCacheHas();
      var listCacheSet = require_listCacheSet();
      function ListCache(entries) {
        var index = -1, length = entries == null ? 0 : entries.length;
        this.clear();
        while (++index < length) {
          var entry = entries[index];
          this.set(entry[0], entry[1]);
        }
      }
      ListCache.prototype.clear = listCacheClear;
      ListCache.prototype["delete"] = listCacheDelete;
      ListCache.prototype.get = listCacheGet;
      ListCache.prototype.has = listCacheHas;
      ListCache.prototype.set = listCacheSet;
      module.exports = ListCache;
    }
  });

  // node_modules/lodash/_stackClear.js
  var require_stackClear = __commonJS({
    "node_modules/lodash/_stackClear.js"(exports, module) {
      var ListCache = require_ListCache();
      function stackClear() {
        this.__data__ = new ListCache();
        this.size = 0;
      }
      module.exports = stackClear;
    }
  });

  // node_modules/lodash/_stackDelete.js
  var require_stackDelete = __commonJS({
    "node_modules/lodash/_stackDelete.js"(exports, module) {
      function stackDelete(key) {
        var data = this.__data__, result = data["delete"](key);
        this.size = data.size;
        return result;
      }
      module.exports = stackDelete;
    }
  });

  // node_modules/lodash/_stackGet.js
  var require_stackGet = __commonJS({
    "node_modules/lodash/_stackGet.js"(exports, module) {
      function stackGet(key) {
        return this.__data__.get(key);
      }
      module.exports = stackGet;
    }
  });

  // node_modules/lodash/_stackHas.js
  var require_stackHas = __commonJS({
    "node_modules/lodash/_stackHas.js"(exports, module) {
      function stackHas(key) {
        return this.__data__.has(key);
      }
      module.exports = stackHas;
    }
  });

  // node_modules/lodash/_freeGlobal.js
  var require_freeGlobal = __commonJS({
    "node_modules/lodash/_freeGlobal.js"(exports, module) {
      var freeGlobal = typeof global == "object" && global && global.Object === Object && global;
      module.exports = freeGlobal;
    }
  });

  // node_modules/lodash/_root.js
  var require_root = __commonJS({
    "node_modules/lodash/_root.js"(exports, module) {
      var freeGlobal = require_freeGlobal();
      var freeSelf = typeof self == "object" && self && self.Object === Object && self;
      var root = freeGlobal || freeSelf || Function("return this")();
      module.exports = root;
    }
  });

  // node_modules/lodash/_Symbol.js
  var require_Symbol = __commonJS({
    "node_modules/lodash/_Symbol.js"(exports, module) {
      var root = require_root();
      var Symbol2 = root.Symbol;
      module.exports = Symbol2;
    }
  });

  // node_modules/lodash/_getRawTag.js
  var require_getRawTag = __commonJS({
    "node_modules/lodash/_getRawTag.js"(exports, module) {
      var Symbol2 = require_Symbol();
      var objectProto = Object.prototype;
      var hasOwnProperty = objectProto.hasOwnProperty;
      var nativeObjectToString = objectProto.toString;
      var symToStringTag = Symbol2 ? Symbol2.toStringTag : void 0;
      function getRawTag(value) {
        var isOwn = hasOwnProperty.call(value, symToStringTag), tag = value[symToStringTag];
        try {
          value[symToStringTag] = void 0;
          var unmasked = true;
        } catch (e) {
        }
        var result = nativeObjectToString.call(value);
        if (unmasked) {
          if (isOwn) {
            value[symToStringTag] = tag;
          } else {
            delete value[symToStringTag];
          }
        }
        return result;
      }
      module.exports = getRawTag;
    }
  });

  // node_modules/lodash/_objectToString.js
  var require_objectToString = __commonJS({
    "node_modules/lodash/_objectToString.js"(exports, module) {
      var objectProto = Object.prototype;
      var nativeObjectToString = objectProto.toString;
      function objectToString(value) {
        return nativeObjectToString.call(value);
      }
      module.exports = objectToString;
    }
  });

  // node_modules/lodash/_baseGetTag.js
  var require_baseGetTag = __commonJS({
    "node_modules/lodash/_baseGetTag.js"(exports, module) {
      var Symbol2 = require_Symbol();
      var getRawTag = require_getRawTag();
      var objectToString = require_objectToString();
      var nullTag = "[object Null]";
      var undefinedTag = "[object Undefined]";
      var symToStringTag = Symbol2 ? Symbol2.toStringTag : void 0;
      function baseGetTag(value) {
        if (value == null) {
          return value === void 0 ? undefinedTag : nullTag;
        }
        return symToStringTag && symToStringTag in Object(value) ? getRawTag(value) : objectToString(value);
      }
      module.exports = baseGetTag;
    }
  });

  // node_modules/lodash/isObject.js
  var require_isObject = __commonJS({
    "node_modules/lodash/isObject.js"(exports, module) {
      function isObject(value) {
        var type4 = typeof value;
        return value != null && (type4 == "object" || type4 == "function");
      }
      module.exports = isObject;
    }
  });

  // node_modules/lodash/isFunction.js
  var require_isFunction = __commonJS({
    "node_modules/lodash/isFunction.js"(exports, module) {
      var baseGetTag = require_baseGetTag();
      var isObject = require_isObject();
      var asyncTag = "[object AsyncFunction]";
      var funcTag = "[object Function]";
      var genTag = "[object GeneratorFunction]";
      var proxyTag = "[object Proxy]";
      function isFunction(value) {
        if (!isObject(value)) {
          return false;
        }
        var tag = baseGetTag(value);
        return tag == funcTag || tag == genTag || tag == asyncTag || tag == proxyTag;
      }
      module.exports = isFunction;
    }
  });

  // node_modules/lodash/_coreJsData.js
  var require_coreJsData = __commonJS({
    "node_modules/lodash/_coreJsData.js"(exports, module) {
      var root = require_root();
      var coreJsData = root["__core-js_shared__"];
      module.exports = coreJsData;
    }
  });

  // node_modules/lodash/_isMasked.js
  var require_isMasked = __commonJS({
    "node_modules/lodash/_isMasked.js"(exports, module) {
      var coreJsData = require_coreJsData();
      var maskSrcKey = function() {
        var uid = /[^.]+$/.exec(coreJsData && coreJsData.keys && coreJsData.keys.IE_PROTO || "");
        return uid ? "Symbol(src)_1." + uid : "";
      }();
      function isMasked(func) {
        return !!maskSrcKey && maskSrcKey in func;
      }
      module.exports = isMasked;
    }
  });

  // node_modules/lodash/_toSource.js
  var require_toSource = __commonJS({
    "node_modules/lodash/_toSource.js"(exports, module) {
      var funcProto = Function.prototype;
      var funcToString = funcProto.toString;
      function toSource(func) {
        if (func != null) {
          try {
            return funcToString.call(func);
          } catch (e) {
          }
          try {
            return func + "";
          } catch (e) {
          }
        }
        return "";
      }
      module.exports = toSource;
    }
  });

  // node_modules/lodash/_baseIsNative.js
  var require_baseIsNative = __commonJS({
    "node_modules/lodash/_baseIsNative.js"(exports, module) {
      var isFunction = require_isFunction();
      var isMasked = require_isMasked();
      var isObject = require_isObject();
      var toSource = require_toSource();
      var reRegExpChar = /[\\^$.*+?()[\]{}|]/g;
      var reIsHostCtor = /^\[object .+?Constructor\]$/;
      var funcProto = Function.prototype;
      var objectProto = Object.prototype;
      var funcToString = funcProto.toString;
      var hasOwnProperty = objectProto.hasOwnProperty;
      var reIsNative = RegExp("^" + funcToString.call(hasOwnProperty).replace(reRegExpChar, "\\$&").replace(/hasOwnProperty|(function).*?(?=\\\()| for .+?(?=\\\])/g, "$1.*?") + "$");
      function baseIsNative(value) {
        if (!isObject(value) || isMasked(value)) {
          return false;
        }
        var pattern = isFunction(value) ? reIsNative : reIsHostCtor;
        return pattern.test(toSource(value));
      }
      module.exports = baseIsNative;
    }
  });

  // node_modules/lodash/_getValue.js
  var require_getValue = __commonJS({
    "node_modules/lodash/_getValue.js"(exports, module) {
      function getValue(object, key) {
        return object == null ? void 0 : object[key];
      }
      module.exports = getValue;
    }
  });

  // node_modules/lodash/_getNative.js
  var require_getNative = __commonJS({
    "node_modules/lodash/_getNative.js"(exports, module) {
      var baseIsNative = require_baseIsNative();
      var getValue = require_getValue();
      function getNative(object, key) {
        var value = getValue(object, key);
        return baseIsNative(value) ? value : void 0;
      }
      module.exports = getNative;
    }
  });

  // node_modules/lodash/_Map.js
  var require_Map = __commonJS({
    "node_modules/lodash/_Map.js"(exports, module) {
      var getNative = require_getNative();
      var root = require_root();
      var Map = getNative(root, "Map");
      module.exports = Map;
    }
  });

  // node_modules/lodash/_nativeCreate.js
  var require_nativeCreate = __commonJS({
    "node_modules/lodash/_nativeCreate.js"(exports, module) {
      var getNative = require_getNative();
      var nativeCreate = getNative(Object, "create");
      module.exports = nativeCreate;
    }
  });

  // node_modules/lodash/_hashClear.js
  var require_hashClear = __commonJS({
    "node_modules/lodash/_hashClear.js"(exports, module) {
      var nativeCreate = require_nativeCreate();
      function hashClear() {
        this.__data__ = nativeCreate ? nativeCreate(null) : {};
        this.size = 0;
      }
      module.exports = hashClear;
    }
  });

  // node_modules/lodash/_hashDelete.js
  var require_hashDelete = __commonJS({
    "node_modules/lodash/_hashDelete.js"(exports, module) {
      function hashDelete(key) {
        var result = this.has(key) && delete this.__data__[key];
        this.size -= result ? 1 : 0;
        return result;
      }
      module.exports = hashDelete;
    }
  });

  // node_modules/lodash/_hashGet.js
  var require_hashGet = __commonJS({
    "node_modules/lodash/_hashGet.js"(exports, module) {
      var nativeCreate = require_nativeCreate();
      var HASH_UNDEFINED = "__lodash_hash_undefined__";
      var objectProto = Object.prototype;
      var hasOwnProperty = objectProto.hasOwnProperty;
      function hashGet(key) {
        var data = this.__data__;
        if (nativeCreate) {
          var result = data[key];
          return result === HASH_UNDEFINED ? void 0 : result;
        }
        return hasOwnProperty.call(data, key) ? data[key] : void 0;
      }
      module.exports = hashGet;
    }
  });

  // node_modules/lodash/_hashHas.js
  var require_hashHas = __commonJS({
    "node_modules/lodash/_hashHas.js"(exports, module) {
      var nativeCreate = require_nativeCreate();
      var objectProto = Object.prototype;
      var hasOwnProperty = objectProto.hasOwnProperty;
      function hashHas(key) {
        var data = this.__data__;
        return nativeCreate ? data[key] !== void 0 : hasOwnProperty.call(data, key);
      }
      module.exports = hashHas;
    }
  });

  // node_modules/lodash/_hashSet.js
  var require_hashSet = __commonJS({
    "node_modules/lodash/_hashSet.js"(exports, module) {
      var nativeCreate = require_nativeCreate();
      var HASH_UNDEFINED = "__lodash_hash_undefined__";
      function hashSet(key, value) {
        var data = this.__data__;
        this.size += this.has(key) ? 0 : 1;
        data[key] = nativeCreate && value === void 0 ? HASH_UNDEFINED : value;
        return this;
      }
      module.exports = hashSet;
    }
  });

  // node_modules/lodash/_Hash.js
  var require_Hash = __commonJS({
    "node_modules/lodash/_Hash.js"(exports, module) {
      var hashClear = require_hashClear();
      var hashDelete = require_hashDelete();
      var hashGet = require_hashGet();
      var hashHas = require_hashHas();
      var hashSet = require_hashSet();
      function Hash(entries) {
        var index = -1, length = entries == null ? 0 : entries.length;
        this.clear();
        while (++index < length) {
          var entry = entries[index];
          this.set(entry[0], entry[1]);
        }
      }
      Hash.prototype.clear = hashClear;
      Hash.prototype["delete"] = hashDelete;
      Hash.prototype.get = hashGet;
      Hash.prototype.has = hashHas;
      Hash.prototype.set = hashSet;
      module.exports = Hash;
    }
  });

  // node_modules/lodash/_mapCacheClear.js
  var require_mapCacheClear = __commonJS({
    "node_modules/lodash/_mapCacheClear.js"(exports, module) {
      var Hash = require_Hash();
      var ListCache = require_ListCache();
      var Map = require_Map();
      function mapCacheClear() {
        this.size = 0;
        this.__data__ = {
          "hash": new Hash(),
          "map": new (Map || ListCache)(),
          "string": new Hash()
        };
      }
      module.exports = mapCacheClear;
    }
  });

  // node_modules/lodash/_isKeyable.js
  var require_isKeyable = __commonJS({
    "node_modules/lodash/_isKeyable.js"(exports, module) {
      function isKeyable(value) {
        var type4 = typeof value;
        return type4 == "string" || type4 == "number" || type4 == "symbol" || type4 == "boolean" ? value !== "__proto__" : value === null;
      }
      module.exports = isKeyable;
    }
  });

  // node_modules/lodash/_getMapData.js
  var require_getMapData = __commonJS({
    "node_modules/lodash/_getMapData.js"(exports, module) {
      var isKeyable = require_isKeyable();
      function getMapData(map, key) {
        var data = map.__data__;
        return isKeyable(key) ? data[typeof key == "string" ? "string" : "hash"] : data.map;
      }
      module.exports = getMapData;
    }
  });

  // node_modules/lodash/_mapCacheDelete.js
  var require_mapCacheDelete = __commonJS({
    "node_modules/lodash/_mapCacheDelete.js"(exports, module) {
      var getMapData = require_getMapData();
      function mapCacheDelete(key) {
        var result = getMapData(this, key)["delete"](key);
        this.size -= result ? 1 : 0;
        return result;
      }
      module.exports = mapCacheDelete;
    }
  });

  // node_modules/lodash/_mapCacheGet.js
  var require_mapCacheGet = __commonJS({
    "node_modules/lodash/_mapCacheGet.js"(exports, module) {
      var getMapData = require_getMapData();
      function mapCacheGet(key) {
        return getMapData(this, key).get(key);
      }
      module.exports = mapCacheGet;
    }
  });

  // node_modules/lodash/_mapCacheHas.js
  var require_mapCacheHas = __commonJS({
    "node_modules/lodash/_mapCacheHas.js"(exports, module) {
      var getMapData = require_getMapData();
      function mapCacheHas(key) {
        return getMapData(this, key).has(key);
      }
      module.exports = mapCacheHas;
    }
  });

  // node_modules/lodash/_mapCacheSet.js
  var require_mapCacheSet = __commonJS({
    "node_modules/lodash/_mapCacheSet.js"(exports, module) {
      var getMapData = require_getMapData();
      function mapCacheSet(key, value) {
        var data = getMapData(this, key), size = data.size;
        data.set(key, value);
        this.size += data.size == size ? 0 : 1;
        return this;
      }
      module.exports = mapCacheSet;
    }
  });

  // node_modules/lodash/_MapCache.js
  var require_MapCache = __commonJS({
    "node_modules/lodash/_MapCache.js"(exports, module) {
      var mapCacheClear = require_mapCacheClear();
      var mapCacheDelete = require_mapCacheDelete();
      var mapCacheGet = require_mapCacheGet();
      var mapCacheHas = require_mapCacheHas();
      var mapCacheSet = require_mapCacheSet();
      function MapCache(entries) {
        var index = -1, length = entries == null ? 0 : entries.length;
        this.clear();
        while (++index < length) {
          var entry = entries[index];
          this.set(entry[0], entry[1]);
        }
      }
      MapCache.prototype.clear = mapCacheClear;
      MapCache.prototype["delete"] = mapCacheDelete;
      MapCache.prototype.get = mapCacheGet;
      MapCache.prototype.has = mapCacheHas;
      MapCache.prototype.set = mapCacheSet;
      module.exports = MapCache;
    }
  });

  // node_modules/lodash/_stackSet.js
  var require_stackSet = __commonJS({
    "node_modules/lodash/_stackSet.js"(exports, module) {
      var ListCache = require_ListCache();
      var Map = require_Map();
      var MapCache = require_MapCache();
      var LARGE_ARRAY_SIZE = 200;
      function stackSet(key, value) {
        var data = this.__data__;
        if (data instanceof ListCache) {
          var pairs = data.__data__;
          if (!Map || pairs.length < LARGE_ARRAY_SIZE - 1) {
            pairs.push([key, value]);
            this.size = ++data.size;
            return this;
          }
          data = this.__data__ = new MapCache(pairs);
        }
        data.set(key, value);
        this.size = data.size;
        return this;
      }
      module.exports = stackSet;
    }
  });

  // node_modules/lodash/_Stack.js
  var require_Stack = __commonJS({
    "node_modules/lodash/_Stack.js"(exports, module) {
      var ListCache = require_ListCache();
      var stackClear = require_stackClear();
      var stackDelete = require_stackDelete();
      var stackGet = require_stackGet();
      var stackHas = require_stackHas();
      var stackSet = require_stackSet();
      function Stack(entries) {
        var data = this.__data__ = new ListCache(entries);
        this.size = data.size;
      }
      Stack.prototype.clear = stackClear;
      Stack.prototype["delete"] = stackDelete;
      Stack.prototype.get = stackGet;
      Stack.prototype.has = stackHas;
      Stack.prototype.set = stackSet;
      module.exports = Stack;
    }
  });

  // node_modules/lodash/_setCacheAdd.js
  var require_setCacheAdd = __commonJS({
    "node_modules/lodash/_setCacheAdd.js"(exports, module) {
      var HASH_UNDEFINED = "__lodash_hash_undefined__";
      function setCacheAdd(value) {
        this.__data__.set(value, HASH_UNDEFINED);
        return this;
      }
      module.exports = setCacheAdd;
    }
  });

  // node_modules/lodash/_setCacheHas.js
  var require_setCacheHas = __commonJS({
    "node_modules/lodash/_setCacheHas.js"(exports, module) {
      function setCacheHas(value) {
        return this.__data__.has(value);
      }
      module.exports = setCacheHas;
    }
  });

  // node_modules/lodash/_SetCache.js
  var require_SetCache = __commonJS({
    "node_modules/lodash/_SetCache.js"(exports, module) {
      var MapCache = require_MapCache();
      var setCacheAdd = require_setCacheAdd();
      var setCacheHas = require_setCacheHas();
      function SetCache(values) {
        var index = -1, length = values == null ? 0 : values.length;
        this.__data__ = new MapCache();
        while (++index < length) {
          this.add(values[index]);
        }
      }
      SetCache.prototype.add = SetCache.prototype.push = setCacheAdd;
      SetCache.prototype.has = setCacheHas;
      module.exports = SetCache;
    }
  });

  // node_modules/lodash/_arraySome.js
  var require_arraySome = __commonJS({
    "node_modules/lodash/_arraySome.js"(exports, module) {
      function arraySome(array, predicate) {
        var index = -1, length = array == null ? 0 : array.length;
        while (++index < length) {
          if (predicate(array[index], index, array)) {
            return true;
          }
        }
        return false;
      }
      module.exports = arraySome;
    }
  });

  // node_modules/lodash/_cacheHas.js
  var require_cacheHas = __commonJS({
    "node_modules/lodash/_cacheHas.js"(exports, module) {
      function cacheHas(cache, key) {
        return cache.has(key);
      }
      module.exports = cacheHas;
    }
  });

  // node_modules/lodash/_equalArrays.js
  var require_equalArrays = __commonJS({
    "node_modules/lodash/_equalArrays.js"(exports, module) {
      var SetCache = require_SetCache();
      var arraySome = require_arraySome();
      var cacheHas = require_cacheHas();
      var COMPARE_PARTIAL_FLAG = 1;
      var COMPARE_UNORDERED_FLAG = 2;
      function equalArrays(array, other, bitmask, customizer, equalFunc, stack) {
        var isPartial = bitmask & COMPARE_PARTIAL_FLAG, arrLength = array.length, othLength = other.length;
        if (arrLength != othLength && !(isPartial && othLength > arrLength)) {
          return false;
        }
        var arrStacked = stack.get(array);
        var othStacked = stack.get(other);
        if (arrStacked && othStacked) {
          return arrStacked == other && othStacked == array;
        }
        var index = -1, result = true, seen = bitmask & COMPARE_UNORDERED_FLAG ? new SetCache() : void 0;
        stack.set(array, other);
        stack.set(other, array);
        while (++index < arrLength) {
          var arrValue = array[index], othValue = other[index];
          if (customizer) {
            var compared = isPartial ? customizer(othValue, arrValue, index, other, array, stack) : customizer(arrValue, othValue, index, array, other, stack);
          }
          if (compared !== void 0) {
            if (compared) {
              continue;
            }
            result = false;
            break;
          }
          if (seen) {
            if (!arraySome(other, function(othValue2, othIndex) {
              if (!cacheHas(seen, othIndex) && (arrValue === othValue2 || equalFunc(arrValue, othValue2, bitmask, customizer, stack))) {
                return seen.push(othIndex);
              }
            })) {
              result = false;
              break;
            }
          } else if (!(arrValue === othValue || equalFunc(arrValue, othValue, bitmask, customizer, stack))) {
            result = false;
            break;
          }
        }
        stack["delete"](array);
        stack["delete"](other);
        return result;
      }
      module.exports = equalArrays;
    }
  });

  // node_modules/lodash/_Uint8Array.js
  var require_Uint8Array = __commonJS({
    "node_modules/lodash/_Uint8Array.js"(exports, module) {
      var root = require_root();
      var Uint8Array2 = root.Uint8Array;
      module.exports = Uint8Array2;
    }
  });

  // node_modules/lodash/_mapToArray.js
  var require_mapToArray = __commonJS({
    "node_modules/lodash/_mapToArray.js"(exports, module) {
      function mapToArray(map) {
        var index = -1, result = Array(map.size);
        map.forEach(function(value, key) {
          result[++index] = [key, value];
        });
        return result;
      }
      module.exports = mapToArray;
    }
  });

  // node_modules/lodash/_setToArray.js
  var require_setToArray = __commonJS({
    "node_modules/lodash/_setToArray.js"(exports, module) {
      function setToArray(set) {
        var index = -1, result = Array(set.size);
        set.forEach(function(value) {
          result[++index] = value;
        });
        return result;
      }
      module.exports = setToArray;
    }
  });

  // node_modules/lodash/_equalByTag.js
  var require_equalByTag = __commonJS({
    "node_modules/lodash/_equalByTag.js"(exports, module) {
      var Symbol2 = require_Symbol();
      var Uint8Array2 = require_Uint8Array();
      var eq = require_eq();
      var equalArrays = require_equalArrays();
      var mapToArray = require_mapToArray();
      var setToArray = require_setToArray();
      var COMPARE_PARTIAL_FLAG = 1;
      var COMPARE_UNORDERED_FLAG = 2;
      var boolTag = "[object Boolean]";
      var dateTag = "[object Date]";
      var errorTag = "[object Error]";
      var mapTag = "[object Map]";
      var numberTag = "[object Number]";
      var regexpTag = "[object RegExp]";
      var setTag = "[object Set]";
      var stringTag = "[object String]";
      var symbolTag = "[object Symbol]";
      var arrayBufferTag = "[object ArrayBuffer]";
      var dataViewTag = "[object DataView]";
      var symbolProto = Symbol2 ? Symbol2.prototype : void 0;
      var symbolValueOf = symbolProto ? symbolProto.valueOf : void 0;
      function equalByTag(object, other, tag, bitmask, customizer, equalFunc, stack) {
        switch (tag) {
          case dataViewTag:
            if (object.byteLength != other.byteLength || object.byteOffset != other.byteOffset) {
              return false;
            }
            object = object.buffer;
            other = other.buffer;
          case arrayBufferTag:
            if (object.byteLength != other.byteLength || !equalFunc(new Uint8Array2(object), new Uint8Array2(other))) {
              return false;
            }
            return true;
          case boolTag:
          case dateTag:
          case numberTag:
            return eq(+object, +other);
          case errorTag:
            return object.name == other.name && object.message == other.message;
          case regexpTag:
          case stringTag:
            return object == other + "";
          case mapTag:
            var convert = mapToArray;
          case setTag:
            var isPartial = bitmask & COMPARE_PARTIAL_FLAG;
            convert || (convert = setToArray);
            if (object.size != other.size && !isPartial) {
              return false;
            }
            var stacked = stack.get(object);
            if (stacked) {
              return stacked == other;
            }
            bitmask |= COMPARE_UNORDERED_FLAG;
            stack.set(object, other);
            var result = equalArrays(convert(object), convert(other), bitmask, customizer, equalFunc, stack);
            stack["delete"](object);
            return result;
          case symbolTag:
            if (symbolValueOf) {
              return symbolValueOf.call(object) == symbolValueOf.call(other);
            }
        }
        return false;
      }
      module.exports = equalByTag;
    }
  });

  // node_modules/lodash/_arrayPush.js
  var require_arrayPush = __commonJS({
    "node_modules/lodash/_arrayPush.js"(exports, module) {
      function arrayPush(array, values) {
        var index = -1, length = values.length, offset = array.length;
        while (++index < length) {
          array[offset + index] = values[index];
        }
        return array;
      }
      module.exports = arrayPush;
    }
  });

  // node_modules/lodash/isArray.js
  var require_isArray = __commonJS({
    "node_modules/lodash/isArray.js"(exports, module) {
      var isArray = Array.isArray;
      module.exports = isArray;
    }
  });

  // node_modules/lodash/_baseGetAllKeys.js
  var require_baseGetAllKeys = __commonJS({
    "node_modules/lodash/_baseGetAllKeys.js"(exports, module) {
      var arrayPush = require_arrayPush();
      var isArray = require_isArray();
      function baseGetAllKeys(object, keysFunc, symbolsFunc) {
        var result = keysFunc(object);
        return isArray(object) ? result : arrayPush(result, symbolsFunc(object));
      }
      module.exports = baseGetAllKeys;
    }
  });

  // node_modules/lodash/_arrayFilter.js
  var require_arrayFilter = __commonJS({
    "node_modules/lodash/_arrayFilter.js"(exports, module) {
      function arrayFilter(array, predicate) {
        var index = -1, length = array == null ? 0 : array.length, resIndex = 0, result = [];
        while (++index < length) {
          var value = array[index];
          if (predicate(value, index, array)) {
            result[resIndex++] = value;
          }
        }
        return result;
      }
      module.exports = arrayFilter;
    }
  });

  // node_modules/lodash/stubArray.js
  var require_stubArray = __commonJS({
    "node_modules/lodash/stubArray.js"(exports, module) {
      function stubArray() {
        return [];
      }
      module.exports = stubArray;
    }
  });

  // node_modules/lodash/_getSymbols.js
  var require_getSymbols = __commonJS({
    "node_modules/lodash/_getSymbols.js"(exports, module) {
      var arrayFilter = require_arrayFilter();
      var stubArray = require_stubArray();
      var objectProto = Object.prototype;
      var propertyIsEnumerable = objectProto.propertyIsEnumerable;
      var nativeGetSymbols = Object.getOwnPropertySymbols;
      var getSymbols = !nativeGetSymbols ? stubArray : function(object) {
        if (object == null) {
          return [];
        }
        object = Object(object);
        return arrayFilter(nativeGetSymbols(object), function(symbol) {
          return propertyIsEnumerable.call(object, symbol);
        });
      };
      module.exports = getSymbols;
    }
  });

  // node_modules/lodash/_baseTimes.js
  var require_baseTimes = __commonJS({
    "node_modules/lodash/_baseTimes.js"(exports, module) {
      function baseTimes(n, iteratee) {
        var index = -1, result = Array(n);
        while (++index < n) {
          result[index] = iteratee(index);
        }
        return result;
      }
      module.exports = baseTimes;
    }
  });

  // node_modules/lodash/isObjectLike.js
  var require_isObjectLike = __commonJS({
    "node_modules/lodash/isObjectLike.js"(exports, module) {
      function isObjectLike(value) {
        return value != null && typeof value == "object";
      }
      module.exports = isObjectLike;
    }
  });

  // node_modules/lodash/_baseIsArguments.js
  var require_baseIsArguments = __commonJS({
    "node_modules/lodash/_baseIsArguments.js"(exports, module) {
      var baseGetTag = require_baseGetTag();
      var isObjectLike = require_isObjectLike();
      var argsTag = "[object Arguments]";
      function baseIsArguments(value) {
        return isObjectLike(value) && baseGetTag(value) == argsTag;
      }
      module.exports = baseIsArguments;
    }
  });

  // node_modules/lodash/isArguments.js
  var require_isArguments = __commonJS({
    "node_modules/lodash/isArguments.js"(exports, module) {
      var baseIsArguments = require_baseIsArguments();
      var isObjectLike = require_isObjectLike();
      var objectProto = Object.prototype;
      var hasOwnProperty = objectProto.hasOwnProperty;
      var propertyIsEnumerable = objectProto.propertyIsEnumerable;
      var isArguments = baseIsArguments(function() {
        return arguments;
      }()) ? baseIsArguments : function(value) {
        return isObjectLike(value) && hasOwnProperty.call(value, "callee") && !propertyIsEnumerable.call(value, "callee");
      };
      module.exports = isArguments;
    }
  });

  // node_modules/lodash/stubFalse.js
  var require_stubFalse = __commonJS({
    "node_modules/lodash/stubFalse.js"(exports, module) {
      function stubFalse() {
        return false;
      }
      module.exports = stubFalse;
    }
  });

  // node_modules/lodash/isBuffer.js
  var require_isBuffer = __commonJS({
    "node_modules/lodash/isBuffer.js"(exports, module) {
      var root = require_root();
      var stubFalse = require_stubFalse();
      var freeExports = typeof exports == "object" && exports && !exports.nodeType && exports;
      var freeModule = freeExports && typeof module == "object" && module && !module.nodeType && module;
      var moduleExports = freeModule && freeModule.exports === freeExports;
      var Buffer2 = moduleExports ? root.Buffer : void 0;
      var nativeIsBuffer = Buffer2 ? Buffer2.isBuffer : void 0;
      var isBuffer = nativeIsBuffer || stubFalse;
      module.exports = isBuffer;
    }
  });

  // node_modules/lodash/_isIndex.js
  var require_isIndex = __commonJS({
    "node_modules/lodash/_isIndex.js"(exports, module) {
      var MAX_SAFE_INTEGER = 9007199254740991;
      var reIsUint = /^(?:0|[1-9]\d*)$/;
      function isIndex(value, length) {
        var type4 = typeof value;
        length = length == null ? MAX_SAFE_INTEGER : length;
        return !!length && (type4 == "number" || type4 != "symbol" && reIsUint.test(value)) && (value > -1 && value % 1 == 0 && value < length);
      }
      module.exports = isIndex;
    }
  });

  // node_modules/lodash/isLength.js
  var require_isLength = __commonJS({
    "node_modules/lodash/isLength.js"(exports, module) {
      var MAX_SAFE_INTEGER = 9007199254740991;
      function isLength(value) {
        return typeof value == "number" && value > -1 && value % 1 == 0 && value <= MAX_SAFE_INTEGER;
      }
      module.exports = isLength;
    }
  });

  // node_modules/lodash/_baseIsTypedArray.js
  var require_baseIsTypedArray = __commonJS({
    "node_modules/lodash/_baseIsTypedArray.js"(exports, module) {
      var baseGetTag = require_baseGetTag();
      var isLength = require_isLength();
      var isObjectLike = require_isObjectLike();
      var argsTag = "[object Arguments]";
      var arrayTag = "[object Array]";
      var boolTag = "[object Boolean]";
      var dateTag = "[object Date]";
      var errorTag = "[object Error]";
      var funcTag = "[object Function]";
      var mapTag = "[object Map]";
      var numberTag = "[object Number]";
      var objectTag = "[object Object]";
      var regexpTag = "[object RegExp]";
      var setTag = "[object Set]";
      var stringTag = "[object String]";
      var weakMapTag = "[object WeakMap]";
      var arrayBufferTag = "[object ArrayBuffer]";
      var dataViewTag = "[object DataView]";
      var float32Tag = "[object Float32Array]";
      var float64Tag = "[object Float64Array]";
      var int8Tag = "[object Int8Array]";
      var int16Tag = "[object Int16Array]";
      var int32Tag = "[object Int32Array]";
      var uint8Tag = "[object Uint8Array]";
      var uint8ClampedTag = "[object Uint8ClampedArray]";
      var uint16Tag = "[object Uint16Array]";
      var uint32Tag = "[object Uint32Array]";
      var typedArrayTags = {};
      typedArrayTags[float32Tag] = typedArrayTags[float64Tag] = typedArrayTags[int8Tag] = typedArrayTags[int16Tag] = typedArrayTags[int32Tag] = typedArrayTags[uint8Tag] = typedArrayTags[uint8ClampedTag] = typedArrayTags[uint16Tag] = typedArrayTags[uint32Tag] = true;
      typedArrayTags[argsTag] = typedArrayTags[arrayTag] = typedArrayTags[arrayBufferTag] = typedArrayTags[boolTag] = typedArrayTags[dataViewTag] = typedArrayTags[dateTag] = typedArrayTags[errorTag] = typedArrayTags[funcTag] = typedArrayTags[mapTag] = typedArrayTags[numberTag] = typedArrayTags[objectTag] = typedArrayTags[regexpTag] = typedArrayTags[setTag] = typedArrayTags[stringTag] = typedArrayTags[weakMapTag] = false;
      function baseIsTypedArray(value) {
        return isObjectLike(value) && isLength(value.length) && !!typedArrayTags[baseGetTag(value)];
      }
      module.exports = baseIsTypedArray;
    }
  });

  // node_modules/lodash/_baseUnary.js
  var require_baseUnary = __commonJS({
    "node_modules/lodash/_baseUnary.js"(exports, module) {
      function baseUnary(func) {
        return function(value) {
          return func(value);
        };
      }
      module.exports = baseUnary;
    }
  });

  // node_modules/lodash/_nodeUtil.js
  var require_nodeUtil = __commonJS({
    "node_modules/lodash/_nodeUtil.js"(exports, module) {
      var freeGlobal = require_freeGlobal();
      var freeExports = typeof exports == "object" && exports && !exports.nodeType && exports;
      var freeModule = freeExports && typeof module == "object" && module && !module.nodeType && module;
      var moduleExports = freeModule && freeModule.exports === freeExports;
      var freeProcess = moduleExports && freeGlobal.process;
      var nodeUtil = function() {
        try {
          var types = freeModule && freeModule.require && freeModule.require("util").types;
          if (types) {
            return types;
          }
          return freeProcess && freeProcess.binding && freeProcess.binding("util");
        } catch (e) {
        }
      }();
      module.exports = nodeUtil;
    }
  });

  // node_modules/lodash/isTypedArray.js
  var require_isTypedArray = __commonJS({
    "node_modules/lodash/isTypedArray.js"(exports, module) {
      var baseIsTypedArray = require_baseIsTypedArray();
      var baseUnary = require_baseUnary();
      var nodeUtil = require_nodeUtil();
      var nodeIsTypedArray = nodeUtil && nodeUtil.isTypedArray;
      var isTypedArray = nodeIsTypedArray ? baseUnary(nodeIsTypedArray) : baseIsTypedArray;
      module.exports = isTypedArray;
    }
  });

  // node_modules/lodash/_arrayLikeKeys.js
  var require_arrayLikeKeys = __commonJS({
    "node_modules/lodash/_arrayLikeKeys.js"(exports, module) {
      var baseTimes = require_baseTimes();
      var isArguments = require_isArguments();
      var isArray = require_isArray();
      var isBuffer = require_isBuffer();
      var isIndex = require_isIndex();
      var isTypedArray = require_isTypedArray();
      var objectProto = Object.prototype;
      var hasOwnProperty = objectProto.hasOwnProperty;
      function arrayLikeKeys(value, inherited) {
        var isArr = isArray(value), isArg = !isArr && isArguments(value), isBuff = !isArr && !isArg && isBuffer(value), isType = !isArr && !isArg && !isBuff && isTypedArray(value), skipIndexes = isArr || isArg || isBuff || isType, result = skipIndexes ? baseTimes(value.length, String) : [], length = result.length;
        for (var key in value) {
          if ((inherited || hasOwnProperty.call(value, key)) && !(skipIndexes && (key == "length" || isBuff && (key == "offset" || key == "parent") || isType && (key == "buffer" || key == "byteLength" || key == "byteOffset") || isIndex(key, length)))) {
            result.push(key);
          }
        }
        return result;
      }
      module.exports = arrayLikeKeys;
    }
  });

  // node_modules/lodash/_isPrototype.js
  var require_isPrototype = __commonJS({
    "node_modules/lodash/_isPrototype.js"(exports, module) {
      var objectProto = Object.prototype;
      function isPrototype(value) {
        var Ctor = value && value.constructor, proto = typeof Ctor == "function" && Ctor.prototype || objectProto;
        return value === proto;
      }
      module.exports = isPrototype;
    }
  });

  // node_modules/lodash/_overArg.js
  var require_overArg = __commonJS({
    "node_modules/lodash/_overArg.js"(exports, module) {
      function overArg(func, transform) {
        return function(arg) {
          return func(transform(arg));
        };
      }
      module.exports = overArg;
    }
  });

  // node_modules/lodash/_nativeKeys.js
  var require_nativeKeys = __commonJS({
    "node_modules/lodash/_nativeKeys.js"(exports, module) {
      var overArg = require_overArg();
      var nativeKeys = overArg(Object.keys, Object);
      module.exports = nativeKeys;
    }
  });

  // node_modules/lodash/_baseKeys.js
  var require_baseKeys = __commonJS({
    "node_modules/lodash/_baseKeys.js"(exports, module) {
      var isPrototype = require_isPrototype();
      var nativeKeys = require_nativeKeys();
      var objectProto = Object.prototype;
      var hasOwnProperty = objectProto.hasOwnProperty;
      function baseKeys(object) {
        if (!isPrototype(object)) {
          return nativeKeys(object);
        }
        var result = [];
        for (var key in Object(object)) {
          if (hasOwnProperty.call(object, key) && key != "constructor") {
            result.push(key);
          }
        }
        return result;
      }
      module.exports = baseKeys;
    }
  });

  // node_modules/lodash/isArrayLike.js
  var require_isArrayLike = __commonJS({
    "node_modules/lodash/isArrayLike.js"(exports, module) {
      var isFunction = require_isFunction();
      var isLength = require_isLength();
      function isArrayLike(value) {
        return value != null && isLength(value.length) && !isFunction(value);
      }
      module.exports = isArrayLike;
    }
  });

  // node_modules/lodash/keys.js
  var require_keys = __commonJS({
    "node_modules/lodash/keys.js"(exports, module) {
      var arrayLikeKeys = require_arrayLikeKeys();
      var baseKeys = require_baseKeys();
      var isArrayLike = require_isArrayLike();
      function keys(object) {
        return isArrayLike(object) ? arrayLikeKeys(object) : baseKeys(object);
      }
      module.exports = keys;
    }
  });

  // node_modules/lodash/_getAllKeys.js
  var require_getAllKeys = __commonJS({
    "node_modules/lodash/_getAllKeys.js"(exports, module) {
      var baseGetAllKeys = require_baseGetAllKeys();
      var getSymbols = require_getSymbols();
      var keys = require_keys();
      function getAllKeys(object) {
        return baseGetAllKeys(object, keys, getSymbols);
      }
      module.exports = getAllKeys;
    }
  });

  // node_modules/lodash/_equalObjects.js
  var require_equalObjects = __commonJS({
    "node_modules/lodash/_equalObjects.js"(exports, module) {
      var getAllKeys = require_getAllKeys();
      var COMPARE_PARTIAL_FLAG = 1;
      var objectProto = Object.prototype;
      var hasOwnProperty = objectProto.hasOwnProperty;
      function equalObjects(object, other, bitmask, customizer, equalFunc, stack) {
        var isPartial = bitmask & COMPARE_PARTIAL_FLAG, objProps = getAllKeys(object), objLength = objProps.length, othProps = getAllKeys(other), othLength = othProps.length;
        if (objLength != othLength && !isPartial) {
          return false;
        }
        var index = objLength;
        while (index--) {
          var key = objProps[index];
          if (!(isPartial ? key in other : hasOwnProperty.call(other, key))) {
            return false;
          }
        }
        var objStacked = stack.get(object);
        var othStacked = stack.get(other);
        if (objStacked && othStacked) {
          return objStacked == other && othStacked == object;
        }
        var result = true;
        stack.set(object, other);
        stack.set(other, object);
        var skipCtor = isPartial;
        while (++index < objLength) {
          key = objProps[index];
          var objValue = object[key], othValue = other[key];
          if (customizer) {
            var compared = isPartial ? customizer(othValue, objValue, key, other, object, stack) : customizer(objValue, othValue, key, object, other, stack);
          }
          if (!(compared === void 0 ? objValue === othValue || equalFunc(objValue, othValue, bitmask, customizer, stack) : compared)) {
            result = false;
            break;
          }
          skipCtor || (skipCtor = key == "constructor");
        }
        if (result && !skipCtor) {
          var objCtor = object.constructor, othCtor = other.constructor;
          if (objCtor != othCtor && ("constructor" in object && "constructor" in other) && !(typeof objCtor == "function" && objCtor instanceof objCtor && typeof othCtor == "function" && othCtor instanceof othCtor)) {
            result = false;
          }
        }
        stack["delete"](object);
        stack["delete"](other);
        return result;
      }
      module.exports = equalObjects;
    }
  });

  // node_modules/lodash/_DataView.js
  var require_DataView = __commonJS({
    "node_modules/lodash/_DataView.js"(exports, module) {
      var getNative = require_getNative();
      var root = require_root();
      var DataView = getNative(root, "DataView");
      module.exports = DataView;
    }
  });

  // node_modules/lodash/_Promise.js
  var require_Promise = __commonJS({
    "node_modules/lodash/_Promise.js"(exports, module) {
      var getNative = require_getNative();
      var root = require_root();
      var Promise2 = getNative(root, "Promise");
      module.exports = Promise2;
    }
  });

  // node_modules/lodash/_Set.js
  var require_Set = __commonJS({
    "node_modules/lodash/_Set.js"(exports, module) {
      var getNative = require_getNative();
      var root = require_root();
      var Set = getNative(root, "Set");
      module.exports = Set;
    }
  });

  // node_modules/lodash/_WeakMap.js
  var require_WeakMap = __commonJS({
    "node_modules/lodash/_WeakMap.js"(exports, module) {
      var getNative = require_getNative();
      var root = require_root();
      var WeakMap = getNative(root, "WeakMap");
      module.exports = WeakMap;
    }
  });

  // node_modules/lodash/_getTag.js
  var require_getTag = __commonJS({
    "node_modules/lodash/_getTag.js"(exports, module) {
      var DataView = require_DataView();
      var Map = require_Map();
      var Promise2 = require_Promise();
      var Set = require_Set();
      var WeakMap = require_WeakMap();
      var baseGetTag = require_baseGetTag();
      var toSource = require_toSource();
      var mapTag = "[object Map]";
      var objectTag = "[object Object]";
      var promiseTag = "[object Promise]";
      var setTag = "[object Set]";
      var weakMapTag = "[object WeakMap]";
      var dataViewTag = "[object DataView]";
      var dataViewCtorString = toSource(DataView);
      var mapCtorString = toSource(Map);
      var promiseCtorString = toSource(Promise2);
      var setCtorString = toSource(Set);
      var weakMapCtorString = toSource(WeakMap);
      var getTag = baseGetTag;
      if (DataView && getTag(new DataView(new ArrayBuffer(1))) != dataViewTag || Map && getTag(new Map()) != mapTag || Promise2 && getTag(Promise2.resolve()) != promiseTag || Set && getTag(new Set()) != setTag || WeakMap && getTag(new WeakMap()) != weakMapTag) {
        getTag = function(value) {
          var result = baseGetTag(value), Ctor = result == objectTag ? value.constructor : void 0, ctorString = Ctor ? toSource(Ctor) : "";
          if (ctorString) {
            switch (ctorString) {
              case dataViewCtorString:
                return dataViewTag;
              case mapCtorString:
                return mapTag;
              case promiseCtorString:
                return promiseTag;
              case setCtorString:
                return setTag;
              case weakMapCtorString:
                return weakMapTag;
            }
          }
          return result;
        };
      }
      module.exports = getTag;
    }
  });

  // node_modules/lodash/_baseIsEqualDeep.js
  var require_baseIsEqualDeep = __commonJS({
    "node_modules/lodash/_baseIsEqualDeep.js"(exports, module) {
      var Stack = require_Stack();
      var equalArrays = require_equalArrays();
      var equalByTag = require_equalByTag();
      var equalObjects = require_equalObjects();
      var getTag = require_getTag();
      var isArray = require_isArray();
      var isBuffer = require_isBuffer();
      var isTypedArray = require_isTypedArray();
      var COMPARE_PARTIAL_FLAG = 1;
      var argsTag = "[object Arguments]";
      var arrayTag = "[object Array]";
      var objectTag = "[object Object]";
      var objectProto = Object.prototype;
      var hasOwnProperty = objectProto.hasOwnProperty;
      function baseIsEqualDeep(object, other, bitmask, customizer, equalFunc, stack) {
        var objIsArr = isArray(object), othIsArr = isArray(other), objTag = objIsArr ? arrayTag : getTag(object), othTag = othIsArr ? arrayTag : getTag(other);
        objTag = objTag == argsTag ? objectTag : objTag;
        othTag = othTag == argsTag ? objectTag : othTag;
        var objIsObj = objTag == objectTag, othIsObj = othTag == objectTag, isSameTag = objTag == othTag;
        if (isSameTag && isBuffer(object)) {
          if (!isBuffer(other)) {
            return false;
          }
          objIsArr = true;
          objIsObj = false;
        }
        if (isSameTag && !objIsObj) {
          stack || (stack = new Stack());
          return objIsArr || isTypedArray(object) ? equalArrays(object, other, bitmask, customizer, equalFunc, stack) : equalByTag(object, other, objTag, bitmask, customizer, equalFunc, stack);
        }
        if (!(bitmask & COMPARE_PARTIAL_FLAG)) {
          var objIsWrapped = objIsObj && hasOwnProperty.call(object, "__wrapped__"), othIsWrapped = othIsObj && hasOwnProperty.call(other, "__wrapped__");
          if (objIsWrapped || othIsWrapped) {
            var objUnwrapped = objIsWrapped ? object.value() : object, othUnwrapped = othIsWrapped ? other.value() : other;
            stack || (stack = new Stack());
            return equalFunc(objUnwrapped, othUnwrapped, bitmask, customizer, stack);
          }
        }
        if (!isSameTag) {
          return false;
        }
        stack || (stack = new Stack());
        return equalObjects(object, other, bitmask, customizer, equalFunc, stack);
      }
      module.exports = baseIsEqualDeep;
    }
  });

  // node_modules/lodash/_baseIsEqual.js
  var require_baseIsEqual = __commonJS({
    "node_modules/lodash/_baseIsEqual.js"(exports, module) {
      var baseIsEqualDeep = require_baseIsEqualDeep();
      var isObjectLike = require_isObjectLike();
      function baseIsEqual(value, other, bitmask, customizer, stack) {
        if (value === other) {
          return true;
        }
        if (value == null || other == null || !isObjectLike(value) && !isObjectLike(other)) {
          return value !== value && other !== other;
        }
        return baseIsEqualDeep(value, other, bitmask, customizer, baseIsEqual, stack);
      }
      module.exports = baseIsEqual;
    }
  });

  // node_modules/lodash/isEqual.js
  var require_isEqual = __commonJS({
    "node_modules/lodash/isEqual.js"(exports, module) {
      var baseIsEqual = require_baseIsEqual();
      function isEqual2(value, other) {
        return baseIsEqual(value, other);
      }
      module.exports = isEqual2;
    }
  });

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/index.ts
  var source_exports = {};
  __export(source_exports, {
    call: () => call,
    dmFunctions: () => dmFunctions,
    runDmLookupTests: () => runTests,
    testing: () => testing2
  });
  var import_ajv = __toModule(require_ajv());
  var import_isEqual = __toModule(require_isEqual());

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/types/DocumentSchema.ts
  var _State;
  (function(_State3) {
    _State3[_State3["AK"] = 0] = "AK";
    _State3[_State3["AL"] = 1] = "AL";
    _State3[_State3["AR"] = 2] = "AR";
    _State3[_State3["AS"] = 3] = "AS";
    _State3[_State3["AZ"] = 4] = "AZ";
    _State3[_State3["CA"] = 5] = "CA";
    _State3[_State3["CT"] = 6] = "CT";
    _State3[_State3["CO"] = 7] = "CO";
    _State3[_State3["DC"] = 8] = "DC";
    _State3[_State3["DE"] = 9] = "DE";
    _State3[_State3["FL"] = 10] = "FL";
    _State3[_State3["GA"] = 11] = "GA";
    _State3[_State3["GU"] = 12] = "GU";
    _State3[_State3["HI"] = 13] = "HI";
    _State3[_State3["ID"] = 14] = "ID";
    _State3[_State3["IL"] = 15] = "IL";
    _State3[_State3["IA"] = 16] = "IA";
    _State3[_State3["IN"] = 17] = "IN";
    _State3[_State3["KS"] = 18] = "KS";
    _State3[_State3["KY"] = 19] = "KY";
    _State3[_State3["LA"] = 20] = "LA";
    _State3[_State3["MS"] = 21] = "MS";
    _State3[_State3["MT"] = 22] = "MT";
    _State3[_State3["MA"] = 23] = "MA";
    _State3[_State3["MD"] = 24] = "MD";
    _State3[_State3["ME"] = 25] = "ME";
    _State3[_State3["MI"] = 26] = "MI";
    _State3[_State3["MN"] = 27] = "MN";
    _State3[_State3["MO"] = 28] = "MO";
    _State3[_State3["NC"] = 29] = "NC";
    _State3[_State3["ND"] = 30] = "ND";
    _State3[_State3["NE"] = 31] = "NE";
    _State3[_State3["NH"] = 32] = "NH";
    _State3[_State3["NJ"] = 33] = "NJ";
    _State3[_State3["NM"] = 34] = "NM";
    _State3[_State3["NV"] = 35] = "NV";
    _State3[_State3["NY"] = 36] = "NY";
    _State3[_State3["OH"] = 37] = "OH";
    _State3[_State3["OK"] = 38] = "OK";
    _State3[_State3["OR"] = 39] = "OR";
    _State3[_State3["PR"] = 40] = "PR";
    _State3[_State3["PA"] = 41] = "PA";
    _State3[_State3["RI"] = 42] = "RI";
    _State3[_State3["SD"] = 43] = "SD";
    _State3[_State3["SC"] = 44] = "SC";
    _State3[_State3["TN"] = 45] = "TN";
    _State3[_State3["TX"] = 46] = "TX";
    _State3[_State3["UT"] = 47] = "UT";
    _State3[_State3["VT"] = 48] = "VT";
    _State3[_State3["VA"] = 49] = "VA";
    _State3[_State3["VI"] = 50] = "VI";
    _State3[_State3["WA"] = 51] = "WA";
    _State3[_State3["WI"] = 52] = "WI";
    _State3[_State3["WV"] = 53] = "WV";
    _State3[_State3["WY"] = 54] = "WY";
  })(_State || (_State = {}));
  function a(typ) {
    return { arrayItems: typ };
  }
  function u(...typs) {
    return { unionMembers: typs };
  }
  function o(props, additional) {
    return { props, additional };
  }
  function r(name) {
    return { ref: name };
  }
  var typeMap = {
    "DocumentSchema": o([
      { json: "order", js: "order", typ: r("Order") },
      { json: "total_price", js: "total_price", typ: 3.14 },
      { json: "users", js: "users", typ: a(r("UserElement")) }
    ], "any"),
    "Order": o([
      { json: "products", js: "products", typ: a(r("ProductElement")) },
      { json: "total_price", js: "total_price", typ: 3.14 }
    ], "any"),
    "ProductElement": o([
      { json: "amount", js: "amount", typ: 3.14 },
      { json: "name", js: "name", typ: "" },
      { json: "price", js: "price", typ: u(void 0, 3.14) }
    ], "any"),
    "UserElement": o([
      { json: "age", js: "age", typ: 3.14 },
      { json: "firstname", js: "firstname", typ: "" },
      { json: "lastname", js: "lastname", typ: "" },
      { json: "state", js: "state", typ: r("State") }
    ], "any"),
    "State": [
      "AK",
      "AL",
      "AR",
      "AS",
      "AZ",
      "CA",
      "CT",
      "CO",
      "DC",
      "DE",
      "FL",
      "GA",
      "GU",
      "HI",
      "ID",
      "IL",
      "IA",
      "IN",
      "KS",
      "KY",
      "LA",
      "MS",
      "MT",
      "MA",
      "MD",
      "ME",
      "MI",
      "MN",
      "MO",
      "NC",
      "ND",
      "NE",
      "NH",
      "NJ",
      "NM",
      "NV",
      "NY",
      "OH",
      "OK",
      "OR",
      "PR",
      "PA",
      "RI",
      "SD",
      "SC",
      "TN",
      "TX",
      "UT",
      "VT",
      "VA",
      "VI",
      "WA",
      "WI",
      "WV",
      "WY"
    ]
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/types/RuleResultSchema.ts
  function o2(props, additional) {
    return { props, additional };
  }
  var typeMap2 = {
    "RuleResultSchema": o2([
      { json: "total_price", js: "total_price", typ: 3.14 }
    ], "any")
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/types/DocumentSchema.json
  var $id = "DocumentSchema.json";
  var description = "Document Data Schema";
  var type = "object";
  var properties = {
    users: {
      $ref: "Definitions.json#/properties/Users"
    },
    total_price: {
      $ref: "Definitions.json#/properties/TotalPrice"
    },
    order: {
      $ref: "Definitions.json#/properties/Order"
    }
  };
  var required = [
    "users",
    "total_price",
    "order"
  ];
  var DocumentSchema_default = {
    $id,
    description,
    type,
    properties,
    required
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/types/Definitions.json
  var $id2 = "Definitions.json";
  var description2 = "Schema definitions";
  var type2 = "object";
  var properties2 = {
    TotalPrice: {
      type: "number",
      minimum: 0
    },
    Users: {
      type: "array",
      items: {
        $ref: "#/properties/User"
      }
    },
    User: {
      type: "object",
      required: [
        "firstname",
        "lastname",
        "age",
        "state"
      ],
      properties: {
        firstname: {
          type: "string"
        },
        lastname: {
          type: "string"
        },
        age: {
          type: "number",
          minimum: 0,
          maximum: 130
        },
        state: {
          $ref: "#/properties/State"
        }
      }
    },
    Product: {
      type: "object",
      required: [
        "name",
        "amount"
      ],
      properties: {
        name: {
          type: "string"
        },
        price: {
          type: "number",
          minumum: 0
        },
        amount: {
          type: "number",
          minumum: 0
        }
      }
    },
    Products: {
      type: "array",
      minItems: 1,
      maxItems: 10,
      items: {
        $ref: "#/properties/Product"
      }
    },
    Order: {
      type: "object",
      required: [
        "total_price",
        "products"
      ],
      properties: {
        total_price: {
          type: "number",
          minumum: 0
        },
        products: {
          $ref: "#/properties/Products"
        }
      }
    },
    State: {
      type: "string",
      enum: [
        "AL",
        "AK",
        "AZ",
        "AR",
        "CA",
        "CO",
        "CT",
        "DE",
        "DC",
        "FL",
        "GA",
        "HI",
        "ID",
        "IL",
        "IN",
        "IA",
        "KS",
        "KY",
        "LA",
        "ME",
        "MD",
        "MA",
        "MI",
        "MN",
        "MS",
        "MO",
        "MT",
        "NE",
        "NV",
        "NH",
        "NJ",
        "NM",
        "NY",
        "NC",
        "ND",
        "OH",
        "OK",
        "OR",
        "PA",
        "RI",
        "SC",
        "SD",
        "TN",
        "TX",
        "UT",
        "VT",
        "VA",
        "WA",
        "WV",
        "WI",
        "WY",
        "AS",
        "GU",
        "PR",
        "VI"
      ]
    }
  };
  var Definitions_default = {
    $id: $id2,
    description: description2,
    type: type2,
    properties: properties2
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/types/RuleResultSchema.json
  var $id3 = "RuleResult.json";
  var description3 = "Rule Result Schema";
  var type3 = "object";
  var properties3 = {
    total_price: {
      $ref: "Definitions.json#/properties/TotalPrice",
      minimum: 10
    }
  };
  var required2 = [
    "total_price"
  ];
  var RuleResultSchema_default = {
    $id: $id3,
    description: description3,
    type: type3,
    properties: properties3,
    required: required2
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/types/Definitions.ts
  var _State2;
  (function(_State3) {
    _State3[_State3["AK"] = 0] = "AK";
    _State3[_State3["AL"] = 1] = "AL";
    _State3[_State3["AR"] = 2] = "AR";
    _State3[_State3["AS"] = 3] = "AS";
    _State3[_State3["AZ"] = 4] = "AZ";
    _State3[_State3["CA"] = 5] = "CA";
    _State3[_State3["CT"] = 6] = "CT";
    _State3[_State3["CO"] = 7] = "CO";
    _State3[_State3["DC"] = 8] = "DC";
    _State3[_State3["DE"] = 9] = "DE";
    _State3[_State3["FL"] = 10] = "FL";
    _State3[_State3["GA"] = 11] = "GA";
    _State3[_State3["GU"] = 12] = "GU";
    _State3[_State3["HI"] = 13] = "HI";
    _State3[_State3["ID"] = 14] = "ID";
    _State3[_State3["IL"] = 15] = "IL";
    _State3[_State3["IA"] = 16] = "IA";
    _State3[_State3["IN"] = 17] = "IN";
    _State3[_State3["KS"] = 18] = "KS";
    _State3[_State3["KY"] = 19] = "KY";
    _State3[_State3["LA"] = 20] = "LA";
    _State3[_State3["MS"] = 21] = "MS";
    _State3[_State3["MT"] = 22] = "MT";
    _State3[_State3["MA"] = 23] = "MA";
    _State3[_State3["MD"] = 24] = "MD";
    _State3[_State3["ME"] = 25] = "ME";
    _State3[_State3["MI"] = 26] = "MI";
    _State3[_State3["MN"] = 27] = "MN";
    _State3[_State3["MO"] = 28] = "MO";
    _State3[_State3["NC"] = 29] = "NC";
    _State3[_State3["ND"] = 30] = "ND";
    _State3[_State3["NE"] = 31] = "NE";
    _State3[_State3["NH"] = 32] = "NH";
    _State3[_State3["NJ"] = 33] = "NJ";
    _State3[_State3["NM"] = 34] = "NM";
    _State3[_State3["NV"] = 35] = "NV";
    _State3[_State3["NY"] = 36] = "NY";
    _State3[_State3["OH"] = 37] = "OH";
    _State3[_State3["OK"] = 38] = "OK";
    _State3[_State3["OR"] = 39] = "OR";
    _State3[_State3["PR"] = 40] = "PR";
    _State3[_State3["PA"] = 41] = "PA";
    _State3[_State3["RI"] = 42] = "RI";
    _State3[_State3["SD"] = 43] = "SD";
    _State3[_State3["SC"] = 44] = "SC";
    _State3[_State3["TN"] = 45] = "TN";
    _State3[_State3["TX"] = 46] = "TX";
    _State3[_State3["UT"] = 47] = "UT";
    _State3[_State3["VT"] = 48] = "VT";
    _State3[_State3["VA"] = 49] = "VA";
    _State3[_State3["VI"] = 50] = "VI";
    _State3[_State3["WA"] = 51] = "WA";
    _State3[_State3["WI"] = 52] = "WI";
    _State3[_State3["WV"] = 53] = "WV";
    _State3[_State3["WY"] = 54] = "WY";
  })(_State2 || (_State2 = {}));
  function a2(typ) {
    return { arrayItems: typ };
  }
  function u2(...typs) {
    return { unionMembers: typs };
  }
  function o3(props, additional) {
    return { props, additional };
  }
  function r2(name) {
    return { ref: name };
  }
  var typeMap3 = {
    "Definitions": o3([
      { json: "Order", js: "Order", typ: u2(void 0, r2("Order")) },
      { json: "Product", js: "Product", typ: u2(void 0, r2("Product")) },
      { json: "Products", js: "Products", typ: u2(void 0, a2(r2("ProductElement"))) },
      { json: "State", js: "State", typ: u2(void 0, r2("State")) },
      { json: "TotalPrice", js: "TotalPrice", typ: u2(void 0, 3.14) },
      { json: "User", js: "User", typ: u2(void 0, r2("User")) },
      { json: "Users", js: "Users", typ: u2(void 0, a2(r2("UserElement"))) }
    ], "any"),
    "Order": o3([
      { json: "products", js: "products", typ: a2(r2("ProductElement")) },
      { json: "total_price", js: "total_price", typ: 3.14 }
    ], "any"),
    "ProductElement": o3([
      { json: "amount", js: "amount", typ: 3.14 },
      { json: "name", js: "name", typ: "" },
      { json: "price", js: "price", typ: u2(void 0, 3.14) }
    ], "any"),
    "Product": o3([
      { json: "amount", js: "amount", typ: 3.14 },
      { json: "name", js: "name", typ: "" },
      { json: "price", js: "price", typ: u2(void 0, 3.14) }
    ], "any"),
    "User": o3([
      { json: "age", js: "age", typ: 3.14 },
      { json: "firstname", js: "firstname", typ: "" },
      { json: "lastname", js: "lastname", typ: "" },
      { json: "state", js: "state", typ: r2("State") }
    ], "any"),
    "UserElement": o3([
      { json: "age", js: "age", typ: 3.14 },
      { json: "firstname", js: "firstname", typ: "" },
      { json: "lastname", js: "lastname", typ: "" },
      { json: "state", js: "state", typ: r2("State") }
    ], "any"),
    "State": [
      "AK",
      "AL",
      "AR",
      "AS",
      "AZ",
      "CA",
      "CT",
      "CO",
      "DC",
      "DE",
      "FL",
      "GA",
      "GU",
      "HI",
      "ID",
      "IL",
      "IA",
      "IN",
      "KS",
      "KY",
      "LA",
      "MS",
      "MT",
      "MA",
      "MD",
      "ME",
      "MI",
      "MN",
      "MO",
      "NC",
      "ND",
      "NE",
      "NH",
      "NJ",
      "NM",
      "NV",
      "NY",
      "OH",
      "OK",
      "OR",
      "PR",
      "PA",
      "RI",
      "SD",
      "SC",
      "TN",
      "TX",
      "UT",
      "VT",
      "VA",
      "VI",
      "WA",
      "WI",
      "WV",
      "WY"
    ]
  };

  // node_modules/@flatten-js/interval-tree/dist/main.esm.js
  var Interval = class Interval2 {
    constructor(low, high) {
      this.low = low;
      this.high = high;
    }
    clone() {
      return new Interval2(this.low, this.high);
    }
    get max() {
      return this.clone();
    }
    less_than(other_interval) {
      return this.low < other_interval.low || this.low == other_interval.low && this.high < other_interval.high;
    }
    equal_to(other_interval) {
      return this.low == other_interval.low && this.high == other_interval.high;
    }
    intersect(other_interval) {
      return !this.not_intersect(other_interval);
    }
    not_intersect(other_interval) {
      return this.high < other_interval.low || other_interval.high < this.low;
    }
    merge(other_interval) {
      return new Interval2(this.low === void 0 ? other_interval.low : Math.min(this.low, other_interval.low), this.high === void 0 ? other_interval.high : Math.max(this.high, other_interval.high));
    }
    output() {
      return [this.low, this.high];
    }
    static comparable_max(interval1, interval2) {
      return interval1.merge(interval2);
    }
    static comparable_less_than(val1, val2) {
      return val1 < val2;
    }
  };
  var RB_TREE_COLOR_RED = 0;
  var RB_TREE_COLOR_BLACK = 1;
  var Node = class {
    constructor(key = void 0, value = void 0, left = null, right = null, parent = null, color = RB_TREE_COLOR_BLACK) {
      this.left = left;
      this.right = right;
      this.parent = parent;
      this.color = color;
      this.item = { key, value };
      if (key && key instanceof Array && key.length == 2) {
        if (!Number.isNaN(key[0]) && !Number.isNaN(key[1])) {
          this.item.key = new Interval(Math.min(key[0], key[1]), Math.max(key[0], key[1]));
        }
      }
      this.max = this.item.key ? this.item.key.max : void 0;
    }
    isNil() {
      return this.item.key === void 0 && this.item.value === void 0 && this.left === null && this.right === null && this.color === RB_TREE_COLOR_BLACK;
    }
    less_than(other_node) {
      if (this.item.value === this.item.key && other_node.item.value === other_node.item.key) {
        return this.item.key.less_than(other_node.item.key);
      } else {
        let value_less_than = this.item.value && other_node.item.value && this.item.value.less_than ? this.item.value.less_than(other_node.item.value) : this.item.value < other_node.item.value;
        return this.item.key.less_than(other_node.item.key) || this.item.key.equal_to(other_node.item.key) && value_less_than;
      }
    }
    equal_to(other_node) {
      if (this.item.value === this.item.key && other_node.item.value === other_node.item.key) {
        return this.item.key.equal_to(other_node.item.key);
      } else {
        let value_equal = this.item.value && other_node.item.value && this.item.value.equal_to ? this.item.value.equal_to(other_node.item.value) : this.item.value == other_node.item.value;
        return this.item.key.equal_to(other_node.item.key) && value_equal;
      }
    }
    intersect(other_node) {
      return this.item.key.intersect(other_node.item.key);
    }
    copy_data(other_node) {
      this.item.key = other_node.item.key.clone();
      this.item.value = other_node.item.value && other_node.item.value.clone ? other_node.item.value.clone() : other_node.item.value;
    }
    update_max() {
      this.max = this.item.key ? this.item.key.max : void 0;
      if (this.right && this.right.max) {
        const comparable_max = this.item.key.constructor.comparable_max;
        this.max = comparable_max(this.max, this.right.max);
      }
      if (this.left && this.left.max) {
        const comparable_max = this.item.key.constructor.comparable_max;
        this.max = comparable_max(this.max, this.left.max);
      }
    }
    not_intersect_left_subtree(search_node) {
      const comparable_less_than = this.item.key.constructor.comparable_less_than;
      let high = this.left.max.high !== void 0 ? this.left.max.high : this.left.max;
      return comparable_less_than(high, search_node.item.key.low);
    }
    not_intersect_right_subtree(search_node) {
      const comparable_less_than = this.item.key.constructor.comparable_less_than;
      let low = this.right.max.low !== void 0 ? this.right.max.low : this.right.item.key.low;
      return comparable_less_than(search_node.item.key.high, low);
    }
  };
  var IntervalTree = class {
    constructor() {
      this.root = null;
      this.nil_node = new Node();
    }
    get size() {
      let count = 0;
      this.tree_walk(this.root, () => count++);
      return count;
    }
    get keys() {
      let res = [];
      this.tree_walk(this.root, (node) => res.push(node.item.key.output ? node.item.key.output() : node.item.key));
      return res;
    }
    get values() {
      let res = [];
      this.tree_walk(this.root, (node) => res.push(node.item.value));
      return res;
    }
    get items() {
      let res = [];
      this.tree_walk(this.root, (node) => res.push({
        key: node.item.key.output ? node.item.key.output() : node.item.key,
        value: node.item.value
      }));
      return res;
    }
    isEmpty() {
      return this.root == null || this.root == this.nil_node;
    }
    insert(key, value = key) {
      if (key === void 0)
        return;
      let insert_node = new Node(key, value, this.nil_node, this.nil_node, null, RB_TREE_COLOR_RED);
      this.tree_insert(insert_node);
      this.recalc_max(insert_node);
      return insert_node;
    }
    exist(key, value = key) {
      let search_node = new Node(key, value);
      return this.tree_search(this.root, search_node) ? true : false;
    }
    remove(key, value = key) {
      let search_node = new Node(key, value);
      let delete_node = this.tree_search(this.root, search_node);
      if (delete_node) {
        this.tree_delete(delete_node);
      }
      return delete_node;
    }
    search(interval, outputMapperFn = (value, key) => value === key ? key.output() : value) {
      let search_node = new Node(interval);
      let resp_nodes = [];
      this.tree_search_interval(this.root, search_node, resp_nodes);
      return resp_nodes.map((node) => outputMapperFn(node.item.value, node.item.key));
    }
    forEach(visitor) {
      this.tree_walk(this.root, (node) => visitor(node.item.key, node.item.value));
    }
    map(callback) {
      const tree = new IntervalTree();
      this.tree_walk(this.root, (node) => tree.insert(node.item.key, callback(node.item.value, node.item.key)));
      return tree;
    }
    recalc_max(node) {
      let node_current = node;
      while (node_current.parent != null) {
        node_current.parent.update_max();
        node_current = node_current.parent;
      }
    }
    tree_insert(insert_node) {
      let current_node = this.root;
      let parent_node = null;
      if (this.root == null || this.root == this.nil_node) {
        this.root = insert_node;
      } else {
        while (current_node != this.nil_node) {
          parent_node = current_node;
          if (insert_node.less_than(current_node)) {
            current_node = current_node.left;
          } else {
            current_node = current_node.right;
          }
        }
        insert_node.parent = parent_node;
        if (insert_node.less_than(parent_node)) {
          parent_node.left = insert_node;
        } else {
          parent_node.right = insert_node;
        }
      }
      this.insert_fixup(insert_node);
    }
    insert_fixup(insert_node) {
      let current_node;
      let uncle_node;
      current_node = insert_node;
      while (current_node != this.root && current_node.parent.color == RB_TREE_COLOR_RED) {
        if (current_node.parent == current_node.parent.parent.left) {
          uncle_node = current_node.parent.parent.right;
          if (uncle_node.color == RB_TREE_COLOR_RED) {
            current_node.parent.color = RB_TREE_COLOR_BLACK;
            uncle_node.color = RB_TREE_COLOR_BLACK;
            current_node.parent.parent.color = RB_TREE_COLOR_RED;
            current_node = current_node.parent.parent;
          } else {
            if (current_node == current_node.parent.right) {
              current_node = current_node.parent;
              this.rotate_left(current_node);
            }
            current_node.parent.color = RB_TREE_COLOR_BLACK;
            current_node.parent.parent.color = RB_TREE_COLOR_RED;
            this.rotate_right(current_node.parent.parent);
          }
        } else {
          uncle_node = current_node.parent.parent.left;
          if (uncle_node.color == RB_TREE_COLOR_RED) {
            current_node.parent.color = RB_TREE_COLOR_BLACK;
            uncle_node.color = RB_TREE_COLOR_BLACK;
            current_node.parent.parent.color = RB_TREE_COLOR_RED;
            current_node = current_node.parent.parent;
          } else {
            if (current_node == current_node.parent.left) {
              current_node = current_node.parent;
              this.rotate_right(current_node);
            }
            current_node.parent.color = RB_TREE_COLOR_BLACK;
            current_node.parent.parent.color = RB_TREE_COLOR_RED;
            this.rotate_left(current_node.parent.parent);
          }
        }
      }
      this.root.color = RB_TREE_COLOR_BLACK;
    }
    tree_delete(delete_node) {
      let cut_node;
      let fix_node;
      if (delete_node.left == this.nil_node || delete_node.right == this.nil_node) {
        cut_node = delete_node;
      } else {
        cut_node = this.tree_successor(delete_node);
      }
      if (cut_node.left != this.nil_node) {
        fix_node = cut_node.left;
      } else {
        fix_node = cut_node.right;
      }
      fix_node.parent = cut_node.parent;
      if (cut_node == this.root) {
        this.root = fix_node;
      } else {
        if (cut_node == cut_node.parent.left) {
          cut_node.parent.left = fix_node;
        } else {
          cut_node.parent.right = fix_node;
        }
        cut_node.parent.update_max();
      }
      this.recalc_max(fix_node);
      if (cut_node != delete_node) {
        delete_node.copy_data(cut_node);
        delete_node.update_max();
        this.recalc_max(delete_node);
      }
      if (cut_node.color == RB_TREE_COLOR_BLACK) {
        this.delete_fixup(fix_node);
      }
    }
    delete_fixup(fix_node) {
      let current_node = fix_node;
      let brother_node;
      while (current_node != this.root && current_node.parent != null && current_node.color == RB_TREE_COLOR_BLACK) {
        if (current_node == current_node.parent.left) {
          brother_node = current_node.parent.right;
          if (brother_node.color == RB_TREE_COLOR_RED) {
            brother_node.color = RB_TREE_COLOR_BLACK;
            current_node.parent.color = RB_TREE_COLOR_RED;
            this.rotate_left(current_node.parent);
            brother_node = current_node.parent.right;
          }
          if (brother_node.left.color == RB_TREE_COLOR_BLACK && brother_node.right.color == RB_TREE_COLOR_BLACK) {
            brother_node.color = RB_TREE_COLOR_RED;
            current_node = current_node.parent;
          } else {
            if (brother_node.right.color == RB_TREE_COLOR_BLACK) {
              brother_node.color = RB_TREE_COLOR_RED;
              brother_node.left.color = RB_TREE_COLOR_BLACK;
              this.rotate_right(brother_node);
              brother_node = current_node.parent.right;
            }
            brother_node.color = current_node.parent.color;
            current_node.parent.color = RB_TREE_COLOR_BLACK;
            brother_node.right.color = RB_TREE_COLOR_BLACK;
            this.rotate_left(current_node.parent);
            current_node = this.root;
          }
        } else {
          brother_node = current_node.parent.left;
          if (brother_node.color == RB_TREE_COLOR_RED) {
            brother_node.color = RB_TREE_COLOR_BLACK;
            current_node.parent.color = RB_TREE_COLOR_RED;
            this.rotate_right(current_node.parent);
            brother_node = current_node.parent.left;
          }
          if (brother_node.left.color == RB_TREE_COLOR_BLACK && brother_node.right.color == RB_TREE_COLOR_BLACK) {
            brother_node.color = RB_TREE_COLOR_RED;
            current_node = current_node.parent;
          } else {
            if (brother_node.left.color == RB_TREE_COLOR_BLACK) {
              brother_node.color = RB_TREE_COLOR_RED;
              brother_node.right.color = RB_TREE_COLOR_BLACK;
              this.rotate_left(brother_node);
              brother_node = current_node.parent.left;
            }
            brother_node.color = current_node.parent.color;
            current_node.parent.color = RB_TREE_COLOR_BLACK;
            brother_node.left.color = RB_TREE_COLOR_BLACK;
            this.rotate_right(current_node.parent);
            current_node = this.root;
          }
        }
      }
      current_node.color = RB_TREE_COLOR_BLACK;
    }
    tree_search(node, search_node) {
      if (node == null || node == this.nil_node)
        return void 0;
      if (search_node.equal_to(node)) {
        return node;
      }
      if (search_node.less_than(node)) {
        return this.tree_search(node.left, search_node);
      } else {
        return this.tree_search(node.right, search_node);
      }
    }
    tree_search_interval(node, search_node, res) {
      if (node != null && node != this.nil_node) {
        if (node.left != this.nil_node && !node.not_intersect_left_subtree(search_node)) {
          this.tree_search_interval(node.left, search_node, res);
        }
        if (node.intersect(search_node)) {
          res.push(node);
        }
        if (node.right != this.nil_node && !node.not_intersect_right_subtree(search_node)) {
          this.tree_search_interval(node.right, search_node, res);
        }
      }
    }
    local_minimum(node) {
      let node_min = node;
      while (node_min.left != null && node_min.left != this.nil_node) {
        node_min = node_min.left;
      }
      return node_min;
    }
    local_maximum(node) {
      let node_max = node;
      while (node_max.right != null && node_max.right != this.nil_node) {
        node_max = node_max.right;
      }
      return node_max;
    }
    tree_successor(node) {
      let node_successor;
      let current_node;
      let parent_node;
      if (node.right != this.nil_node) {
        node_successor = this.local_minimum(node.right);
      } else {
        current_node = node;
        parent_node = node.parent;
        while (parent_node != null && parent_node.right == current_node) {
          current_node = parent_node;
          parent_node = parent_node.parent;
        }
        node_successor = parent_node;
      }
      return node_successor;
    }
    rotate_left(x) {
      let y = x.right;
      x.right = y.left;
      if (y.left != this.nil_node) {
        y.left.parent = x;
      }
      y.parent = x.parent;
      if (x == this.root) {
        this.root = y;
      } else {
        if (x == x.parent.left) {
          x.parent.left = y;
        } else {
          x.parent.right = y;
        }
      }
      y.left = x;
      x.parent = y;
      if (x != null && x != this.nil_node) {
        x.update_max();
      }
      y = x.parent;
      if (y != null && y != this.nil_node) {
        y.update_max();
      }
    }
    rotate_right(y) {
      let x = y.left;
      y.left = x.right;
      if (x.right != this.nil_node) {
        x.right.parent = y;
      }
      x.parent = y.parent;
      if (y == this.root) {
        this.root = x;
      } else {
        if (y == y.parent.left) {
          y.parent.left = x;
        } else {
          y.parent.right = x;
        }
      }
      x.right = y;
      y.parent = x;
      if (y != null && y != this.nil_node) {
        y.update_max();
      }
      x = y.parent;
      if (x != null && x != this.nil_node) {
        x.update_max();
      }
    }
    tree_walk(node, action) {
      if (node != null && node != this.nil_node) {
        this.tree_walk(node.left, action);
        action(node);
        this.tree_walk(node.right, action);
      }
    }
    testRedBlackProperty() {
      let res = true;
      this.tree_walk(this.root, function(node) {
        if (node.color == RB_TREE_COLOR_RED) {
          if (!(node.left.color == RB_TREE_COLOR_BLACK && node.right.color == RB_TREE_COLOR_BLACK)) {
            res = false;
          }
        }
      });
      return res;
    }
    testBlackHeightProperty(node) {
      let height = 0;
      let heightLeft = 0;
      let heightRight = 0;
      if (node.color == RB_TREE_COLOR_BLACK) {
        height++;
      }
      if (node.left != this.nil_node) {
        heightLeft = this.testBlackHeightProperty(node.left);
      } else {
        heightLeft = 1;
      }
      if (node.right != this.nil_node) {
        heightRight = this.testBlackHeightProperty(node.right);
      } else {
        heightRight = 1;
      }
      if (heightLeft != heightRight) {
        throw new Error("Red-black height property violated");
      }
      height += heightLeft;
      return height;
    }
  };
  var main_esm_default = IntervalTree;

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/support/dataMatrix.ts
  var getAttr = (dataMatrix22, attrKey) => {
    for (const colAttr of dataMatrix22.columnAttrs) {
      if (colAttr.attr === attrKey) {
        return colAttr;
      }
    }
    for (const rowAttr of dataMatrix22.rowAttrs) {
      if (rowAttr.attr === attrKey) {
        return rowAttr;
      }
    }
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/support/dataMatrixLookup.ts
  var isOpenOrClosedInterval = function(interval) {
    let maybeOpenOrClosedInterval = interval;
    return maybeOpenOrClosedInterval.lowInclusive !== void 0 && maybeOpenOrClosedInterval.highInclusive !== void 0;
  };
  var OpenOrClosedInterval = class {
    constructor(low, high, lowInclusive = true, otherHighInclusive = true) {
      this.lowInclusive = true;
      this.highInclusive = true;
      this.low = low;
      this.high = high;
      this.lowInclusive = lowInclusive;
      this.highInclusive = otherHighInclusive;
    }
    static isLowInclusive(other_interval) {
      return isOpenOrClosedInterval(other_interval) ? other_interval.lowInclusive : true;
    }
    static isHighInclusive(other_interval) {
      return isOpenOrClosedInterval(other_interval) ? other_interval.highInclusive : true;
    }
    clone() {
      return new OpenOrClosedInterval(this.low, this.high, this.lowInclusive, this.highInclusive);
    }
    get max() {
      return this.clone();
    }
    less_than(other_interval) {
      let otherLowInclusive = OpenOrClosedInterval.isLowInclusive(other_interval);
      let otherHighInclusive = OpenOrClosedInterval.isHighInclusive(other_interval);
      const thisLowLower = this.low === other_interval.low && this.lowInclusive && !otherLowInclusive || this.low < other_interval.low;
      const thisLowEquals = this.lowInclusive === otherLowInclusive && this.low === other_interval.low;
      const thisHighLower = this.high < other_interval.high || this.high === other_interval.high && !this.highInclusive && otherHighInclusive;
      return thisLowLower || thisLowEquals && thisHighLower;
    }
    equal_to(other_interval) {
      let otherLowInclusive = OpenOrClosedInterval.isLowInclusive(other_interval);
      let otherHighInclusive = OpenOrClosedInterval.isHighInclusive(other_interval);
      return this.low === other_interval.low && this.high === other_interval.high && this.lowInclusive === otherLowInclusive && this.highInclusive === otherHighInclusive;
    }
    intersect(other_interval) {
      return !this.not_intersect(other_interval);
    }
    not_intersect(other_interval) {
      let otherLowInclusive = OpenOrClosedInterval.isLowInclusive(other_interval);
      let otherHighInclusive = OpenOrClosedInterval.isHighInclusive(other_interval);
      let belowOtherLowerBound = false;
      let afterOtherHigherBound = false;
      if (!this.highInclusive || !otherLowInclusive) {
        belowOtherLowerBound = this.high <= other_interval.low;
      } else {
        belowOtherLowerBound = this.high < other_interval.low;
      }
      if (!this.lowInclusive || !otherHighInclusive) {
        afterOtherHigherBound = other_interval.high <= this.low;
      } else {
        afterOtherHigherBound = other_interval.high < this.low;
      }
      return belowOtherLowerBound || afterOtherHigherBound;
    }
    merge(other_interval) {
      let otherLowInclusive = OpenOrClosedInterval.isLowInclusive(other_interval);
      let otherHighInclusive = OpenOrClosedInterval.isHighInclusive(other_interval);
      let thisLowLower = true;
      let thisHighHigher = true;
      if (this.low === void 0 || other_interval.low < this.low) {
        thisLowLower = false;
      }
      if (this.low === other_interval.low && !this.lowInclusive) {
        thisLowLower = false;
      }
      if (this.high === void 0 || other_interval.high > this.high) {
        thisHighHigher = false;
      }
      if (this.high === other_interval.high && !this.highInclusive) {
        thisHighHigher = false;
      }
      let newLowInclusive = thisLowLower ? this.lowInclusive : otherLowInclusive;
      let newHighInclusive = thisHighHigher ? this.highInclusive : otherHighInclusive;
      return new OpenOrClosedInterval(this.low === void 0 ? other_interval.low : Math.min(this.low, other_interval.low), this.high === void 0 ? other_interval.high : Math.max(this.high, other_interval.high), newLowInclusive, newHighInclusive);
    }
    output() {
      return [this.low, this.high];
    }
    static comparable_max(interval1, interval2) {
      return interval1.merge(interval2);
    }
    static comparable_less_than(val1, val2) {
      return val1 < val2;
    }
  };
  var rawIntervalToOpenOrClosedInterval = function(interval) {
    const lowInclusive = interval[0] === "[";
    const highInclusive = interval[3] === "]";
    return new OpenOrClosedInterval(interval[1], interval[2], lowInclusive, highInclusive);
  };
  var arrayIntersection = (arrays) => {
    return arrays.reduce((acc, array) => {
      const filtered = array.filter((elem) => arrays.every((arr) => arr.includes(elem)));
      const newAcc = [...acc, ...filtered];
      const distinctAcc = newAcc.filter((n, i) => newAcc.indexOf(n) === i);
      return distinctAcc;
    }, []);
  };
  var numberOperations = {
    ">": (num1) => (num2) => num2 > num1,
    ">=": (num1) => (num2) => num2 >= num1,
    "<": (num1) => (num2) => num2 < num1,
    "<=": (num1) => (num2) => num2 <= num1,
    "==": (num1) => (num2) => num2 === num1
  };
  var rangeRegexp = /^((?<cond1>\>\=|\>)(?<num1>.*?))?((?<cond2>\<\=|\<)(?<num2>.*?))?$/;
  var rangeToCheck = (rangeString) => {
    const { cond1, num1, cond2, num2 } = rangeRegexp.exec(rangeString).groups;
    const checks = [];
    if (cond1 !== void 0) {
      checks.push(numberOperations[cond1](Number.parseFloat(num1)));
    }
    if (cond2 !== void 0) {
      checks.push(numberOperations[cond2](Number.parseFloat(num2)));
    }
    return (value) => checks.every((check) => check(value));
  };
  var rangeStringToRawInterval = (rangeString) => {
    let minimum = -Infinity;
    let minimumInclusive = false;
    let maximum = Infinity;
    let maximumInclusive = false;
    const { cond1, num1, cond2, num2 } = rangeRegexp.exec(rangeString).groups;
    const parsedNum1 = Number.parseFloat(num1);
    const parsedNum2 = Number.parseFloat(num2);
    if (cond1 === "==") {
      if (cond2 !== void 0) {
        throw new Error("Invalid rangeString " + rangeString);
      }
      return ["[", parsedNum1, parsedNum1, "]"];
    }
    if (cond1 === ">" || cond1 === ">=") {
      minimum = parsedNum1;
      if (cond1 === ">=") {
        minimumInclusive = true;
      }
    }
    if (cond2 === "<" || cond2 === "<=") {
      maximum = parsedNum2;
      if (cond2 === "<=") {
        maximumInclusive = true;
      }
    }
    let openingBracket = "(";
    if (minimumInclusive) {
      openingBracket = "[";
    }
    let closingBracket = ")";
    if (maximumInclusive) {
      closingBracket = "]";
    }
    return [openingBracket, minimum, maximum, closingBracket];
  };
  var numberStringToCheck = (numberString) => {
    const checks = numberString.split("|").map((str) => str.trim()).map((rangeOrNumberString) => {
      if (rangeOrNumberString.includes(">") || rangeOrNumberString.includes("<")) {
        return rangeToCheck(rangeOrNumberString);
      }
      return numberOperations["=="](parseFloat(rangeOrNumberString));
    });
    return (value) => checks.some((check) => check(value));
  };
  var attrsAreRanges = (attrInfo) => {
    return attrInfo.type === "bigint" || attrInfo.type === "number";
  };
  var initializeDataMatrix = (dataMatrix22) => {
    indexAttributes(dataMatrix22);
  };
  var indexAttributes = function(dataMatrix22) {
    let attrIndices = {};
    let indexAttrs = function(attrs) {
      for (const attrInfo of attrs) {
        if (attrsAreRanges(attrInfo)) {
          const attrName = attrInfo.attr;
          let intervalTree = new main_esm_default();
          attrIndices[attrName] = { intervalTree, nots: [], wildcards: [] };
          attrInfo["nots"].forEach((not, index) => {
            if (not) {
              attrIndices[attrName]["nots"].push(index);
            }
          });
          attrInfo["wildcards"].forEach((wildcard, index) => {
            if (wildcard) {
              attrIndices[attrName]["wildcards"].push(index);
            }
          });
          const keys = attrInfo.keys;
          for (const index in keys) {
            const key = keys[index];
            if (typeof key === "string") {
              const interval = rangeStringToRawInterval(key);
              const intervalForTree = rawIntervalToOpenOrClosedInterval(interval);
              attrIndices[attrName]["intervalTree"].insert(intervalForTree, index);
            } else if (Array.isArray(key)) {
              for (const possibleValue of key) {
                attrIndices[attrName]["intervalTree"].insert([possibleValue, possibleValue], index);
              }
            }
          }
        }
      }
    };
    indexAttrs(dataMatrix22.columnAttrs);
    indexAttrs(dataMatrix22.rowAttrs);
    dataMatrix22.attrIndices = attrIndices;
  };
  var indicesLookupIndexedIntervalTree = (dataMatrix22, attrName, val) => {
    if (!dataMatrix22.attrIndices) {
      return [];
    }
    if (dataMatrix22.attrIndices && !(attrName in dataMatrix22.attrIndices)) {
      return [];
    }
    let result = dataMatrix22.attrIndices[attrName]["intervalTree"].search([val, val]);
    if (result && result.length > 0) {
      const retval = [];
      for (let res of result) {
        retval.push(Number.parseFloat(res));
      }
      return retval;
    }
    return [];
  };
  var indicesLookupIndexedNots = (dataMatrix22, attrName, val) => {
    let nots = [];
    if (dataMatrix22.attrIndices && dataMatrix22.attrIndices[attrName]) {
      nots = dataMatrix22.attrIndices[attrName]["nots"];
    }
    const indices = [];
    const attr = getAttr(dataMatrix22, attrName);
    for (const notInd of nots) {
      let attrKey = attr.keys[notInd];
      let attrType = attr.type;
      if (!match(attrType, attrKey, val)) {
        indices.push(notInd);
      }
    }
    return indices;
  };
  var indicesLookupIndexedWildcards = (dataMatrix22, attrName) => {
    if (dataMatrix22.attrIndices && dataMatrix22.attrIndices[attrName]) {
      return dataMatrix22.attrIndices[attrName]["wildcards"];
    }
    return [];
  };
  var indicesLookupIndexed = (dataMatrix22, attrName, value) => {
    let indices = null;
    if (dataMatrix22.attrIndices && attrName in dataMatrix22.attrIndices) {
      indices = indicesLookupIndexedIntervalTree(dataMatrix22, attrName, value).concat(indicesLookupIndexedNots(dataMatrix22, attrName, value)).concat(indicesLookupIndexedWildcards(dataMatrix22, attrName));
    }
    return indices;
  };
  var hasAttrIndexed = (dataMatrix22, attrName) => {
    return dataMatrix22.attrIndices && attrName in dataMatrix22.attrIndices;
  };
  var isRangeKey = function(attrType, attrKey) {
    return attrType === "number" && typeof attrKey === "string";
  };
  var match = function(attrType, attrKey, value) {
    let matches = false;
    if (attrKey === null || attrKey === void 0) {
      matches = value === null || value === void 0;
    } else if (isRangeKey(attrType, attrKey)) {
      let validateValueFn = numberStringToCheck(attrKey);
      matches = value !== null && value !== void 0 && validateValueFn(value);
    } else if (attrType == "boolean") {
      matches = value === attrKey;
    } else {
      matches = attrKey.includes(value);
    }
    return matches;
  };
  var indicesLookupLinear = (dataMatrix22, attr, value) => {
    const indices = [];
    const type4 = attr.type;
    const nots = attr.nots;
    const wildcards = attr.wildcards;
    const convertedVal = value;
    attr.keys.forEach((keyVal, index) => {
      const wildcard = wildcards[index];
      if (keyVal === null && wildcard) {
        indices.push(index);
      }
      const notCondition = nots[index];
      let checkRes;
      let check;
      if (keyVal === null || keyVal === void 0) {
        checkRes = value === null || value === void 0;
      } else if (type4 === "number" && typeof keyVal === "string") {
        check = numberStringToCheck(keyVal);
        checkRes = value !== null && value !== void 0 && check(convertedVal);
      } else if (type4 === "boolean") {
        checkRes = keyVal === convertedVal;
      } else {
        checkRes = keyVal.includes(convertedVal);
      }
      if (checkRes && !notCondition) {
        indices.push(index);
      }
      if (!checkRes && notCondition) {
        indices.push(index);
      }
    });
    return indices;
  };
  var indicesLookup = (dataMatrix22, attributes) => {
    const lookupFunction = (acc, key) => {
      const attr = key.attr;
      const value = attributes[attr];
      let indices = null;
      if (value && hasAttrIndexed(dataMatrix22, attr)) {
        indices = indicesLookupIndexed(dataMatrix22, attr, value);
      } else {
        indices = indicesLookupLinear(dataMatrix22, key, value);
      }
      return [...acc, indices];
    };
    const vIndicesArr = dataMatrix22.columnAttrs.reduce(lookupFunction, []);
    const hIndicesArr = dataMatrix22.rowAttrs.reduce(lookupFunction, []);
    return { vIndicesArr, hIndicesArr };
  };
  var indicesLookupOld = (dataMatrix22, attributes) => {
    const lookupFunction = (acc, key) => {
      const attr = key.attr;
      const value = attributes[attr];
      const type4 = key.type;
      const nots = key.nots;
      const wildcards = key.wildcards;
      const convertedVal = value;
      const indices = [];
      key.keys.forEach((keyVal, index) => {
        const wildcard = wildcards[index];
        if (keyVal === null && wildcard) {
          indices.push(index);
        }
        const notCondition = nots[index];
        let checkRes;
        let check;
        if (keyVal === null || keyVal === void 0) {
          checkRes = value === null || value === void 0;
        } else if (type4 === "number" && typeof keyVal === "string") {
          check = numberStringToCheck(keyVal);
          checkRes = value !== null && value !== void 0 && check(convertedVal);
        } else if (type4 === "boolean") {
          checkRes = keyVal === convertedVal;
        } else {
          checkRes = keyVal.includes(convertedVal);
        }
        if (checkRes && !notCondition) {
          indices.push(index);
        }
        if (!checkRes && notCondition) {
          indices.push(index);
        }
      });
      return [...acc, indices];
    };
    const vIndicesArr = dataMatrix22.columnAttrs.reduce(lookupFunction, []);
    const hIndicesArr = dataMatrix22.rowAttrs.reduce(lookupFunction, []);
    return { vIndicesArr, hIndicesArr };
  };
  var dataMatrixLookup = (dataMatrix22, attributes, options = { returnData: false }) => {
    let vIndices;
    let hIndices;
    const { vIndicesArr, hIndicesArr } = indicesLookup(dataMatrix22, attributes);
    if (vIndicesArr.length === 0) {
      vIndices = [0];
    } else {
      vIndices = arrayIntersection(vIndicesArr);
    }
    if (hIndicesArr.length === 0) {
      hIndices = [0];
    } else {
      hIndices = arrayIntersection(hIndicesArr);
    }
    const vIndexMin = vIndices.length > 0 ? Math.min(...vIndices) : null;
    const hIndexMin = hIndices.length > 0 ? Math.min(...hIndices) : null;
    if (vIndexMin === null || hIndexMin === null) {
      return {
        data: options.returnData ? dataMatrix22.data : null,
        name: dataMatrix22.name,
        result: null,
        metadata: null
      };
    }
    const result = dataMatrix22.data[vIndexMin][hIndexMin];
    return {
      data: options.returnData ? dataMatrix22.data : null,
      name: dataMatrix22.name,
      result,
      metadata: null
    };
  };
  var dataMatrixLookupLinear = (dataMatrix22, attributes, options = { returnData: false }) => {
    let vIndices;
    let hIndices;
    const { vIndicesArr, hIndicesArr } = indicesLookupOld(dataMatrix22, attributes);
    if (vIndicesArr.length === 0) {
      vIndices = [0];
    } else {
      vIndices = arrayIntersection(vIndicesArr);
    }
    if (hIndicesArr.length === 0) {
      hIndices = [0];
    } else {
      hIndices = arrayIntersection(hIndicesArr);
    }
    const vIndexMin = vIndices.length > 0 ? Math.min(...vIndices) : null;
    const hIndexMin = hIndices.length > 0 ? Math.min(...hIndices) : null;
    if (vIndexMin === null || hIndexMin === null) {
      return {
        data: options.returnData ? dataMatrix22.data : null,
        name: dataMatrix22.name,
        result: null,
        metadata: null
      };
    }
    const result = dataMatrix22.data[vIndexMin][hIndexMin];
    return {
      data: options.returnData ? dataMatrix22.data : null,
      name: dataMatrix22.name,
      result,
      metadata: null
    };
  };
  var testing = {
    isRangeKey,
    rangeStringToRawInterval,
    initializeDataMatrix,
    indicesLookupIndexedWildcards,
    indicesLookupIndexedNots,
    OpenOrClosedInterval
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/dataMatrices/g1.ts
  var dataMatrix = {
    "name": "G1",
    "data": [
      [
        1.1,
        2.2,
        3.3
      ],
      [
        4.4,
        5.5,
        6.6
      ],
      [
        1.2,
        2.3,
        3.4
      ],
      [
        4.5,
        5.6,
        null
      ],
      [
        11,
        22,
        33
      ]
    ],
    "columnAttrs": [
      {
        "attr": "state",
        "keys": [
          [
            "CA"
          ],
          [
            "HI",
            "TX"
          ],
          [
            "NM"
          ],
          [
            "MA"
          ],
          null
        ],
        "nots": [
          false,
          false,
          false,
          false,
          false
        ],
        "type": "State",
        "wildcards": [
          false,
          false,
          false,
          false,
          true
        ]
      },
      {
        "attr": "ltv",
        "keys": [
          "<=80",
          ">80<=105",
          "<=80",
          ">80<=105",
          "<=80"
        ],
        "nots": [
          false,
          false,
          false,
          false,
          false
        ],
        "type": "number",
        "wildcards": [
          false,
          false,
          false,
          false,
          false
        ]
      }
    ],
    "rowAttrs": [
      {
        "attr": "fico",
        "keys": [
          ">=600<700",
          ">=700<750",
          ">=750"
        ],
        "nots": [
          false,
          false,
          false
        ],
        "type": "number",
        "wildcards": [
          false,
          false,
          false
        ]
      }
    ],
    "comments": [
      "Example comment",
      null,
      "Second comment",
      null,
      null
    ],
    "dataType": null
  };
  initializeDataMatrix(dataMatrix);
  var g1 = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookup(dataMatrix, attributes, options);
  };
  var g1Linear = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookupLinear(dataMatrix, attributes, options);
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/dataMatrices/g1WithNulls.ts
  var dataMatrix2 = {
    "name": "G1WithNulls",
    "data": [
      [
        1.1,
        2.2,
        3.3
      ],
      [
        4.4,
        5.5,
        6.6
      ],
      [
        1.2,
        2.3,
        3.4
      ],
      [
        4.5,
        5.6,
        null
      ],
      [
        11,
        22,
        33
      ]
    ],
    "columnAttrs": [
      {
        "attr": "state",
        "keys": [
          [
            "CA"
          ],
          [
            "HI",
            "TX"
          ],
          [
            "NM"
          ],
          [
            "MA"
          ],
          null
        ],
        "nots": [
          false,
          false,
          false,
          false,
          false
        ],
        "type": "State",
        "wildcards": [
          false,
          false,
          false,
          false,
          false
        ]
      },
      {
        "attr": "ltv",
        "keys": [
          "<=80",
          ">80<=105",
          "<=80",
          ">80<=105",
          "<=80"
        ],
        "nots": [
          false,
          false,
          false,
          false,
          false
        ],
        "type": "number",
        "wildcards": [
          false,
          false,
          false,
          false,
          false
        ]
      }
    ],
    "rowAttrs": [
      {
        "attr": "fico",
        "keys": [
          ">=600<700",
          ">=700<750",
          ">=750"
        ],
        "nots": [
          false,
          false,
          false
        ],
        "type": "number",
        "wildcards": [
          false,
          false,
          false
        ]
      }
    ],
    "comments": [
      null,
      null,
      null,
      null,
      null
    ],
    "dataType": null
  };
  initializeDataMatrix(dataMatrix2);
  var g1WithNulls = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookup(dataMatrix2, attributes, options);
  };
  var g1WithNullsLinear = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookupLinear(dataMatrix2, attributes, options);
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/dataMatrices/g1WithNulls2.ts
  var dataMatrix3 = {
    "name": "G1WithNulls2",
    "data": [
      [
        1.1,
        2.2,
        3.3
      ],
      [
        4.4,
        5.5,
        6.6
      ],
      [
        1.2,
        2.3,
        3.4
      ],
      [
        4.5,
        5.6,
        null
      ],
      [
        11,
        22,
        33
      ]
    ],
    "columnAttrs": [
      {
        "attr": "state",
        "keys": [
          [
            "CA"
          ],
          [
            "HI",
            "TX"
          ],
          [
            "NM"
          ],
          [
            "MA"
          ],
          [
            "NY",
            null
          ]
        ],
        "nots": [
          false,
          false,
          false,
          false,
          false
        ],
        "type": "State",
        "wildcards": [
          false,
          false,
          false,
          false,
          false
        ]
      },
      {
        "attr": "ltv",
        "keys": [
          "<=80",
          ">80<=105",
          "<=80",
          ">80<=105",
          "<=80"
        ],
        "nots": [
          false,
          false,
          false,
          false,
          false
        ],
        "type": "number",
        "wildcards": [
          false,
          false,
          false,
          false,
          false
        ]
      }
    ],
    "rowAttrs": [
      {
        "attr": "fico",
        "keys": [
          ">=600<700",
          ">=700<750",
          ">=750"
        ],
        "nots": [
          false,
          false,
          false
        ],
        "type": "number",
        "wildcards": [
          false,
          false,
          false
        ]
      }
    ],
    "comments": [
      null,
      null,
      null,
      null,
      null
    ],
    "dataType": null
  };
  initializeDataMatrix(dataMatrix3);
  var g1WithNulls2 = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookup(dataMatrix3, attributes, options);
  };
  var g1WithNulls2Linear = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookupLinear(dataMatrix3, attributes, options);
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/dataMatrices/g1WithRangeNulls.ts
  var dataMatrix4 = {
    "name": "G1WithRangeNulls",
    "data": [
      [
        1.1,
        2.2,
        3.3
      ],
      [
        4.4,
        5.5,
        6.6
      ],
      [
        1.2,
        2.3,
        3.4
      ],
      [
        4.5,
        5.6,
        null
      ],
      [
        11,
        22,
        33
      ]
    ],
    "columnAttrs": [
      {
        "attr": "state",
        "keys": [
          [
            "CA"
          ],
          [
            "HI",
            "TX"
          ],
          [
            "NM"
          ],
          [
            "MA"
          ],
          null
        ],
        "nots": [
          false,
          false,
          false,
          false,
          false
        ],
        "type": "State",
        "wildcards": [
          false,
          false,
          false,
          false,
          true
        ]
      },
      {
        "attr": "ltv",
        "keys": [
          "<=80",
          ">80<=105",
          null,
          ">80<=105",
          null
        ],
        "nots": [
          false,
          false,
          false,
          false,
          false
        ],
        "type": "number",
        "wildcards": [
          false,
          false,
          true,
          false,
          false
        ]
      }
    ],
    "rowAttrs": [
      {
        "attr": "fico",
        "keys": [
          ">=600<700",
          ">=700<750",
          ">=750"
        ],
        "nots": [
          false,
          false,
          false
        ],
        "type": "number",
        "wildcards": [
          false,
          false,
          false
        ]
      }
    ],
    "comments": [
      null,
      null,
      null,
      null,
      null
    ],
    "dataType": null
  };
  initializeDataMatrix(dataMatrix4);
  var g1WithRangeNulls = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookup(dataMatrix4, attributes, options);
  };
  var g1WithRangeNullsLinear = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookupLinear(dataMatrix4, attributes, options);
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/dataMatrices/g2.ts
  var dataMatrix5 = {
    "name": "G2",
    "data": [
      [
        1.1,
        2.2,
        3.3
      ],
      [
        4.4,
        5.5,
        6.6
      ],
      [
        1.2,
        2.3,
        3.4
      ],
      [
        4.5,
        5.6,
        6.7
      ]
    ],
    "columnAttrs": [
      {
        "attr": "units",
        "keys": [
          [
            1,
            2
          ],
          [
            1,
            2
          ],
          [
            3,
            4
          ],
          [
            3,
            4
          ]
        ],
        "nots": [
          false,
          false,
          false,
          false
        ],
        "type": "number",
        "wildcards": [
          false,
          false,
          false,
          false
        ]
      },
      {
        "attr": "ltv",
        "keys": [
          "<=80",
          ">80<=105",
          "<=80",
          ">80<=105"
        ],
        "nots": [
          false,
          false,
          false,
          false
        ],
        "type": "number",
        "wildcards": [
          false,
          false,
          false,
          false
        ]
      }
    ],
    "rowAttrs": [
      {
        "attr": "cltv",
        "keys": [
          ">=100<110",
          ">=110<120",
          ">=120"
        ],
        "nots": [
          false,
          false,
          false
        ],
        "type": "number",
        "wildcards": [
          false,
          false,
          false
        ]
      },
      {
        "attr": "fico",
        "keys": [
          ">=600<700",
          ">=700<750",
          ">=750"
        ],
        "nots": [
          false,
          false,
          false
        ],
        "type": "number",
        "wildcards": [
          false,
          false,
          false
        ]
      }
    ],
    "comments": [
      null,
      null,
      null,
      null
    ],
    "dataType": null
  };
  initializeDataMatrix(dataMatrix5);
  var g2 = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookup(dataMatrix5, attributes, options);
  };
  var g2Linear = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookupLinear(dataMatrix5, attributes, options);
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/dataMatrices/g3.ts
  var dataMatrix6 = {
    "name": "G3",
    "data": [
      [
        1.16,
        1.46,
        1.59,
        1.66,
        1.7,
        1.73,
        1.76,
        1.79
      ],
      [
        1.27,
        1.57,
        1.7,
        1.77,
        1.81,
        1.84,
        1.87,
        1.9
      ],
      [
        1.05,
        1.35,
        1.48,
        1.55,
        1.59,
        1.62,
        1.65,
        1.68
      ],
      [
        1.093,
        1.393,
        1.523,
        1.593,
        1.633,
        1.663,
        1.693,
        1.723
      ],
      [
        1.155,
        1.455,
        1.585,
        1.655,
        1.695,
        1.725,
        1.755,
        1.785
      ],
      [
        1.03,
        1.33,
        1.46,
        1.53,
        1.57,
        1.6,
        1.63,
        1.66
      ],
      [
        1.097,
        1.397,
        1.527,
        1.597,
        1.637,
        1.667,
        1.697,
        1.727
      ],
      [
        1.16,
        1.46,
        1.59,
        1.66,
        1.7,
        1.73,
        1.76,
        1.79
      ],
      [
        1.16,
        1.46,
        1.59,
        1.66,
        1.7,
        1.73,
        1.76,
        1.79
      ],
      [
        1.39,
        1.69,
        1.82,
        1.89,
        1.93,
        1.96,
        1.99,
        2.02
      ],
      [
        1.27,
        1.57,
        1.7,
        1.77,
        1.81,
        1.84,
        1.87,
        1.9
      ],
      [
        1.155,
        1.455,
        1.585,
        1.655,
        1.695,
        1.725,
        1.755,
        1.785
      ],
      [
        1.295,
        1.595,
        1.725,
        1.795,
        1.835,
        1.865,
        1.895,
        1.925
      ],
      [
        1.16,
        1.46,
        1.59,
        1.66,
        1.7,
        1.73,
        1.76,
        1.79
      ],
      [
        1.233,
        1.533,
        1.663,
        1.733,
        1.773,
        1.803,
        1.833,
        1.863
      ],
      [
        1.03,
        1.33,
        1.46,
        1.53,
        1.57,
        1.6,
        1.63,
        1.66
      ],
      [
        1.17,
        1.47,
        1.6,
        1.67,
        1.71,
        1.74,
        1.77,
        1.8
      ],
      [
        1.17,
        1.47,
        1.6,
        1.67,
        1.71,
        1.74,
        1.77,
        1.8
      ],
      [
        1.27,
        1.57,
        1.7,
        1.77,
        1.81,
        1.84,
        1.87,
        1.9
      ],
      [
        1.295,
        1.595,
        1.725,
        1.795,
        1.835,
        1.865,
        1.895,
        1.925
      ],
      [
        1.27,
        1.57,
        1.7,
        1.77,
        1.81,
        1.84,
        1.87,
        1.9
      ],
      [
        1.03,
        1.33,
        1.46,
        1.53,
        1.57,
        1.6,
        1.63,
        1.66
      ],
      [
        1.093,
        1.393,
        1.523,
        1.593,
        1.633,
        1.663,
        1.693,
        1.723
      ],
      [
        1.18,
        1.48,
        1.61,
        1.68,
        1.72,
        1.75,
        1.78,
        1.81
      ],
      [
        1.17,
        1.47,
        1.6,
        1.67,
        1.71,
        1.74,
        1.77,
        1.8
      ],
      [
        1.27,
        1.57,
        1.7,
        1.77,
        1.81,
        1.84,
        1.87,
        1.9
      ],
      [
        1.05,
        1.35,
        1.48,
        1.55,
        1.59,
        1.62,
        1.65,
        1.68
      ],
      [
        1.165,
        1.465,
        1.595,
        1.665,
        1.705,
        1.735,
        1.765,
        1.795
      ],
      [
        1.39,
        1.69,
        1.82,
        1.89,
        1.93,
        1.96,
        1.99,
        2.02
      ],
      [
        1.17,
        1.47,
        1.6,
        1.67,
        1.71,
        1.74,
        1.77,
        1.8
      ],
      [
        1.05,
        1.35,
        1.48,
        1.55,
        1.59,
        1.62,
        1.65,
        1.68
      ],
      [
        1.207,
        1.507,
        1.637,
        1.707,
        1.747,
        1.777,
        1.807,
        1.837
      ],
      [
        1.17,
        1.47,
        1.6,
        1.67,
        1.71,
        1.74,
        1.77,
        1.8
      ],
      [
        0.93,
        1.23,
        1.36,
        1.43,
        1.47,
        1.5,
        1.53,
        1.56
      ],
      [
        1.227,
        1.527,
        1.657,
        1.727,
        1.767,
        1.797,
        1.827,
        1.857
      ],
      [
        1.29,
        1.59,
        1.72,
        1.79,
        1.83,
        1.86,
        1.89,
        1.92
      ],
      [
        1.265,
        1.565,
        1.695,
        1.765,
        1.805,
        1.835,
        1.865,
        1.895
      ],
      [
        1.29,
        1.59,
        1.72,
        1.79,
        1.83,
        1.86,
        1.89,
        1.92
      ],
      [
        1.327,
        1.627,
        1.757,
        1.827,
        1.867,
        1.897,
        1.927,
        1.957
      ],
      [
        0.87,
        1.17,
        1.3,
        1.37,
        1.41,
        1.44,
        1.47,
        1.5
      ],
      [
        1.165,
        1.465,
        1.595,
        1.665,
        1.705,
        1.735,
        1.765,
        1.795
      ],
      [
        1.05,
        1.35,
        1.48,
        1.55,
        1.59,
        1.62,
        1.65,
        1.68
      ],
      [
        1.227,
        1.527,
        1.657,
        1.727,
        1.767,
        1.797,
        1.827,
        1.857
      ],
      [
        1.45,
        1.75,
        1.88,
        1.95,
        1.99,
        2.02,
        2.05,
        2.08
      ],
      [
        1.05,
        1.35,
        1.48,
        1.55,
        1.59,
        1.62,
        1.65,
        1.68
      ],
      [
        1.29,
        1.59,
        1.72,
        1.79,
        1.83,
        1.86,
        1.89,
        1.92
      ],
      [
        1.05,
        1.35,
        1.48,
        1.55,
        1.59,
        1.62,
        1.65,
        1.68
      ],
      [
        1.17,
        1.47,
        1.6,
        1.67,
        1.71,
        1.74,
        1.77,
        1.8
      ],
      [
        1.29,
        1.59,
        1.72,
        1.79,
        1.83,
        1.86,
        1.89,
        1.92
      ],
      [
        1.17,
        1.47,
        1.6,
        1.67,
        1.71,
        1.74,
        1.77,
        1.8
      ],
      [
        1.05,
        1.35,
        1.48,
        1.55,
        1.59,
        1.62,
        1.65,
        1.68
      ]
    ],
    "columnAttrs": [
      {
        "attr": "state",
        "keys": [
          [
            "AK"
          ],
          [
            "AL"
          ],
          [
            "AR"
          ],
          [
            "AZ"
          ],
          [
            "CA"
          ],
          [
            "CO"
          ],
          [
            "CT"
          ],
          [
            "DC"
          ],
          [
            "DE"
          ],
          [
            "FL"
          ],
          [
            "GA"
          ],
          [
            "HI"
          ],
          [
            "IA"
          ],
          [
            "ID"
          ],
          [
            "IL"
          ],
          [
            "IN"
          ],
          [
            "KS"
          ],
          [
            "KY"
          ],
          [
            "LA"
          ],
          [
            "MA"
          ],
          [
            "MD"
          ],
          [
            "ME"
          ],
          [
            "MI"
          ],
          [
            "MN"
          ],
          [
            "MO"
          ],
          [
            "MS"
          ],
          [
            "MT"
          ],
          [
            "NC"
          ],
          [
            "ND"
          ],
          [
            "NE"
          ],
          [
            "NH"
          ],
          [
            "NJ"
          ],
          [
            "NM"
          ],
          [
            "NV"
          ],
          [
            "NY"
          ],
          [
            "OH"
          ],
          [
            "OK"
          ],
          [
            "OR"
          ],
          [
            "PA"
          ],
          [
            "RI"
          ],
          [
            "SC"
          ],
          [
            "SD"
          ],
          [
            "TN"
          ],
          [
            "TX"
          ],
          [
            "UT"
          ],
          [
            "VA"
          ],
          [
            "VT"
          ],
          [
            "WA"
          ],
          [
            "WI"
          ],
          [
            "WV"
          ],
          [
            "WY"
          ]
        ],
        "nots": [
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false
        ],
        "type": "State",
        "wildcards": [
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false
        ]
      }
    ],
    "rowAttrs": [
      {
        "attr": "amount",
        "keys": [
          "<80000",
          ">=80000<120000",
          ">=120000<160000",
          ">=160000<200000",
          ">=200000<240000",
          ">=240000<280000",
          ">=280000<320000",
          ">=320000"
        ],
        "nots": [
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false
        ],
        "type": "number",
        "wildcards": [
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false
        ]
      }
    ],
    "comments": [
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null
    ],
    "dataType": null
  };
  initializeDataMatrix(dataMatrix6);
  var g3 = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookup(dataMatrix6, attributes, options);
  };
  var g3Linear = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookupLinear(dataMatrix6, attributes, options);
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/dataMatrices/g4.ts
  var dataMatrix7 = {
    "name": "G4",
    "data": [
      [
        -0.75,
        -0.75,
        -0.75,
        -1.5,
        -1.5,
        -1.5,
        null,
        null
      ]
    ],
    "columnAttrs": [
      {
        "attr": "hb_indicator",
        "keys": [
          true
        ],
        "nots": [
          false
        ],
        "type": "boolean",
        "wildcards": [
          false
        ]
      }
    ],
    "rowAttrs": [
      {
        "attr": "cltv",
        "keys": [
          "<=60",
          ">60<=70",
          ">70<=75",
          ">75<=80",
          ">80<=85",
          ">85<=90",
          ">90<=95",
          ">95<=97"
        ],
        "nots": [
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false
        ],
        "type": "number",
        "wildcards": [
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false
        ]
      }
    ],
    "comments": [
      null
    ],
    "dataType": null
  };
  initializeDataMatrix(dataMatrix7);
  var g4 = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookup(dataMatrix7, attributes, options);
  };
  var g4Linear = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookupLinear(dataMatrix7, attributes, options);
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/dataMatrices/g5.ts
  var dataMatrix8 = {
    "name": "G5",
    "data": [
      [
        -0.375
      ],
      [
        -0.75
      ]
    ],
    "columnAttrs": [
      {
        "attr": "ltv",
        "keys": [
          "<=115",
          ">115<=135"
        ],
        "nots": [
          false,
          false
        ],
        "type": "number",
        "wildcards": [
          false,
          false
        ]
      }
    ],
    "rowAttrs": [],
    "comments": [
      null,
      null
    ],
    "dataType": null
  };
  initializeDataMatrix(dataMatrix8);
  var g5 = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookup(dataMatrix8, attributes, options);
  };
  var g5Linear = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookupLinear(dataMatrix8, attributes, options);
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/dataMatrices/g6.ts
  var dataMatrix9 = {
    "name": "G6",
    "data": [
      [
        -0.375,
        -0.75
      ]
    ],
    "columnAttrs": [],
    "rowAttrs": [
      {
        "attr": "ltv",
        "keys": [
          "<=115",
          ">115<=135"
        ],
        "nots": [
          false,
          false
        ],
        "type": "number",
        "wildcards": [
          false,
          false
        ]
      }
    ],
    "comments": [
      null
    ],
    "dataType": null
  };
  initializeDataMatrix(dataMatrix9);
  var g6 = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookup(dataMatrix9, attributes, options);
  };
  var g6Linear = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookupLinear(dataMatrix9, attributes, options);
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/dataMatrices/g7.ts
  var dataMatrix10 = {
    "name": "G7",
    "data": [
      [
        "This",
        "is",
        "a",
        "test",
        "of",
        "string type",
        null,
        null
      ]
    ],
    "columnAttrs": [
      {
        "attr": "hb_indicator",
        "keys": [
          true
        ],
        "nots": [
          false
        ],
        "type": "boolean",
        "wildcards": [
          false
        ]
      }
    ],
    "rowAttrs": [
      {
        "attr": "cltv",
        "keys": [
          "<=60",
          ">60<=70",
          ">70<=75",
          ">75<=80",
          ">80<=85",
          ">85<=90",
          ">90<=95",
          ">95<=97"
        ],
        "nots": [
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false
        ],
        "type": "number",
        "wildcards": [
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false
        ]
      }
    ],
    "comments": [
      null
    ],
    "dataType": "string"
  };
  initializeDataMatrix(dataMatrix10);
  var g7 = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookup(dataMatrix10, attributes, options);
  };
  var g7Linear = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookupLinear(dataMatrix10, attributes, options);
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/dataMatrices/g8.ts
  var dataMatrix11 = {
    "name": "G8",
    "data": [
      [
        "G1"
      ],
      [
        "G2"
      ],
      [
        "G3"
      ]
    ],
    "columnAttrs": [
      {
        "attr": "ltv",
        "keys": [
          "<=115",
          ">115<=135",
          ">135<=140"
        ],
        "nots": [
          false,
          false,
          false
        ],
        "type": "number",
        "wildcards": [
          false,
          false,
          false
        ]
      }
    ],
    "rowAttrs": [],
    "comments": [
      null,
      null,
      null
    ],
    "dataType": "string"
  };
  initializeDataMatrix(dataMatrix11);
  var g8 = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookup(dataMatrix11, attributes, options);
  };
  var g8Linear = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookupLinear(dataMatrix11, attributes, options);
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/dataMatrices/ga.ts
  var dataMatrix12 = {
    "name": "Ga",
    "data": [
      [
        7
      ],
      [
        8
      ]
    ],
    "columnAttrs": [
      {
        "attr": "dg",
        "keys": [
          [
            "G1",
            "G2"
          ],
          [
            "G3"
          ]
        ],
        "nots": [
          false,
          false
        ],
        "type": "string",
        "wildcards": [
          false,
          false
        ]
      }
    ],
    "rowAttrs": [],
    "comments": [
      null,
      null
    ],
    "dataType": null
  };
  initializeDataMatrix(dataMatrix12);
  var ga = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookup(dataMatrix12, attributes, options);
  };
  var gaLinear = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookupLinear(dataMatrix12, attributes, options);
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/dataMatrices/gb.ts
  var dataMatrix13 = {
    "name": "Gb",
    "data": [
      [
        70
      ],
      [
        80
      ],
      [
        90
      ]
    ],
    "columnAttrs": [
      {
        "attr": "property_state",
        "keys": [
          [
            "CA",
            "TX"
          ],
          [
            "GA"
          ],
          [
            "MN"
          ]
        ],
        "nots": [
          false,
          false,
          false
        ],
        "type": "State",
        "wildcards": [
          false,
          false,
          false
        ]
      }
    ],
    "rowAttrs": [],
    "comments": [
      null,
      null,
      null
    ],
    "dataType": null
  };
  initializeDataMatrix(dataMatrix13);
  var gb = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookup(dataMatrix13, attributes, options);
  };
  var gbLinear = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookupLinear(dataMatrix13, attributes, options);
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/dataMatrices/gc.ts
  var dataMatrix14 = {
    "name": "Gc",
    "data": [
      [
        "Gb"
      ]
    ],
    "columnAttrs": [
      {
        "attr": "property_state",
        "keys": [
          [
            "CA",
            "TX"
          ]
        ],
        "nots": [
          false
        ],
        "type": "State",
        "wildcards": [
          false
        ]
      }
    ],
    "rowAttrs": [],
    "comments": [
      null
    ],
    "dataType": "string"
  };
  initializeDataMatrix(dataMatrix14);
  var gc = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookup(dataMatrix14, attributes, options);
  };
  var gcLinear = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookupLinear(dataMatrix14, attributes, options);
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/dataMatrices/gd.ts
  var dataMatrix15 = {
    "name": "Gd",
    "data": [
      [
        456
      ],
      [
        123
      ]
    ],
    "columnAttrs": [
      {
        "attr": "hb_indicator",
        "keys": [
          true,
          false
        ],
        "nots": [
          false,
          false
        ],
        "type": "boolean",
        "wildcards": [
          false,
          false
        ]
      }
    ],
    "rowAttrs": [],
    "comments": [
      null,
      null
    ],
    "dataType": null
  };
  initializeDataMatrix(dataMatrix15);
  var gd = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookup(dataMatrix15, attributes, options);
  };
  var gdLinear = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookupLinear(dataMatrix15, attributes, options);
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/dataMatrices/ge.ts
  var dataMatrix16 = {
    "name": "Ge",
    "data": [
      [
        1.1,
        1.1
      ]
    ],
    "columnAttrs": [],
    "rowAttrs": [
      {
        "attr": "ltv",
        "keys": [
          ">110",
          ">120"
        ],
        "nots": [
          false,
          false
        ],
        "type": "number",
        "wildcards": [
          false,
          false
        ]
      }
    ],
    "comments": [
      null
    ],
    "dataType": null
  };
  initializeDataMatrix(dataMatrix16);
  var ge = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookup(dataMatrix16, attributes, options);
  };
  var geLinear = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookupLinear(dataMatrix16, attributes, options);
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/dataMatrices/gf.ts
  var dataMatrix17 = {
    "name": "Gf",
    "data": [
      [
        "Y"
      ],
      [
        "M"
      ],
      [
        "N"
      ]
    ],
    "columnAttrs": [
      {
        "attr": "b",
        "keys": [
          true,
          null,
          false
        ],
        "nots": [
          false,
          false,
          false
        ],
        "type": "boolean",
        "wildcards": [
          false,
          true,
          false
        ]
      },
      {
        "attr": "i",
        "keys": [
          [
            1
          ],
          [
            2
          ],
          null
        ],
        "nots": [
          false,
          false,
          false
        ],
        "type": "number",
        "wildcards": [
          false,
          false,
          true
        ]
      },
      {
        "attr": "i4",
        "keys": [
          "<10|16",
          null,
          ">10"
        ],
        "nots": [
          false,
          false,
          false
        ],
        "type": "number",
        "wildcards": [
          false,
          true,
          false
        ]
      },
      {
        "attr": "n",
        "keys": [
          "<10.0",
          null,
          null
        ],
        "nots": [
          false,
          false,
          false
        ],
        "type": "number",
        "wildcards": [
          false,
          true,
          true
        ]
      }
    ],
    "rowAttrs": [],
    "comments": [
      null,
      null,
      null
    ],
    "dataType": "string"
  };
  initializeDataMatrix(dataMatrix17);
  var gf = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookup(dataMatrix17, attributes, options);
  };
  var gfLinear = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookupLinear(dataMatrix17, attributes, options);
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/dataMatrices/gg.ts
  var dataMatrix18 = {
    "name": "Gg",
    "data": [
      [
        1
      ],
      [
        21
      ],
      [
        20
      ]
    ],
    "columnAttrs": [
      {
        "attr": "i1",
        "keys": [
          null,
          [
            2
          ],
          [
            2
          ]
        ],
        "nots": [
          false,
          false,
          false
        ],
        "type": "number",
        "wildcards": [
          true,
          false,
          false
        ]
      },
      {
        "attr": "i2",
        "keys": [
          [
            1
          ],
          [
            1
          ],
          null
        ],
        "nots": [
          false,
          false,
          false
        ],
        "type": "number",
        "wildcards": [
          false,
          false,
          true
        ]
      }
    ],
    "rowAttrs": [],
    "comments": [
      null,
      null,
      null
    ],
    "dataType": null
  };
  initializeDataMatrix(dataMatrix18);
  var gg = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookup(dataMatrix18, attributes, options);
  };
  var ggLinear = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookupLinear(dataMatrix18, attributes, options);
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/dataMatrices/gh.ts
  var dataMatrix19 = {
    "name": "Gh",
    "data": [
      [
        10
      ],
      [
        8
      ]
    ],
    "columnAttrs": [
      {
        "attr": "property_state",
        "keys": [
          [
            "NY"
          ],
          null
        ],
        "nots": [
          false,
          false
        ],
        "type": "State",
        "wildcards": [
          false,
          true
        ]
      },
      {
        "attr": "county_name",
        "keys": [
          null,
          [
            "R"
          ]
        ],
        "nots": [
          false,
          false
        ],
        "type": "string",
        "wildcards": [
          true,
          false
        ]
      }
    ],
    "rowAttrs": [],
    "comments": [
      null,
      null
    ],
    "dataType": null
  };
  initializeDataMatrix(dataMatrix19);
  var gh = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookup(dataMatrix19, attributes, options);
  };
  var ghLinear = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookupLinear(dataMatrix19, attributes, options);
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/dataMatrices/gj.ts
  var dataMatrix20 = {
    "name": "Gj",
    "data": [
      [
        0.25
      ],
      [
        0.35
      ]
    ],
    "columnAttrs": [
      {
        "attr": "client_id",
        "keys": [
          null,
          [
            700127
          ]
        ],
        "nots": [
          false,
          false
        ],
        "type": "number",
        "wildcards": [
          true,
          false
        ]
      },
      {
        "attr": "property_state",
        "keys": [
          [
            "CA"
          ],
          [
            "CA"
          ]
        ],
        "nots": [
          false,
          false
        ],
        "type": "State",
        "wildcards": [
          false,
          false
        ]
      }
    ],
    "rowAttrs": [],
    "comments": [
      null,
      null
    ],
    "dataType": null
  };
  initializeDataMatrix(dataMatrix20);
  var gj = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookup(dataMatrix20, attributes, options);
  };
  var gjLinear = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookupLinear(dataMatrix20, attributes, options);
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/dataMatrices/gl.ts
  var dataMatrix21 = {
    "name": "Gl",
    "data": [
      [
        -0.625
      ],
      [
        -1
      ],
      [
        -1.625
      ],
      [
        -0.5
      ]
    ],
    "columnAttrs": [
      {
        "attr": "fha_203k_option2",
        "keys": [
          [
            "Investor Services"
          ],
          [
            "Admin Premium Services",
            "Admin Services",
            "Admin Services Plus"
          ],
          [
            "Admin Services Plus"
          ],
          [
            "Investor Services Acadamy"
          ]
        ],
        "nots": [
          false,
          true,
          false,
          false
        ],
        "type": "string",
        "wildcards": [
          false,
          false,
          false,
          false
        ]
      }
    ],
    "rowAttrs": [],
    "comments": [
      "comment 1",
      "comment 2",
      "comment 3",
      "comment 4"
    ],
    "dataType": null
  };
  initializeDataMatrix(dataMatrix21);
  var gl = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookup(dataMatrix21, attributes, options);
  };
  var glLinear = (attributes, options = { distinct: false, returnData: false }) => {
    return dataMatrixLookupLinear(dataMatrix21, attributes, options);
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/preface.ts
  function preface(data) {
    const users = data.users;
    const total_price = data.total_price + 0.1;
    const order = data.order;
    return { ...data, users, total_price, order };
  }

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/rules/rule1.ts
  var rule1 = (data) => {
    const doubled_price = data.total_price * 2;
    const total_price = doubled_price + 1;
    return {
      total_price
    };
  };
  var rule1Guard = (data) => {
    return true;
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/rules/rule2.ts
  var rule2 = (data) => {
    const doubled_price = data.total_price * 2;
    const total_price = doubled_price + 2;
    return {
      total_price
    };
  };
  var rule2Guard = (data) => {
    return true;
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/rules/rule3WithGuards.ts
  var rule3WithGuards = (data) => {
    const doubled_price = data.total_price * 2;
    const total_price = doubled_price + 3;
    return {
      total_price
    };
  };
  var rule3WithGuardsGuard = (data) => {
    const doubled_price = data.total_price > 100;
    if (doubled_price) {
      return doubled_price;
    }
    return false;
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/aggregationFunction.ts
  function aggregationFunction(data) {
    const state = "SC";
    const all = data;
    const first_price = data[0].total_price ? data[0].total_price : 0;
    const total_price = first_price;
    return { state, all, total_price };
  }

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/support/dataMatrixLookupTests.ts
  var rangeAttrInfo = { "attr": "cltv", "type": "number", "keys": ["<=60", ">60<=70"], "nots": [false, false], "wildcards": [false, false] };
  var assert = function(assertion, msg = "Assertion Failed") {
    msg = msg || "Assertion Failed";
    if (!assertion) {
      throw new Error(msg);
    }
  };
  var testIsRangeKey = function() {
    assert(testing.isRangeKey(rangeAttrInfo.type, rangeAttrInfo.keys[0]), "rangeAttrInfo (an example attr whose keys are ranges) should pass theisRangeKey(rangeAttrInfo,rangeAttrInfo.keys[any]) check.\nrangeAttrInfo: " + rangeAttrInfo);
  };
  var testRangeStringToInterval = function() {
    const expectedRes1 = ["(", 35, Infinity, ")"];
    assert(tupleEquals(expectedRes1, testing.rangeStringToRawInterval(">35")), "1| >35 -> rangeStringToRange = " + testing.rangeStringToRawInterval(">35") + "instead of " + expectedRes1);
    const expectedRes2 = ["[", 35, Infinity, ")"];
    assert(tupleEquals(expectedRes2, testing.rangeStringToRawInterval(">=35")), "2| >=35 -> rangeStringToRange = " + testing.rangeStringToRawInterval(">=35") + "instead of " + expectedRes2);
    const expectedRes3 = ["[", 35, 10, ")"];
    assert(tupleEquals(expectedRes3, testing.rangeStringToRawInterval(">=35<10")), "3| >=35<10 -> rangeStringToRange = " + testing.rangeStringToRawInterval(">=35<10") + "instead of " + expectedRes3);
    const expectedRes4 = ["[", 35, 40, ")"];
    assert(tupleEquals(expectedRes4, testing.rangeStringToRawInterval(">=35<40")), "4| >=35<40 -> rangeStringToRange = " + testing.rangeStringToRawInterval(">=35<40") + "instead of " + expectedRes4);
    const expectedRes5 = ["[", 35, 40, "]"];
    assert(tupleEquals(expectedRes5, testing.rangeStringToRawInterval(">=35<=40")), "5| >=35<=40 -> rangeStringToRange = " + testing.rangeStringToRawInterval(">=35<=40") + "instead of " + expectedRes5);
    const expectedRes6 = ["(", -Infinity, 35, ")"];
    assert(tupleEquals(expectedRes6, testing.rangeStringToRawInterval("<35")), "6| <35 -> rangeStringToRange = " + testing.rangeStringToRawInterval("<35") + "instead of " + expectedRes6);
    const expectedRes7 = ["(", -Infinity, 35, "]"];
    assert(tupleEquals(expectedRes7, testing.rangeStringToRawInterval("<=35")), "7| <35 -> rangeStringToRange = " + testing.rangeStringToRawInterval("<=35") + "instead of " + expectedRes7);
  };
  var tupleEquals = function(tuplea, tupleb) {
    return tuplea.every((val, i) => tupleb[i] === val);
  };
  var objectEquals = function(objecta, objectb) {
    if (Object.keys(objecta).length !== Object.keys(objectb).length) {
      return false;
    }
    for (let key in objecta) {
      if (objectb[key] !== objecta[key]) {
        return false;
      }
    }
    return true;
  };
  var testIndexedNots = function() {
    const dm = {
      name: "dm2",
      data: [["dm1"], ["dm2"], ["dm3"]],
      columnAttrs: [
        {
          attr: "second",
          nots: [false, true, false],
          keys: ["<100", ">200<=250", ">250"],
          type: "number",
          wildcards: [true, true, false]
        },
        {
          attr: "ltv",
          nots: [false, false, false],
          keys: ["<=115", ">115<=135", ">135<=140"],
          type: "number",
          wildcards: [false, false, false]
        }
      ],
      rowAttrs: [
        {
          attr: "row1",
          nots: [true, false, true],
          keys: ["<=115", ">115<=135", ">135<=140"],
          type: "number",
          wildcards: [false, false, true]
        }
      ],
      comments: [null, null, null],
      dataType: "string"
    };
    testing.initializeDataMatrix(dm);
    assert(objectEquals(testing.indicesLookupIndexedNots(dm, "second", 260), [1]), "'second' indexed nots should be [1], not " + testing.indicesLookupIndexedNots(dm, "second", 260));
    assert(objectEquals(testing.indicesLookupIndexedNots(dm, "second", 240), []), "'second' indexed nots should be [], not " + testing.indicesLookupIndexedNots(dm, "second", 240));
    assert(objectEquals(testing.indicesLookupIndexedNots(dm, "ltv", 116), []), "'ltv' indexed nots should be [], not " + testing.indicesLookupIndexedNots(dm, "ltv", 116));
    assert(objectEquals(testing.indicesLookupIndexedNots(dm, "row1", 116), [0, 2]), "'row1' indexed nots should be [0,2], not " + testing.indicesLookupIndexedNots(dm, "row1", 116));
    assert(objectEquals(testing.indicesLookupIndexedNots(dm, "row1", 114), [2]), "'row1' indexed nots should be [2], not " + testing.indicesLookupIndexedNots(dm, "row1", 114));
  };
  var testIndexedWildcards = function() {
    const dm = {
      name: "dm2",
      data: [["dm1"], ["dm2"], ["dm3"]],
      columnAttrs: [
        {
          attr: "second",
          nots: [false, true, false],
          keys: ["<100", ">200<=250", ">250"],
          type: "number",
          wildcards: [true, true, false]
        },
        {
          attr: "ltv",
          nots: [false, false, false],
          keys: ["<=115", ">115<=135", ">135<=140"],
          type: "number",
          wildcards: [false, false, false]
        }
      ],
      rowAttrs: [
        {
          attr: "row1",
          nots: [true, false, true],
          keys: ["<=115", ">115<=135", ">135<=140"],
          type: "number",
          wildcards: [false, false, true]
        }
      ],
      comments: [null, null, null],
      dataType: "string"
    };
    testing.initializeDataMatrix(dm);
    assert(objectEquals(testing.indicesLookupIndexedWildcards(dm, "second"), [0, 1]), "'second' indexed wildcards should be [0,1], not " + testing.indicesLookupIndexedWildcards(dm, "second"));
    assert(objectEquals(testing.indicesLookupIndexedWildcards(dm, "ltv"), []), "'ltv' indexed wildcards should be [], not " + testing.indicesLookupIndexedWildcards(dm, "ltv"));
    assert(objectEquals(testing.indicesLookupIndexedWildcards(dm, "row1"), [2]), "'row1' indexed wildcards should be [2], not " + testing.indicesLookupIndexedWildcards(dm, "row1"));
  };
  var testOpenOrClosedInterval = function() {
    let intervalTree = new main_esm_default();
    intervalTree.insert([1, 3], 0);
    assert(intervalTree.search([2, 2])[0] === 0, "Searching for 2 in RawInterval [1,3] should return 0, not " + intervalTree.search([2, 2]));
    assert(!intervalTree.search([4, 4])[0], "Searching for 4 in RawInterval [1,3] should fail, not return " + intervalTree.search([4, 4]));
    let it2 = new main_esm_default();
    let a3 = new testing.OpenOrClosedInterval(1, 3, true, true);
    it2.insert(a3, 0);
    assert(it2.search([1, 1])[0] === 0, "Searching for 1 in OpenOrClosedInterval [1,3] should return 0, not " + it2.search([1, 1]));
    assert(it2.search([2, 2])[0] === 0, "Searching for 2 in OpenOrClosedInterval [1,3] should return 0, not " + it2.search([2, 2]));
    assert(it2.search([3, 3])[0] === 0, "Searching for 3 in OpenOrClosedInterval [1,3] should return 0, not " + it2.search([3, 3]));
    assert(it2.search([4, 4])[0] !== 0, "Searching for 4 in OpenOrClosedInterval [1,3] should fail, not return " + it2.search([4, 4]));
    assert(it2.search([0, 0])[0] !== 0, "Searching for 0 in OpenOrClosedInterval [1,3] should fail, not return " + it2.search([4, 4]));
    let it3 = new main_esm_default();
    let b = new testing.OpenOrClosedInterval(1, 3, false, true);
    it3.insert(b, 0);
    assert(it3.search([1, 1])[0] !== 0, "Searching for 1 in OpenOrClosedInterval (1,3] should fail, not return " + it3.search([1, 1]));
    assert(it3.search([2, 2])[0] === 0, "Searching for 2 in OpenOrClosedInterval (1,3] should return 0, not " + it3.search([2, 2]));
    assert(it3.search([3, 3])[0] === 0, "Searching for 3 in OpenOrClosedInterval (1,3] should return 0, not " + it3.search([3, 3]));
    let it4 = new main_esm_default();
    let c = new testing.OpenOrClosedInterval(1, 3, true, false);
    it4.insert(c, 0);
    assert(it4.search([1, 1])[0] === 0, "Searching for 1 in OpenOrClosedInterval [1,3) should returin 0, not return " + it4.search([1, 1]));
    assert(it4.search([2, 2])[0] === 0, "Searching for 2 in OpenOrClosedInterval [1,3) should return 0, not " + it4.search([2, 2]));
    assert(it4.search([3, 3])[0] !== 0, "Searching for 3 in OpenOrClosedInterval [1,3) should fail, not return " + it4.search([3, 3]));
    let it5 = new main_esm_default();
    let d = new testing.OpenOrClosedInterval(1, 3, false, false);
    it5.insert(d, 0);
    assert(it5.search([1, 1])[0] !== 0, "Searching for 1 in OpenOrClosedInterval (1,3) should returin 0, not return " + it5.search([1, 1]));
    assert(it5.search([2, 2])[0] === 0, "Searching for 2 in OpenOrClosedInterval (1,3) should return 0, not " + it5.search([2, 2]));
    assert(it5.search([3, 3])[0] !== 0, "Searching for 3 in OpenOrClosedInterval (1,3) should fail, not return " + it5.search([3, 3]));
    let it6 = new main_esm_default();
    it6.insert(new testing.OpenOrClosedInterval(1, 3, false, false), 0);
    it6.insert(new testing.OpenOrClosedInterval(3, 10, true, false), 1);
    it6.insert(new testing.OpenOrClosedInterval(10, 12, false, true), 2);
    it6.insert([13, 15], 3);
    assert(it6.search([1, 1])[0] !== 0 && !it6.search([1, 1])[0], "Searching for 1 in IntervalTree (1,3) -> 0, [3,10) -> 1, (10,12] -> 2, should fail, not return " + it6.search([1, 1]));
    assert(it6.search([2, 2])[0] === 0, "Searching for 2 in IntervalTree (1,3) -> 0, [3,10) -> 1, (10,12] -> 2, should return 0, not " + it6.search([2, 2]));
    assert(it6.search([3, 3])[0] === 1, "Searching for 3 in IntervalTree (1,3) -> 0, [3,10) -> 1, (10,12] -> 2, should return 1, not return " + it6.search([3, 3]));
    assert(!it6.search([10, 10])[0] && it6.search([10, 10])[0] !== 0, "Searching for 10 in IntervalTree (1,3) -> 0, [3,10) -> 1, (10,12] -> 2, should fail, not return " + it6.search([10, 10]));
    assert(it6.search([13, 13])[0] === 3, "Searching for 13 in IntervalTree with both OpenOrClosedIntervals, and NumericTuples, representing the ranges should return 3, not return " + it6.search([13, 13]));
  };
  var runTests = function() {
    assert(objectEquals({}, {}), "{} failed to === {}");
    assert(!objectEquals({ a: 2 }, {}), "{a:2} failed to !== {}");
    assert(!objectEquals({ a: 2 }, { b: 2 }), "{a:2} failed to not !== {b:2}");
    assert(objectEquals({ a: 1, b: 2 }, { a: 1, b: 2 }), "{a: 1, b:2} failed to equal {a:1, b:2}");
    testRangeStringToInterval();
    testOpenOrClosedInterval();
    testIndexedNots();
    testIndexedWildcards();
    testIsRangeKey();
  };

  // tmp/packages/236b696747f77178bf915a7f83f7da/source/index.ts
  var rulesFunctions = [];
  rulesFunctions.push({
    name: "Rule1",
    compute: rule1,
    guard: rule1Guard
  });
  rulesFunctions.push({
    name: "Rule2",
    compute: rule2,
    guard: rule2Guard
  });
  rulesFunctions.push({
    name: "Rule3 With Guards",
    compute: rule3WithGuards,
    guard: rule3WithGuardsGuard
  });
  var dmFunctions = {
    g1,
    g1Linear,
    g1WithNulls,
    g1WithNullsLinear,
    g1WithNulls2,
    g1WithNulls2Linear,
    g1WithRangeNulls,
    g1WithRangeNullsLinear,
    g2,
    g2Linear,
    g3,
    g3Linear,
    g4,
    g4Linear,
    g5,
    g5Linear,
    g6,
    g6Linear,
    g7,
    g7Linear,
    g8,
    g8Linear,
    ga,
    gaLinear,
    gb,
    gbLinear,
    gc,
    gcLinear,
    gd,
    gdLinear,
    ge,
    geLinear,
    gf,
    gfLinear,
    gg,
    ggLinear,
    gh,
    ghLinear,
    gj,
    gjLinear,
    gl,
    glLinear
  };
  var ajv = new import_ajv.default({
    allErrors: true,
    schemas: [DocumentSchema_default, Definitions_default, RuleResultSchema_default]
  });
  var validateDocument = ajv.getSchema("DocumentSchema.json");
  function parse_errors(errors) {
    return errors.map((eobj) => {
      const msg = eobj.message;
      switch (eobj.keyword) {
        case "required": {
          return msg;
        }
        case "maximum":
        case "maxItems":
        case "minimum":
        case "minItems":
        case "type": {
          const dp = eobj.dataPath == "" ? "input" : eobj.dataPath;
          return `${dp}: ${msg}`;
        }
        case "additionalProperties": {
          const property = eobj.params.additionalProperty;
          return `${msg}: ${property}`;
        }
        case "enum": {
          const dp = eobj.dataPath;
          const lov = eobj.params.allowedValues;
          return `${dp}: ${msg}: ${lov}`;
        }
        default:
          return `${msg}: ${JSON.stringify(eobj)}`;
      }
    });
  }
  var call = (data) => {
    const schemaIsValid = validateDocument(data);
    if (!schemaIsValid) {
      return {
        errors: parse_errors(validateDocument.errors),
        error_object: validateDocument.errors
      };
    }
    const immutableData = data;
    const prefacedData = preface(immutableData);
    const rulesResults = rulesFunctions.map((ruleFunctionObj) => {
      if (!ruleFunctionObj.guard(prefacedData)) {
        return null;
      }
      return {
        __metadata__: {
          rule_name: ruleFunctionObj.name
        },
        ...ruleFunctionObj.compute(prefacedData)
      };
    }).filter((result) => result !== null);
    const aggregatedData = aggregationFunction(rulesResults);
    return aggregatedData;
  };
  var testing2 = {
    tests: [
      {
        "id": 1,
        "input": {
          "order": {
            "products": [
              {
                "name": "Water",
                "price": 100.5,
                "amount": 1
              },
              {
                "name": "Hot dog",
                "price": 10,
                "amount": 1
              }
            ],
            "total_price": 110.5
          },
          "users": [
            {
              "age": 25,
              "state": "CA",
              "lastname": "Doe",
              "firstname": "John"
            },
            {
              "age": 42,
              "state": "NY",
              "lastname": "Adams",
              "firstname": "Arthur"
            }
          ],
          "total_price": 110.5
        },
        "expected_output": {
          "all": [
            {
              "total_price": 222.2,
              "__metadata__": {
                "rule_name": "Rule1"
              }
            },
            {
              "total_price": 223.2,
              "__metadata__": {
                "rule_name": "Rule2"
              }
            },
            {
              "total_price": 224.2,
              "__metadata__": {
                "rule_name": "Rule3 With Guards"
              }
            }
          ],
          "state": "SC",
          "total_price": 222.2
        }
      },
      {
        "id": 2,
        "input": {
          "order": {
            "products": [
              {
                "name": "Water",
                "price": 200.5,
                "amount": 1
              },
              {
                "name": "Hot dog",
                "price": 50,
                "amount": 5
              }
            ],
            "total_price": 250.5
          },
          "users": [
            {
              "age": 25,
              "state": "CA",
              "lastname": "Doe",
              "firstname": "John"
            },
            {
              "age": 42,
              "state": "NY",
              "lastname": "Adams",
              "firstname": "Arthur"
            }
          ],
          "total_price": 250.5
        },
        "expected_output": {
          "all": [
            {
              "total_price": 502.2,
              "__metadata__": {
                "rule_name": "Rule1"
              }
            },
            {
              "total_price": 503.2,
              "__metadata__": {
                "rule_name": "Rule2"
              }
            },
            {
              "total_price": 504.2,
              "__metadata__": {
                "rule_name": "Rule3 With Guards"
              }
            }
          ],
          "state": "SC",
          "total_price": 502.2
        }
      }
    ],
    runAll: () => {
      const tests = testing2.tests.map((test) => testing2.run(test));
      return {
        tests,
        passed: !tests.find((r3) => !r3.passed)
      };
    },
    runById: (id) => {
      const test = testing2.tests.find((id2) => id2);
      if (test) {
        return testing2.run(test);
      }
    },
    run: (test) => {
      const output = call(test.input);
      const passed = (0, import_isEqual.default)(output, test.expected_output);
      return {
        ...test,
        passed,
        output
      };
    }
  };
  return source_exports;
})();
/** @license URI.js v4.4.0 (c) 2011 Gary Court. License: http://github.com/garycourt/uri-js */
//# sourceMappingURL=bundle.js.map
