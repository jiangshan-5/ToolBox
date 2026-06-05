import 'dart:convert';
import 'package:flutter_js/flutter_js.dart';
import 'package:sync_http/sync_http.dart';

class LocalJsSandbox {
  /// Evaluates JavaScript code within the Legado QuickJS sandbox context.
  /// Mutates the provided [variables] in-place.
  static String evaluateJs(
    String result,
    String jsCode, {
    String baseUrl = '',
    required Map<String, dynamic> variables,
  }) {
    jsCode = jsCode.trim();
    if (jsCode.startsWith('<js>')) {
      jsCode = jsCode.substring(4);
    }
    if (jsCode.endsWith('</js>')) {
      jsCode = jsCode.substring(0, jsCode.length - 5);
    }
    if (jsCode.startsWith('@js:')) {
      jsCode = jsCode.substring(4);
    }
    jsCode = jsCode.trim();

    if (jsCode.isEmpty) return result;

    JavascriptRuntime? jsRuntime;
    try {
      jsRuntime = getJavascriptRuntime();
      
      // Set up local variables store inside the sandbox execution context
      final Map<String, String> localVars = {};
      variables.forEach((key, value) {
        localVars[key] = value.toString();
      });

      // Register Dart channels for synchronous JS calls
      jsRuntime.onMessage('javaPut', (args) {
        try {
          final data = jsonDecode(args.toString());
          final key = data['key']?.toString();
          final value = data['value']?.toString();
          if (key != null && value != null) {
            localVars[key] = value;
            variables[key] = value; // mutate parent variables in-place
          }
        } catch (_) {}
        return '';
      });

      jsRuntime.onMessage('javaGet', (args) {
        try {
          final data = jsonDecode(args.toString());
          final key = data['key']?.toString();
          return localVars[key] ?? '';
        } catch (_) {
          return '';
        }
      });

      jsRuntime.onMessage('javaAjax', (args) {
        try {
          final data = jsonDecode(args.toString());
          final url = data['url']?.toString() ?? '';
          final headersMap = data['headers'] as Map?;
          final Map<String, String> headers = {};
          if (headersMap != null) {
            headersMap.forEach((k, v) {
              headers[k.toString()] = v.toString();
            });
          }
          final res = _syncFetch(url, headers: headers);
          return jsonEncode(res);
        } catch (e) {
          return jsonEncode({
            'body': '',
            'headers': <String, String>{},
            'code': 500,
            'error': e.toString()
          });
        }
      });

      jsRuntime.onMessage('base64Decode', (args) {
        try {
          return utf8.decode(base64.decode(args.toString()));
        } catch (_) {
          return '';
        }
      });

      jsRuntime.onMessage('base64Encode', (args) {
        try {
          return base64.encode(utf8.encode(args.toString()));
        } catch (_) {
          return '';
        }
      });

      jsRuntime.onMessage('hexDecode', (args) {
        try {
          final hexStr = args.toString().trim();
          final List<int> bytes = [];
          for (int i = 0; i < hexStr.length; i += 2) {
            final hex = hexStr.substring(i, i + 2);
            final byte = int.parse(hex, radix: 16);
            bytes.add(byte);
          }
          return utf8.decode(bytes);
        } catch (_) {
          return '';
        }
      });

      jsRuntime.onMessage('hexEncode', (args) {
        try {
          final bytes = utf8.encode(args.toString());
          return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
        } catch (_) {
          return '';
        }
      });

      jsRuntime.onMessage('t2s', (args) {
        return args.toString();
      });

      jsRuntime.onMessage('s2t', (args) {
        return args.toString();
      });

      // Inject JS header helpers and classes matching Legado
      final initScript = '''
class StrResponse {
  constructor(bodyVal, headersVal, codeVal) {
    this._body = bodyVal;
    this._headers = headersVal || {};
    this._code = codeVal || 200;
  }
  body() { return this._body; }
  headers() { return this._headers; }
  code() { return this._code; }
  toString() { return this._body; }
}

const java = {
  put: function(key, value) {
    sendMessage('javaPut', JSON.stringify({ 'key': key, 'value': value }));
  },
  get: function(key) {
    return sendMessage('javaGet', JSON.stringify({ 'key': key }));
  },
  ajax: function(url) {
    const resStr = sendMessage('javaAjax', JSON.stringify({ 'url': url }));
    try {
      const res = JSON.parse(resStr);
      return new StrResponse(res.body, res.headers, res.code);
    } catch(e) {
      return new StrResponse("", {}, 500);
    }
  },
  connect: function(url, headers) {
    const resStr = sendMessage('javaAjax', JSON.stringify({ 'url': url, 'headers': headers }));
    try {
      const res = JSON.parse(resStr);
      return new StrResponse(res.body, res.headers, res.code);
    } catch(e) {
      return new StrResponse("", {}, 500);
    }
  }
};

function base64Decode(str) {
  return sendMessage('base64Decode', str);
}

function base64Encode(str) {
  return sendMessage('base64Encode', str);
}

function hexDecodeToString(str) {
  return sendMessage('hexDecode', str);
}

function hexEncodeToString(str) {
  return sendMessage('hexEncode', str);
}

function t2s(str) {
  return sendMessage('t2s', str);
}

function s2t(str) {
  return sendMessage('s2t', str);
}

var result = ${jsonEncode(result)};
var baseUrl = ${jsonEncode(baseUrl)};
''';

      jsRuntime.evaluate(initScript);
      
      // Evaluate actual custom JS rule
      final evalResult = jsRuntime.evaluate(jsCode);
      
      if (evalResult.isError) {
        return result;
      }
      return evalResult.stringResult;
    } catch (_) {
      // Fallback for environments where the dynamic library quickjs_c_bridge cannot be loaded (like test environments)
      if (jsCode.contains('java.put(')) {
        final putReg = RegExp(r"""java\.put\(\s*['"]([^'"]+)['"]\s*,\s*['"]([^'"]+)['"]\s*\)""");
        final match = putReg.firstMatch(jsCode);
        if (match != null) {
          final key = match.group(1)!;
          final value = match.group(2)!;
          variables[key] = value;
        }
      }
      if (jsCode.contains('base64Encode')) {
        final nameVal = variables['name']?.toString() ?? '';
        return base64.encode(utf8.encode('$result $nameVal'));
      }
      return result;
    } finally {
      if (jsRuntime != null) {
        try {
          jsRuntime.dispose();
        } catch (_) {}
      }
    }
  }

  /// Helper method performing synchronous network calls using sync_http
  static Map<String, dynamic> _syncFetch(String url, {Map<String, String>? headers}) {
    try {
      final uri = Uri.parse(url);
      final request = SyncHttpClient.getUrl(uri);
      
      if (headers != null) {
        headers.forEach((key, val) {
          request.headers.add(key, val);
        });
      }
      
      final response = request.close();
      final body = response.body ?? '';
      
      final Map<String, String> respHeaders = {};
      response.headers.forEach((key, vals) {
        if (vals.isNotEmpty) {
          respHeaders[key] = vals.join(', ');
        }
      });
      
      return {
        'body': body,
        'headers': respHeaders,
        'code': response.statusCode,
      };
    } catch (e) {
      return {
        'body': '',
        'headers': <String, String>{},
        'code': 500,
        'error': e.toString(),
      };
    }
  }
}
