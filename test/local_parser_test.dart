import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import 'package:toolbox_app/features/novel/service/local_parser/local_jsoup_parser.dart';
import 'package:toolbox_app/features/novel/service/local_parser/local_xpath_parser.dart';
import 'package:toolbox_app/features/novel/service/local_parser/local_js_sandbox.dart';
import 'package:toolbox_app/features/novel/service/local_parser/local_parser_engine.dart';
import 'package:toolbox_app/features/novel/service/local_parser/local_book_source_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('LocalJsoupParser Index Slicing & Exclusions', () {
    const htmlList = '''
    <div class="list">
        <span>Item 1</span>
        <span>Item 2</span>
        <span>Item 3</span>
    </div>
    ''';
    
    late dom.Element soup;
    
    setUp(() {
      final doc = html_parser.parse(htmlList);
      soup = doc.body!;
    });
    
    test('Dot selection index', () {
      final r1 = LocalJsoupParser.evaluateSingleSelectorToList(soup, 'span.0@text');
      expect(r1, equals(['Item 1']));
      
      final r2 = LocalJsoupParser.evaluateSingleSelectorToList(soup, 'span.2@text');
      expect(r2, equals(['Item 3']));
    });

    test('Exclamation exclusion index', () {
      final r1 = LocalJsoupParser.evaluateSingleSelectorToList(soup, 'span!0@text');
      expect(r1, equals(['Item 2', 'Item 3']));
      
      final r2 = LocalJsoupParser.evaluateSingleSelectorToList(soup, 'span!2@text');
      expect(r2, equals(['Item 1', 'Item 2']));
    });

    test('Dot multiple selection indexes', () {
      final r = LocalJsoupParser.evaluateSingleSelectorToList(soup, 'span.0:2@text');
      expect(r, equals(['Item 1', 'Item 3']));
    });

    test('Exclamation multiple exclusion indexes', () {
      final r = LocalJsoupParser.evaluateSingleSelectorToList(soup, 'span!0:2@text');
      expect(r, equals(['Item 2']));
    });

    test('Bracket range selection', () {
      final r1 = LocalJsoupParser.evaluateSingleSelectorToList(soup, 'span[0:1]@text');
      expect(r1, equals(['Item 1', 'Item 2']));

      final r2 = LocalJsoupParser.evaluateSingleSelectorToList(soup, 'span[1:]@text');
      expect(r2, equals(['Item 2', 'Item 3']));

      final r3 = LocalJsoupParser.evaluateSingleSelectorToList(soup, 'span[-1]@text');
      expect(r3, equals(['Item 3']));
    });

    test('Bracket range exclusion', () {
      final r = LocalJsoupParser.evaluateSingleSelectorToList(soup, 'span[!0:1]@text');
      expect(r, equals(['Item 3']));
    });
  });

  group('JSONPath Queries with Negative Indexing', () {
    const jsonStr = '''
    {
      "title": "万古第一神",
      "author": "风青阳",
      "items": [
        {"name": "Chapter 1"},
        {"name": "Chapter 2"},
        {"name": "Chapter 3"}
      ]
    }
    ''';

    test('Basic JSONPath field queries', () {
      final res1 = LocalParserEngine.evaluateSelector(jsonStr, '\$.title', {});
      expect(res1, equals('万古第一神'));

      final res2 = LocalParserEngine.evaluateSelector(jsonStr, 'author', {});
      expect(res2, equals('风青阳'));
    });

    test('JSONPath negative array indices', () {
      final res1 = LocalParserEngine.evaluateSelector(jsonStr, 'items[-1].name', {});
      expect(res1, equals('Chapter 3'));

      final res2 = LocalParserEngine.evaluateSelector(jsonStr, 'items[-2].name', {});
      expect(res2, equals('Chapter 2'));
    });
  });

  group('XPath Queries on HTML Elements', () {
    const html = '''
    <div class="book">
        <a class="title" href="/novel/123.html">万古第一仙</a>
        <span class="author">笔落惊风雨</span>
    </div>
    ''';

    test('XPath selections', () {
      final r1 = LocalXpathParser.evaluateXpath(html, '//a[@class="title"]/text()');
      expect(r1, equals(['万古第一仙']));

      final r2 = LocalXpathParser.evaluateXpath(html, '//span[@class="author"]/@class');
      expect(r2, equals(['author']));
    });
  });

  group('Operator Splitting (||, &&, %%)', () {
    const html = '''
    <div class="book">
        <a class="title" href="/novel/123.html">万古第一仙</a>
        <span class="author">笔落惊风雨</span>
        <span class="translator"></span>
    </div>
    ''';

    test('Operator fallback (||)', () {
      final doc = html_parser.parse(html);
      final soup = doc.body!;

      final r1 = LocalParserEngine.evaluateSelector(soup, 'a.title@text || span.author@text', {});
      expect(r1, equals('万古第一仙'));

      final r2 = LocalParserEngine.evaluateSelector(soup, 'span.translator@text || span.author@text', {});
      expect(r2, equals('笔落惊风雨'));
    });

    test('Operator merging (&&)', () {
      final doc = html_parser.parse(html);
      final soup = doc.body!;

      final r = LocalParserEngine.evaluateSelector(soup, 'a.title@text && span.author@text', {});
      expect(r, equals('万古第一仙\n笔落惊风雨'));
    });

    test('Operator interleaving (%%)', () {
      const htmlList = '''
      <div class="list">
          <span class="first">A1</span>
          <span class="second">B1</span>
          <span class="first">A2</span>
          <span class="second">B2</span>
      </div>
      ''';
      final doc = html_parser.parse(htmlList);
      final soup = doc.body!;

      final r = LocalParserEngine.evaluateSelector(soup, 'span.first@text %% span.second@text', {});
      expect(r, equals('A1\nB1\nA2\nB2'));
    });
  });

  group('JS Sandbox Execution', () {
    test('Simulated variable mutation and log/b64 encoding', () {
      final Map<String, dynamic> variables = {};
      final res = LocalJsSandbox.evaluateJs('hello', 'java.put("name", "John"); base64Encode(result + " " + java.get("name"));', variables: variables);
      
      // Decoded output of base64: "hello John" => "aGVsbG8gSm9obg=="
      expect(res, equals('aGVsbG8gSm9obg=='));
      expect(variables['name'], equals('John'));
    });
  });

  group('LocalBookSourceDb & Import Validation', () {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    
    setUpAll(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return '.';
        }
        return null;
      });
    });

    test('Initializes with default pre-seeded book sources', () async {
      await LocalBookSourceDb.instance.init();
      final sources = LocalBookSourceDb.instance.getAllSources();
      expect(sources, isNotEmpty);
      expect(sources.any((s) => s.sourceName == '笔趣阁小说'), isTrue);
      expect(sources.any((s) => s.sourceName == '七游小说'), isTrue);
    });
  });
}
