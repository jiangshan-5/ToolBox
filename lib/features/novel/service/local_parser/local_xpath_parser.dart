import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:xml/xml.dart' as xml;
import 'package:xml/xpath.dart';

class LocalXpathParser {
  /// Evaluates an XPath expression against an HTML or XML element/string.
  /// Converts the DOM node tree to XML first to bypass HTML format issues.
  static List<String> evaluateXpath(dynamic element, String xpathStr) {
    xpathStr = xpathStr.trim();
    if (xpathStr.startsWith('@xpath:')) {
      xpathStr = xpathStr.substring(7);
    } else if (xpathStr.startsWith('xpath:')) {
      xpathStr = xpathStr.substring(6);
    }

    if (xpathStr.isEmpty) return [];

    try {
      dom.Node htmlNode;
      if (element is dom.Node) {
        htmlNode = element;
      } else if (element is String) {
        htmlNode = html_parser.parse(element);
      } else {
        htmlNode = html_parser.parse(element.toString());
      }

      final xmlNode = htmlToXmlNode(htmlNode);
      final xpathResult = xmlNode.xpath(xpathStr);
      final List<String> results = [];
      
      for (final node in xpathResult) {
        if (node is xml.XmlAttribute) {
          results.add(node.value.trim());
        } else if (node is xml.XmlText) {
          results.add(node.value.trim());
        } else if (node is xml.XmlElement) {
          results.add(node.innerText.trim());
        } else {
          results.add(node.toString().trim());
        }
      }
      return results.where((r) => r.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  /// Recursively converts HTML parsed nodes into valid XML nodes
  static xml.XmlNode htmlToXmlNode(dom.Node htmlNode) {
    if (htmlNode is dom.Text) {
      return xml.XmlText(htmlNode.text ?? '');
    } else if (htmlNode is dom.Element) {
      final name = htmlNode.localName ?? 'div';
      final List<xml.XmlAttribute> attrs = [];
      htmlNode.attributes.forEach((key, val) {
        final cleanKey = key.toString().replaceAll(RegExp(r'[^a-zA-Z0-9\-_]'), '');
        if (cleanKey.isNotEmpty) {
          attrs.add(xml.XmlAttribute(xml.XmlName(cleanKey), val));
        }
      });
      final List<xml.XmlNode> children = [];
      for (final child in htmlNode.nodes) {
        children.add(htmlToXmlNode(child));
      }
      return xml.XmlElement(xml.XmlName(name), attrs, children);
    } else if (htmlNode is dom.Document) {
      final List<xml.XmlNode> children = [];
      for (final child in htmlNode.nodes) {
        children.add(htmlToXmlNode(child));
      }
      return xml.XmlDocument(children);
    } else if (htmlNode is dom.DocumentFragment) {
      final List<xml.XmlNode> children = [];
      for (final child in htmlNode.nodes) {
        children.add(htmlToXmlNode(child));
      }
      return xml.XmlDocumentFragment(children);
    }
    return xml.XmlText('');
  }
}
