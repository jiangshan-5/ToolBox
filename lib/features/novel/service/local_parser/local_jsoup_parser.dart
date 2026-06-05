import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

class LegadoIndexRange {
  final int? start;
  final int? end;
  final int step;
  LegadoIndexRange(this.start, this.end, this.step);
}

class LegadoJsoupIndex {
  final String beforeRule;
  final String splitChar; // '.', '!', or ' '
  final List<dynamic> indexes;
  LegadoJsoupIndex(this.beforeRule, this.splitChar, this.indexes);
}

class LocalJsoupParser {
  /// Splits a Jsoup rule string by '@' at depth 0, ignoring nested brackets and quotes
  static List<String> splitJsoupRule(String ruleStr) {
    if (ruleStr.isEmpty) return [];
    final List<String> parts = [];
    final List<String> curr = [];
    int depth = 0;
    String? inQuote;
    
    for (int i = 0; i < ruleStr.length; i++) {
      final ch = ruleStr[i];
      if (inQuote != null) {
        if (ch == inQuote) {
          inQuote = null;
        }
        curr.add(ch);
      } else {
        if (ch == "'" || ch == '"') {
          inQuote = ch;
          curr.add(ch);
        } else if (ch == '[' || ch == '(') {
          depth++;
          curr.add(ch);
        } else if (ch == ']' || ch == ')') {
          depth = depth > 0 ? depth - 1 : 0;
          curr.add(ch);
        } else if (ch == '@' && depth == 0) {
          parts.add(curr.join().trim());
          curr.clear();
        } else {
          curr.add(ch);
        }
      }
    }
    if (curr.isNotEmpty) {
      parts.add(curr.join().trim());
    }
    return parts.where((p) => p.isNotEmpty).toList();
  }

  /// Cleans rule strings by stripping prefix indicators and translating class. tag. id.
  static String cleanSelector(String selectorStr) {
    selectorStr = selectorStr.trim();
    if (selectorStr.startsWith('css:')) {
      selectorStr = selectorStr.substring(4).trim();
    } else if (selectorStr.startsWith('@css:')) {
      selectorStr = selectorStr.substring(5).trim();
    } else if (selectorStr.startsWith('CSS:')) {
      selectorStr = selectorStr.substring(4).trim();
    } else if (selectorStr.startsWith('@CSS:')) {
      selectorStr = selectorStr.substring(5).trim();
    }
    
    if (selectorStr.startsWith('class.')) {
      selectorStr = '.' + selectorStr.substring(6);
    } else if (selectorStr.contains(' class.')) {
      selectorStr = selectorStr.replaceAll(' class.', ' .');
    }
    
    if (selectorStr.startsWith('id.')) {
      selectorStr = '#' + selectorStr.substring(3);
    } else if (selectorStr.contains(' id.')) {
      selectorStr = selectorStr.replaceAll(' id.', ' #');
    }
    
    if (selectorStr.startsWith('tag.')) {
      selectorStr = selectorStr.substring(4);
    } else if (selectorStr.contains(' tag.')) {
      selectorStr = selectorStr.replaceAll(' tag.', ' ');
    }
    
    return selectorStr;
  }

  /// Extracts ownText content (only direct child text nodes)
  static String getOwnText(dom.Element element) {
    final buffer = StringBuffer();
    for (final node in element.nodes) {
      if (node.nodeType == dom.Node.TEXT_NODE) {
        buffer.write(node.text);
      }
    }
    return buffer.toString().trim();
  }

  /// Parses Legado index notation in a rule segment
  static LegadoJsoupIndex parseLegadoJsoupIndex(String ruleStr) {
    ruleStr = ruleStr.trim();
    if (ruleStr.isEmpty) {
      return LegadoJsoupIndex('', ' ', []);
    }

    // 1. Bracket notation like tag.div[-1, 0:3] or tag.div[!0:3]
    if (ruleStr.endsWith(']')) {
      final idx = ruleStr.lastIndexOf('[');
      if (idx != -1) {
        final beforeRule = ruleStr.substring(0, idx).trim();
        var bracketContent = ruleStr.substring(idx + 1, ruleStr.length - 1).trim();
        var splitChar = '.';
        if (bracketContent.startsWith('!')) {
          splitChar = '!';
          bracketContent = bracketContent.substring(1).trim();
        }
        
        final List<dynamic> indexes = [];
        final parts = bracketContent.split(',');
        for (var part in parts) {
          part = part.trim();
          if (part.isEmpty) continue;
          if (part.contains(':')) {
            final subparts = part.split(':');
            final start = subparts[0].trim().isNotEmpty ? int.tryParse(subparts[0].trim()) : null;
            final end = (subparts.length > 1 && subparts[1].trim().isNotEmpty) ? int.tryParse(subparts[1].trim()) : null;
            final step = (subparts.length > 2 && subparts[2].trim().isNotEmpty) ? int.tryParse(subparts[2].trim()) ?? 1 : 1;
            indexes.add(LegadoIndexRange(start, end, step));
          } else {
            final val = int.tryParse(part);
            if (val != null) {
              indexes.add(val);
            }
          }
        }
        return LegadoJsoupIndex(beforeRule, splitChar, indexes);
      }
    }

    // 2. Dot/Exclamation/Colon notation like tag.div.-1 or tag.div!0:3
    final reg = RegExp(r'([\.!])(-?\d+(?::-?\d+)*)$');
    final match = reg.firstMatch(ruleStr);
    if (match != null) {
      final splitChar = match.group(1)!;
      final indicesStr = match.group(2)!;
      final beforeRule = ruleStr.substring(0, match.start!).trim();
      
      final parts = indicesStr.split(':');
      final List<int> indexes = [];
      for (var p in parts) {
        final val = int.tryParse(p);
        if (val != null) indexes.add(val);
      }
      return LegadoJsoupIndex(beforeRule, splitChar, indexes);
    }

    return LegadoJsoupIndex(ruleStr, ' ', []);
  }

  /// Filters a list of elements based on index selection/exclusion rules
  static List<dom.Element> applyLegadoIndexes(List<dom.Element> elements, String splitChar, List<dynamic> indexes) {
    if (elements.isEmpty || splitChar == ' ') {
      return elements;
    }
    final n = elements.length;
    final List<int> indexSet = [];
    
    for (final item in indexes) {
      if (item is LegadoIndexRange) {
        var start = item.start ?? 0;
        if (start < 0) start += n;
        
        var end = item.end ?? (n - 1);
        if (end < 0) end += n;
        
        if ((start < 0 && end < 0) || (start >= n && end >= n)) {
          continue;
        }
        
        start = start.clamp(0, n - 1);
        end = end.clamp(0, n - 1);
        
        if (start == end || item.step.abs() >= n) {
          if (!indexSet.contains(start)) {
            indexSet.add(start);
          }
          continue;
        }
        
        final step = item.step > 0 ? item.step : (item.step + n < n ? item.step + n : 1);
        if (end > start) {
          for (var idx = start; idx <= end; idx += step) {
            if (!indexSet.contains(idx)) {
              indexSet.add(idx);
            }
          }
        } else {
          for (var idx = start; idx >= end; idx -= step) {
            if (!indexSet.contains(idx)) {
              indexSet.add(idx);
            }
          }
        }
      } else if (item is int) {
        var idx = item;
        if (idx < 0) idx += n;
        if (idx >= 0 && idx < n) {
          if (!indexSet.contains(idx)) {
            indexSet.add(idx);
          }
        }
      }
    }
    
    if (splitChar == '!') {
      final List<dom.Element> result = [];
      for (var i = 0; i < n; i++) {
        if (!indexSet.contains(i)) {
          result.add(elements[i]);
        }
      }
      return result;
    } else {
      final List<dom.Element> result = [];
      for (final idx in indexSet) {
        result.add(elements[idx]);
      }
      return result;
    }
  }

  /// Selects elements according to the rule prefix (children, class, tag, id, text, or standard CSS selector)
  static List<dom.Element> selectJsoupElements(dom.Element element, String beforeRule) {
    if (beforeRule.isEmpty) {
      return element.children;
    }
    
    final parts = beforeRule.split('.');
    final prefix = parts[0].trim();
    
    if (prefix == 'children') {
      return element.children;
    } else if (prefix == 'class' && parts.length > 1) {
      final className = parts[1].trim();
      return element.querySelectorAll('.$className');
    } else if (prefix == 'tag' && parts.length > 1) {
      final tagName = parts[1].trim();
      return element.querySelectorAll(tagName);
    } else if (prefix == 'id' && parts.length > 1) {
      final idVal = parts[1].trim();
      return element.querySelectorAll('#$idVal');
    } else if (prefix == 'text' && parts.length > 1) {
      final textVal = parts[1].trim();
      final List<dom.Element> results = [];
      void walk(dom.Element el) {
        if (getOwnText(el).contains(textVal)) {
          results.add(el);
        }
        for (final child in el.children) {
          walk(child);
        }
      }
      walk(element);
      return results;
    } else {
      final cleaned = cleanSelector(beforeRule);
      try {
        return element.querySelectorAll(cleaned);
      } catch (_) {
        return [];
      }
    }
  }

  /// Extracts the desired attribute value from a DOM element
  static String extractElementAttribute(dom.Element el, String extractToken) {
    if (extractToken == 'text') {
      return el.text.trim();
    } else if (extractToken == 'textNodes') {
      final List<String> tn = [];
      for (final node in el.nodes) {
        if (node.nodeType == dom.Node.TEXT_NODE) {
          final t = node.text?.trim() ?? '';
          if (t.isNotEmpty) tn.add(t);
        }
      }
      return tn.join('\n');
    } else if (extractToken == 'ownText') {
      return getOwnText(el);
    } else if (extractToken == 'html') {
      // Remove script/style
      final scripts = el.querySelectorAll('script');
      for (final s in scripts) {
        s.remove();
      }
      final styles = el.querySelectorAll('style');
      for (final s in styles) {
        s.remove();
      }
      return el.outerHtml;
    } else if (extractToken == 'all') {
      return el.outerHtml;
    } else {
      final val = el.attributes[extractToken];
      return val?.trim() ?? '';
    }
  }

  /// Core selector pipeline matching Python's evaluate_elements_pipeline
  static List<dom.Element> evaluateElementsPipeline(dom.Element element, String rawSelector) {
    rawSelector = rawSelector.trim();
    if (rawSelector.isEmpty) return [];
    
    bool isCss = false;
    if (rawSelector.startsWith('css:') || rawSelector.startsWith('@css:') || rawSelector.startsWith('CSS:') || rawSelector.startsWith('@CSS:')) {
      isCss = true;
      if (rawSelector.startsWith('css:')) {
        rawSelector = rawSelector.substring(4).trim();
      } else if (rawSelector.startsWith('@css:')) {
        rawSelector = rawSelector.substring(5).trim();
      } else if (rawSelector.startsWith('CSS:')) {
        rawSelector = rawSelector.substring(4).trim();
      } else if (rawSelector.startsWith('@CSS:')) {
        rawSelector = rawSelector.substring(5).trim();
      }
    }

    if (isCss) {
      final tokens = rawSelector.split('@').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
      if (tokens.isEmpty) return [];
      final lastToken = tokens.last;
      String cssSelector;
      if (['text', 'textNodes', 'ownText', 'html', 'all', 'href', 'src', 'alt', 'title', 'content'].contains(lastToken)) {
        cssSelector = tokens.sublist(0, tokens.length - 1).join('@');
      } else {
        cssSelector = rawSelector;
      }
      try {
        return cssSelector.isNotEmpty ? element.querySelectorAll(cssSelector) : [element];
      } catch (_) {
        return [];
      }
    } else {
      final tokens = splitJsoupRule(rawSelector);
      if (tokens.isEmpty) return [];
      
      List<String> evalTokens;
      if (tokens.length > 1) {
        evalTokens = tokens.sublist(0, tokens.length - 1);
      } else {
        final part = tokens.first;
        if (['text', 'textNodes', 'ownText', 'html', 'all', 'href', 'src', 'alt', 'title', 'content'].contains(part)) {
          evalTokens = [];
        } else {
          evalTokens = [part];
        }
      }

      List<dom.Element> currElements = [element];
      for (final token in evalTokens) {
        final List<dom.Element> nextElements = [];
        final parsed = parseLegadoJsoupIndex(token);
        for (final curr in currElements) {
          final selected = selectJsoupElements(curr, parsed.beforeRule);
          final filtered = applyLegadoIndexes(selected, parsed.splitChar, parsed.indexes);
          nextElements.addAll(filtered);
        }
        currElements = nextElements;
      }
      return currElements;
    }
  }

  /// Evaluates CSS/Jsoup selector to a list of strings
  static List<String> evaluateSingleSelectorToList(dom.Element element, String selectorStr) {
    selectorStr = selectorStr.trim();
    if (selectorStr.isEmpty) return [];
    if (selectorStr.startsWith(':')) return []; // regex-based selector ignored

    final currElements = evaluateElementsPipeline(element, selectorStr);
    final tokens = splitJsoupRule(selectorStr);
    String extractToken = 'text';
    if (tokens.length > 1) {
      extractToken = tokens.last;
    } else if (tokens.isNotEmpty) {
      final part = tokens.first;
      if (['text', 'textNodes', 'ownText', 'html', 'all', 'href', 'src', 'alt', 'title', 'content'].contains(part)) {
        extractToken = part;
      }
    }

    final List<String> results = [];
    for (final el in currElements) {
      final val = extractElementAttribute(el, extractToken);
      if (val.isNotEmpty) {
        results.add(val);
      }
    }
    return results;
  }
}
