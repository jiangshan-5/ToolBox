class LocalJsonpathParser {
  /// Evaluates a JSONPath query against a decoded JSON object or list.
  /// Standard jsonpath prefixes like $. or @json: are handled.
  static dynamic evaluateJsonpath(dynamic data, String jsonpathStr) {
    if (data == null) return null;
    var path = jsonpathStr.trim();
    if (path.startsWith('@json:')) {
      path = path.substring(6);
    }
    if (path.startsWith('\$.')) {
      path = path.substring(2);
    } else if (path.startsWith('\$')) {
      path = path.substring(1);
    }

    if (path.isEmpty) {
      return data;
    }

    final parts = path.split('.');
    return _walk(data, parts);
  }

  static dynamic _walk(dynamic curr, List<String> parts) {
    if (parts.isEmpty) {
      return curr;
    }
    final part = parts.first;
    final remaining = parts.sublist(1);

    if (part.contains('[') && part.endsWith(']')) {
      final openBracket = part.indexOf('[');
      final key = part.substring(0, openBracket);
      final idxStr = part.substring(openBracket + 1, part.length - 1).trim();
      
      var target = curr;
      if (key.isNotEmpty) {
        if (curr is Map) {
          target = curr[key];
        } else {
          return null;
        }
      }

      if (target == null) {
        return null;
      }

      if (idxStr == '*') {
        if (target is List) {
          final List<dynamic> res = [];
          for (final item in target) {
            final val = _walk(item, remaining);
            if (val != null) {
              if (val is List) {
                res.addAll(val);
              } else {
                res.add(val);
              }
            }
          }
          return res;
        }
        return null;
      } else {
        final idx = int.tryParse(idxStr);
        if (idx != null && target is List) {
          final len = target.length;
          if (idx >= 0 && idx < len) {
            return _walk(target[idx], remaining);
          } else if (idx < 0 && len >= -idx) {
            return _walk(target[idx + len], remaining);
          }
        }
        return null;
      }
    } else {
      if (curr is Map) {
        return _walk(curr[part], remaining);
      } else if (curr is List) {
        final List<dynamic> res = [];
        for (final item in curr) {
          if (item is Map) {
            final val = _walk(item[part], remaining);
            if (val != null) {
              res.add(val);
            }
          }
        }
        return res;
      }
      return null;
    }
  }
}
