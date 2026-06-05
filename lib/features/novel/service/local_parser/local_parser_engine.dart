import 'dart:convert';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import 'local_jsoup_parser.dart';
import 'local_jsonpath_parser.dart';
import 'local_xpath_parser.dart';
import 'local_js_sandbox.dart';

class SplitRuleResult {
  final List<String> parts;
  final String op;
  SplitRuleResult(this.parts, this.op);
}

class LocalParserEngine {
  /// Splits a rule string by operators (&&, ||, %%) at depth 0
  static SplitRuleResult splitRule(String ruleStr) {
    if (ruleStr.isEmpty) {
      return SplitRuleResult([], '');
    }

    int depthBracket = 0;
    int depthParen = 0;
    bool inSingleQuote = false;
    bool inDoubleQuote = false;
    bool escaped = false;
    
    final operators = ['&&', '||', '%%'];
    String? foundOp;
    
    int n = ruleStr.length;
    int i = 0;
    while (i < n) {
      final c = ruleStr[i];
      if (escaped) {
        escaped = false;
        i++;
        continue;
      }
      if (c == '\\') {
        escaped = true;
        i++;
        continue;
      }
      if (c == "'" && !inDoubleQuote) {
        inSingleQuote = !inSingleQuote;
        i++;
        continue;
      }
      if (c == '"' && !inSingleQuote) {
        inDoubleQuote = !inDoubleQuote;
        i++;
        continue;
      }
      
      if (!inSingleQuote && !inDoubleQuote) {
        if (c == '[') {
          depthBracket++;
        } else if (c == ']') {
          depthBracket = depthBracket > 0 ? depthBracket - 1 : 0;
        } else if (c == '(') {
          depthParen++;
        } else if (c == ')') {
          depthParen = depthParen > 0 ? depthParen - 1 : 0;
        } else if (depthBracket == 0 && depthParen == 0) {
          for (final op in operators) {
            if (ruleStr.startsWith(op, i)) {
              foundOp = op;
              break;
            }
          }
        }
      }
      if (foundOp != null) {
        break;
      }
      i++;
    }
    
    if (foundOp == null) {
      return SplitRuleResult([ruleStr], '');
    }
    
    final List<String> parts = [];
    final List<String> currentPart = [];
    depthBracket = 0;
    depthParen = 0;
    inSingleQuote = false;
    inDoubleQuote = false;
    escaped = false;
    
    i = 0;
    while (i < n) {
      final c = ruleStr[i];
      if (escaped) {
        escaped = false;
        currentPart.add(c);
        i++;
        continue;
      }
      if (c == '\\') {
        escaped = true;
        currentPart.add(c);
        i++;
        continue;
      }
      if (c == "'" && !inDoubleQuote) {
        inSingleQuote = !inSingleQuote;
        currentPart.add(c);
        i++;
        continue;
      }
      if (c == '"' && !inSingleQuote) {
        inDoubleQuote = !inDoubleQuote;
        currentPart.add(c);
        i++;
        continue;
      }
      
      if (!inSingleQuote && !inDoubleQuote) {
        if (c == '[') {
          depthBracket++;
          currentPart.add(c);
        } else if (c == ']') {
          depthBracket = depthBracket > 0 ? depthBracket - 1 : 0;
          currentPart.add(c);
        } else if (c == '(') {
          depthParen++;
          currentPart.add(c);
        } else if (c == ')') {
          depthParen = depthParen > 0 ? depthParen - 1 : 0;
          currentPart.add(c);
        } else if (depthBracket == 0 && depthParen == 0 && ruleStr.startsWith(foundOp, i)) {
          parts.add(currentPart.join().trim());
          currentPart.clear();
          i += foundOp.length;
          continue;
        } else {
          currentPart.add(c);
        }
      } else {
        currentPart.add(c);
      }
      i++;
    }
    parts.add(currentPart.join().trim());
    return SplitRuleResult(parts, foundOp);
  }

  /// Evaluates regular expression replacements in text (pattern##replace)
  static String applyRegexReplacements(String text, String ruleStr) {
    if (!ruleStr.contains('##')) {
      return text;
    }
    final parts = ruleStr.split('##');
    var curr = text;
    int i = 1;
    while (i < parts.length) {
      final regexPat = parts[i];
      var replaceVal = (i + 1 < parts.length) ? parts[i + 1] : '';
      
      // Translate Python's \1 \2 captures to Dart's $1 $2 captures
      replaceVal = replaceVal.replaceAllMapped(RegExp(r'\\(\d)'), (match) {
        return '\$${match.group(1)}';
      });
      
      try {
        curr = curr.replaceAll(RegExp(regexPat, multiLine: true, dotAll: true), replaceVal);
      } catch (_) {}
      i += 2;
    }
    return curr;
  }

  /// Core selector evaluation matching Python's evaluate_selector
  static String evaluateSelector(dynamic element, String selectorStr, Map<String, dynamic> variables) {
    if (element == null || selectorStr.isEmpty) {
      return '';
    }

    // 1. Parse and extract @put directive
    if (selectorStr.contains('@put:')) {
      final parts = selectorStr.split('@put:');
      final baseSelector = parts[0].trim();
      final putContent = parts[1].trim();
      
      if (putContent.startsWith('{') && putContent.endsWith('}')) {
        final inner = putContent.substring(1, putContent.length - 1).trim();
        if (inner.contains(':')) {
          final idx = inner.indexOf(':');
          final varName = inner.substring(0, idx).trim();
          final varSelector = inner.substring(idx + 1).trim();
          
          final varVal = evaluateSelector(element, varSelector, variables);
          if (varName.isNotEmpty && varVal.isNotEmpty) {
            variables[varName] = varVal;
          }
        }
      }
      selectorStr = baseSelector;
    }

    // 2. Check if the selector is a template string containing placeholders
    if ((selectorStr.contains('{{') && selectorStr.contains('}}')) || 
        (selectorStr.contains('{') && selectorStr.contains('}') && !selectorStr.trim().startsWith('{'))) {
      var interpolated = selectorStr;
      
      // Process double curly braces {{...}}
      final doubleReg = RegExp(r'\{\{([^}]+)\}\}');
      final doubleMatches = doubleReg.allMatches(interpolated).toList();
      for (final m in doubleMatches.reversed) {
        final p = m.group(1)!.trim();
        var val = evaluateSelector(element, p, variables);
        if (val.isEmpty) {
          var key = p;
          if (key.startsWith('\$.')) key = key.substring(2);
          if (key.startsWith('@get:{') && key.endsWith('}')) {
            key = key.substring(6, key.length - 1);
          } else if (key.startsWith('@get:')) {
            key = key.substring(5);
          }
          if (variables.containsKey(key)) {
            val = variables[key].toString();
          }
        }
        interpolated = interpolated.replaceRange(m.start, m.end, val);
      }
      
      // Process single curly braces {...}
      final singleReg = RegExp(r'(?<!\{)\{([^{}]+)\}(?!\})');
      final singleMatches = singleReg.allMatches(interpolated).toList();
      for (final m in singleMatches.reversed) {
        final p = m.group(1)!.trim();
        if (!p.contains(':') || p.startsWith('\$.') || p.startsWith('@')) {
          var val = evaluateSelector(element, p, variables);
          if (val.isEmpty) {
            var key = p;
            if (key.startsWith('\$.')) key = key.substring(2);
            if (key.startsWith('@get:{') && key.endsWith('}')) {
              key = key.substring(6, key.length - 1);
            } else if (key.startsWith('@get:')) {
              key = key.substring(5);
            }
            if (variables.containsKey(key)) {
              val = variables[key].toString();
            }
          }
          interpolated = interpolated.replaceRange(m.start, m.end, val);
        }
      }
      return interpolated;
    }

    // 3. Extract regex replacements (##regex##replace)
    var baseSelector = selectorStr;
    var regexPart = '';
    if (selectorStr.contains('##')) {
      final parts = selectorStr.split('##');
      baseSelector = parts[0].trim();
      regexPart = '##' + parts.sublist(1).join('##');
    }

    // 4. Extract JS logic (@js:... or <js>...</js>)
    var jsCode = '';
    if (baseSelector.contains('@js:')) {
      final idx = baseSelector.indexOf('@js:');
      jsCode = baseSelector.substring(idx);
      baseSelector = baseSelector.substring(0, idx).trim();
    } else if (baseSelector.contains('<js>')) {
      final idx = baseSelector.indexOf('<js>');
      jsCode = baseSelector.substring(idx);
      baseSelector = baseSelector.substring(0, idx).trim();
    }

    // 5. Check for operators in the base selector and evaluate
    final splitRes = splitRule(baseSelector);
    String resultText;
    
    if (splitRes.op.isNotEmpty) {
      final List<List<String>> subResults = [];
      for (final r in splitRes.parts) {
        final res = evaluateSelectorToList(element, r, variables);
        if (res.isNotEmpty) {
          subResults.add(res);
        }
      }
      
      final List<String> combinedList = [];
      if (splitRes.op == '||') {
        for (final res in subResults) {
          if (res.isNotEmpty) {
            combinedList.addAll(res);
            break;
          }
        }
      } else if (splitRes.op == '&&') {
        for (final res in subResults) {
          combinedList.addAll(res);
        }
      } else if (splitRes.op == '%%') {
        if (subResults.isNotEmpty) {
          final maxLen = subResults.map((l) => l.length).reduce((a, b) => a > b ? a : b);
          for (int idx = 0; idx < maxLen; idx++) {
            for (final res in subResults) {
              if (idx < res.length) {
                combinedList.add(res[idx]);
              }
            }
          }
        }
      }
      resultText = combinedList.join('\n');
    } else {
      if (baseSelector.isNotEmpty) {
        resultText = evaluateSingleSelector(element, baseSelector, variables);
      } else {
        if (element is dom.Element) {
          resultText = element.text.trim();
        } else {
          resultText = element.toString().trim();
        }
      }
    }

    // 6. Apply JS transformation
    if (jsCode.isNotEmpty) {
      resultText = LocalJsSandbox.evaluateJs(resultText, jsCode, variables: variables);
    }

    // 7. Apply regex replacements
    if (regexPart.isNotEmpty) {
      resultText = applyRegexReplacements(resultText, regexPart);
    }

    return resultText;
  }

  /// Evaluates a selector and returns a list of strings
  static List<String> evaluateSelectorToList(dynamic element, String selectorStr, Map<String, dynamic> variables) {
    if (element == null || selectorStr.isEmpty) {
      return [];
    }

    var baseSelector = selectorStr;
    var regexPart = '';
    if (selectorStr.contains('##')) {
      final parts = selectorStr.split('##');
      baseSelector = parts[0].trim();
      regexPart = '##' + parts.sublist(1).join('##');
    }

    var jsCode = '';
    if (baseSelector.contains('@js:')) {
      final idx = baseSelector.indexOf('@js:');
      jsCode = baseSelector.substring(idx);
      baseSelector = baseSelector.substring(0, idx).trim();
    } else if (baseSelector.contains('<js>')) {
      final idx = baseSelector.indexOf('<js>');
      jsCode = baseSelector.substring(idx);
      baseSelector = baseSelector.substring(0, idx).trim();
    }

    final splitRes = splitRule(baseSelector);
    List<String> combinedList = [];
    
    if (splitRes.op.isNotEmpty) {
      final List<List<String>> subResults = [];
      for (final r in splitRes.parts) {
        final res = evaluateSelectorToList(element, r, variables);
        if (res.isNotEmpty) {
          subResults.add(res);
        }
      }
      
      if (splitRes.op == '||') {
        for (final res in subResults) {
          if (res.isNotEmpty) {
            combinedList = res;
            break;
          }
        }
      } else if (splitRes.op == '&&') {
        for (final res in subResults) {
          combinedList.addAll(res);
        }
      } else if (splitRes.op == '%%') {
        if (subResults.isNotEmpty) {
          final maxLen = subResults.map((l) => l.length).reduce((a, b) => a > b ? a : b);
          for (int idx = 0; idx < maxLen; idx++) {
            for (final res in subResults) {
              if (idx < res.length) {
                combinedList.add(res[idx]);
              }
            }
          }
        }
      }
    } else {
      if (baseSelector.isNotEmpty) {
        combinedList = evaluateSingleSelectorToList(element, baseSelector, variables);
      } else {
        if (element is dom.Element) {
          combinedList = [element.text.trim()];
        } else if (element != null) {
          combinedList = [element.toString().trim()];
        }
      }
    }

    if (jsCode.isNotEmpty) {
      final resultStr = combinedList.join('\n');
      final jsRes = LocalJsSandbox.evaluateJs(resultStr, jsCode, variables: variables);
      combinedList = jsRes.isNotEmpty ? [jsRes] : [];
    }

    if (regexPart.isNotEmpty && combinedList.isNotEmpty) {
      combinedList = combinedList.map((item) => applyRegexReplacements(item, regexPart)).toList();
    }

    return combinedList;
  }

  /// Evaluates a single selector with no operators
  static String evaluateSingleSelector(dynamic element, String selectorStr, Map<String, dynamic> variables) {
    final results = evaluateSingleSelectorToList(element, selectorStr, variables);
    if (results.isEmpty) return '';
    if (results.length == 1) return results[0];
    return results.join('\n');
  }

  /// Evaluates a single selector without operators to a list of strings
  static List<String> evaluateSingleSelectorToList(dynamic element, String selectorStr, Map<String, dynamic> variables) {
    if (element == null || selectorStr.isEmpty) return [];

    // Check if element is a JSON structure
    bool isJson = false;
    dynamic jsonData;
    if (element is Map || element is List) {
      jsonData = element;
      isJson = true;
    } else if (element is String) {
      final trimmed = element.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          jsonData = jsonDecode(trimmed);
          isJson = true;
        } catch (_) {}
      }
    }

    if (isJson && jsonData != null) {
      final val = LocalJsonpathParser.evaluateJsonpath(jsonData, selectorStr);
      if (val is List) {
        return val.map((item) => item?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      }
      return val != null ? [val.toString()] : [];
    } else if (selectorStr.startsWith('//') || selectorStr.startsWith('@xpath:') || selectorStr.startsWith('xpath:')) {
      return LocalXpathParser.evaluateXpath(element, selectorStr);
    } else if (selectorStr.startsWith('\$.') || selectorStr.startsWith('@json:') || selectorStr.startsWith('json:')) {
      String textContent = (element is dom.Element) ? element.text : element.toString();
      try {
        final jsData = jsonDecode(textContent.trim());
        final val = LocalJsonpathParser.evaluateJsonpath(jsData, selectorStr);
        if (val is List) {
          return val.map((item) => item?.toString() ?? '').where((s) => s.isNotEmpty).toList();
        }
        return val != null ? [val.toString()] : [];
      } catch (_) {
        return [];
      }
    } else {
      dom.Element htmlElement;
      if (element is dom.Element) {
        htmlElement = element;
      } else {
        htmlElement = html_parser.parse(element.toString()).body ?? dom.Element.tag('body');
      }
      return LocalJsoupParser.evaluateSingleSelectorToList(htmlElement, selectorStr);
    }
  }

  /// Evaluates selector to a list of sub-elements or strings
  static List<dynamic> evaluateListSelector(dynamic element, String selectorStr, Map<String, dynamic> variables) {
    if (element == null || selectorStr.isEmpty) return [];

    var baseSelector = selectorStr;
    if (selectorStr.contains('##')) {
      baseSelector = selectorStr.split('##')[0].trim();
    }
    if (baseSelector.contains('@js:')) {
      baseSelector = baseSelector.split('@js:')[0].trim();
    } else if (baseSelector.contains('<js>')) {
      baseSelector = baseSelector.split('<js>')[0].trim();
    }

    final splitRes = splitRule(baseSelector);
    if (splitRes.op.isNotEmpty) {
      final List<List<dynamic>> subResults = [];
      for (final r in splitRes.parts) {
        final res = evaluateListSelector(element, r, variables);
        if (res.isNotEmpty) {
          subResults.add(res);
        }
      }
      
      final List<dynamic> combinedList = [];
      if (splitRes.op == '||') {
        for (final res in subResults) {
          if (res.isNotEmpty) {
            combinedList.addAll(res);
            break;
          }
        }
      } else if (splitRes.op == '&&') {
        for (final res in subResults) {
          combinedList.addAll(res);
        }
      } else if (splitRes.op == '%%') {
        if (subResults.isNotEmpty) {
          final maxLen = subResults.map((l) => l.length).reduce((a, b) => a > b ? a : b);
          for (int idx = 0; idx < maxLen; idx++) {
            for (final res in subResults) {
              if (idx < res.length) {
                combinedList.add(res[idx]);
              }
            }
          }
        }
      }
      return combinedList;
    } else {
      return evaluateSingleListSelector(element, baseSelector, variables);
    }
  }

  /// Evaluates a single list selector with no operators
  static List<dynamic> evaluateSingleListSelector(dynamic element, String baseSelector, Map<String, dynamic> variables) {
    if (element == null || baseSelector.isEmpty) return [];

    if (baseSelector.trim().startsWith(':')) return []; // ignore regex base

    bool isJson = false;
    dynamic jsonData;
    if (element is Map || element is List) {
      jsonData = element;
      isJson = true;
    } else if (element is String) {
      final trimmed = element.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          jsonData = jsonDecode(trimmed);
          isJson = true;
        } catch (_) {}
      }
    }

    if (isJson && jsonData != null) {
      final val = LocalJsonpathParser.evaluateJsonpath(jsonData, baseSelector);
      if (val is List) {
        return val.map((item) => item is Map || item is List ? jsonEncode(item) : item).toList();
      }
      return val != null ? [val] : [];
    } else if (baseSelector.startsWith('//') || baseSelector.startsWith('@xpath:') || baseSelector.startsWith('xpath:')) {
      // In Dart XPath, we return list of XML elements serialized to string
      return LocalXpathParser.evaluateXpath(element, baseSelector);
    } else if (baseSelector.startsWith('\$.') || baseSelector.startsWith('@json:') || baseSelector.startsWith('json:')) {
      String textContent = (element is dom.Element) ? element.text : element.toString();
      try {
        final jsData = jsonDecode(textContent.trim());
        final val = LocalJsonpathParser.evaluateJsonpath(jsData, baseSelector);
        if (val is List) {
          return val.map((item) => item is Map || item is List ? jsonEncode(item) : item).toList();
        }
        return val != null ? [val] : [];
      } catch (_) {
        return [];
      }
    } else {
      dom.Element htmlElement;
      if (element is dom.Element) {
        htmlElement = element;
      } else {
        htmlElement = html_parser.parse(element.toString()).body ?? dom.Element.tag('body');
      }
      return LocalJsoupParser.evaluateElementsPipeline(htmlElement, baseSelector);
    }
  }
}
