import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../model/novel_models.dart';

import 'package:crypto/crypto.dart';

class LocalBookSourceDb {
  static final LocalBookSourceDb instance = LocalBookSourceDb._internal();
  LocalBookSourceDb._internal();

  List<BookSourceRule> _sources = [];
  bool _initialized = false;

  String _generateBookId(String title, String author) {
    final bytes = utf8.encode('$title|$author');
    return md5.convert(bytes).toString();
  }

  Future<void> init() async {
    if (_initialized) return;
    try {
      final file = await _getDatabaseFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        _sources = jsonList.map((item) => BookSourceRule.fromJson(item)).toList();
      } else {
        _sources = [];
      }
    } catch (_) {
      _sources = [];
    }

    if (_sources.isEmpty) {
      await _seedDefaultSources();
    }

    _initialized = true;
  }

  Future<void> _seedDefaultSources() async {
    try {
      final List<dynamic> list = jsonDecode(_defaultSourcesJson);
      final List<BookSourceRule> rules = [];
      for (final item in list) {
        if (item is Map) {
          final name = item['bookSourceName']?.toString() ?? '';
          final sourceUrl = item['bookSourceUrl']?.toString() ?? '';
          if (name.isNotEmpty && sourceUrl.isNotEmpty) {
            rules.add(BookSourceRule(
              id: _generateBookId(name, sourceUrl),
              sourceName: name,
              sourceUrl: sourceUrl,
              searchUrl: item['searchUrl']?.toString() ?? '',
              ruleJson: jsonEncode(item),
              isActive: true,
              isValid: true,
              isPrivate: false,
              isAbyss: false,
            ));
          }
        }
      }
      _sources = rules;
      await save();
    } catch (_) {}
  }

  static const String _defaultSourcesJson = r'''
[
  {
    "bookSourceGroup": "常用合规",
    "bookSourceName": "笔趣阁小说",
    "bookSourceUrl": "https://www.ibiquges.org",
    "searchUrl": "https://www.ibiquges.org/modules/article/search.php?searchkey=%s",
    "ruleSearch": {
      "bookList": "tr",
      "name": "td.odd a@text",
      "author": "td.odd[1]@text",
      "intro": "td.even@text",
      "coverUrl": "",
      "bookUrl": "td.odd a@href"
    },
    "ruleToc": {
      "chapterList": "#list dd",
      "chapterName": "a@text",
      "chapterUrl": "a@href"
    },
    "ruleContent": {
      "content": "#content@text"
    }
  },
  {
    "bookSourceGroup": "常用合规",
    "bookSourceName": "七游小说",
    "bookSourceUrl": "https://www.qiyou.biz",
    "searchUrl": "https://www.qiyou.biz/search?key=%s",
    "ruleSearch": {
      "bookList": ".book-list li",
      "name": ".title a@text",
      "author": ".author@text",
      "intro": ".desc@text",
      "coverUrl": "img@src",
      "bookUrl": ".title a@href"
    },
    "ruleToc": {
      "chapterList": ".chapter-list a",
      "chapterName": "text",
      "chapterUrl": "href"
    },
    "ruleContent": {
      "content": ".content-detail@text"
    }
  },
  {
    "bookSourceGroup": "API",
    "bookSourceName": "酷我小说",
    "bookSourceType": 0,
    "bookSourceUrl": "http://appi.kuwo.cn",
    "customOrder": 4,
    "enabled": true,
    "enabledCookieJar": true,
    "enabledExplore": false,
    "header": "{\n\t\"Accept\": \"*/*\",\n\t\"Connection\": \"Close\",\n\t\"User-Agent\": \"Dalvik/2.1.0 (Linux; U; Android 8.0.0; LND-AL40 Build/HONORLND-AL40)\"\n}",
    "ruleBookInfo": {
      "author": "$.author_name",
      "coverUrl": "$.cover_url",
      "init": "$.data",
      "intro": "$.intro##(^|[。！？]+[”专」）】]?)##$1<br>",
      "kind": "{{$.category_name}},{{$.status}},{{$.update_time}}@js:result.replace(/30/,\"连载\").replace(/50/,\"完结\").replace(/\\s..:.*/,\"\")",
      "lastChapter": "$.new_chapter_name##正文卷.|正文.|VIP卷.|默认卷.|卷_|VIP章节.|免费章节.|章节目录.|最新章节.|[\\(（【].*?[求更票谢乐发订合补加架字修Kk].*?[】）\\)]",
      "name": "$.title",
      "tocUrl": "/novels/api/book/{{$.book_id}}/chapters?paging=0",
      "wordCount": "$.all_words"
    },
    "ruleContent": {
      "content": "$.data.content"
    },
    "ruleExplore": {},
    "ruleSearch": {
      "author": "$.author_name",
      "bookList": "$.data",
      "bookUrl": "/novels/api/book/{{$.book_id}}",
      "coverUrl": "$.cover_url",
      "intro": "$.intro",
      "kind": "{{$.category_name}},{{$.status}}@js:result.replace(/30/,\"连载\").replace(/50/,\"完结\")",
      "name": "$.title",
      "wordCount": "$.all_words"
    },
    "ruleToc": {
      "chapterList": "$.data",
      "chapterName": "$.chapter_title##正文卷.|正文.|VIP卷.|默认卷.|卷_|VIP章节.|免费章节.|章节目录.|最新章节.|[\\(（【].*?[求更票谢乐发订合补加架字修Kk].*?[】）\\)]",
      "chapterUrl": "/novels/api/book/{{$.book_id}}/chapters/{{$.chapter_id}}",
      "updateTime": "{{$.volume_name}}•{{$.original_words}}字"
    },
    "searchUrl": "/novels/api/book/search?keyword={{key}}&pi={{page}}&ps=30",
    "weight": 50
  },
  {
    "bookSourceComment": "",
    "bookSourceGroup": "校验可用",
    "bookSourceName": "笔趣阁(xinbiquge)",
    "bookSourceType": 0,
    "bookSourceUrl": "https://wap2.xinbiquge.org##旅途",
    "customOrder": 666,
    "enabled": true,
    "enabledCookieJar": false,
    "enabledExplore": true,
    "ruleBookInfo": {
      "author": "[property$=author]@content",
      "coverUrl": "[property=og:image]@content",
      "init": "",
      "intro": "[property=og:description]@content",
      "kind": "[property~=(category|status|update_time)]@content",
      "lastChapter": "[property=og:novel:latest_chapter_name]@content",
      "name": "[property=og:novel:book_name]@content"
    },
    "ruleContent": {
      "content": "#chaptercontent@html",
      "nextContentUrl": "text.下一章@href",
      "replaceRegex": "##.*\\(\\d+ / \\d+\\).*\\n|新笔趣阁.*\\s*|\\s*.*下一页继续阅读.*|.本章阅读完毕.*\\s*"
    },
    "ruleSearch": {
      "author": ".author@span@text",
      "bookList": ".hot_sale",
      "bookUrl": "a@href",
      "checkKeyWord": "我的青春",
      "name": ".title@text"
    },
    "ruleToc": {
      "chapterList": ".book_last.-1@dd a",
      "chapterName": "text",
      "chapterUrl": "href"
    },
    "searchUrl": "https://wap2.xinbiquge.org/book/search.aspx?ie=utf-8&siteid=xinbiquge.org&s=000&key={{key}}",
    "weight": 0
  },
  {
    "bookSourceComment": "",
    "bookSourceGroup": "校验可用",
    "bookSourceName": "笔趣阁⑥-🔖",
    "bookSourceType": 0,
    "bookSourceUrl": "https://wap2.xinbiquge.org",
    "customOrder": 1455,
    "enabled": true,
    "enabledCookieJar": false,
    "enabledExplore": true,
    "ruleBookInfo": {
      "author": "[property$=author]@content",
      "coverUrl": "[property=og:image]@content",
      "init": "",
      "intro": "[property=og:description]@content",
      "kind": "[property~=(category|status|update_time)]@content",
      "lastChapter": "[property=og:novel:latest_chapter_name]@content",
      "name": "[property=og:novel:book_name]@content"
    },
    "ruleContent": {
      "content": "#chaptercontent@html",
      "nextContentUrl": "text.下一章@href",
      "replaceRegex": "##.*\\(\\d+ / \\d+\\).*\\n|新笔趣阁.*\\s*|\\s*.*下一页继续阅读.*|.本章阅读完毕.*\\s*"
    },
    "ruleExplore": {},
    "ruleReview": {},
    "ruleSearch": {
      "author": ".author@span@text",
      "bookList": ".hot_sale",
      "bookUrl": "a@href",
      "checkKeyWord": "我的青春",
      "name": ".title@text"
    },
    "ruleToc": {
      "chapterList": ".book_last.-1@dd a",
      "chapterName": "text",
      "chapterUrl": "href"
    },
    "searchUrl": "https://wap2.xinbiquge.org/book/search.aspx?ie=utf-8&siteid=xinbiquge.org&s=000&key={{key}}",
    "weight": 0
  },
  {
    "bookSourceComment": "",
    "bookSourceGroup": "校验可用",
    "bookSourceName": "笔趣阁77",
    "bookSourceType": 0,
    "bookSourceUrl": "https://www.biquge7.xyz/",
    "customOrder": 1541,
    "enabled": true,
    "enabledCookieJar": false,
    "enabledExplore": true,
    "ruleBookInfo": {
      "author": "class.author@text##作者：",
      "coverUrl": "img@src",
      "intro": "class.des.p.1@text",
      "lastChapter": "class.upd.a@text##最新章节：",
      "name": "class.tits.h1@text",
      "tocUrl": ""
    },
    "ruleContent": {
      "content": "class.text@text##\\【看书.*|交流好书.*",
      "replaceRegex": ""
    },
    "ruleExplore": {},
    "ruleReview": {},
    "ruleSearch": {
      "author": "class.author@text",
      "bookList": "class.tui_1_item",
      "bookUrl": ".title a@href",
      "coverUrl": "img@src",
      "intro": "",
      "name": "img@alt"
    },
    "ruleToc": {
      "chapterList": "div.list ul li",
      "chapterName": "a@text",
      "chapterUrl": "a@href"
    },
    "searchUrl": "https://www.biquge7.xyz/search?keyword={{key}}",
    "weight": 0
  }
]
''' ;


  Future<File> _getDatabaseFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/book_sources.json');
  }

  Future<void> save() async {
    try {
      final file = await _getDatabaseFile();
      final content = jsonEncode(_sources.map((e) => e.toJson()).toList());
      await file.writeAsString(content);
    } catch (_) {}
  }

  List<BookSourceRule> getAllSources() {
    return List.from(_sources);
  }

  BookSourceRule? getSourceById(String id) {
    try {
      return _sources.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addSource(BookSourceRule rule) async {
    // Check duplicate URL
    _sources.removeWhere((element) => element.sourceUrl == rule.sourceUrl);
    _sources.add(rule);
    await save();
  }

  Future<void> addSources(List<BookSourceRule> rules) async {
    for (final rule in rules) {
      _sources.removeWhere((element) => element.sourceUrl == rule.sourceUrl);
      _sources.add(rule);
    }
    await save();
  }

  Future<void> deleteSource(String id) async {
    _sources.removeWhere((element) => element.id == id);
    await save();
  }

  Future<void> toggleSourceActive(String id, bool active) async {
    for (int i = 0; i < _sources.length; i++) {
      if (_sources[i].id == id) {
        final s = _sources[i];
        _sources[i] = BookSourceRule(
          id: s.id,
          sourceName: s.sourceName,
          sourceUrl: s.sourceUrl,
          searchUrl: s.searchUrl,
          ruleJson: s.ruleJson,
          isActive: active,
          isValid: s.isValid,
          isPrivate: s.isPrivate,
          isAbyss: s.isAbyss,
        );
        break;
      }
    }
    await save();
  }
}
