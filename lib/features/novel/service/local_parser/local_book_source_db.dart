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
    "header": "{
	\"Accept\": \"*/*\",
	\"Connection\": \"Close\",
	\"User-Agent\": \"Dalvik/2.1.0 (Linux; U; Android 8.0.0; LND-AL40 Build/HONORLND-AL40)\"
}",
    "ruleBookInfo": {
      "author": "$.author_name",
      "coverUrl": "$.cover_url",
      "init": "$.data",
      "intro": "$.intro##(^|[。！？]+[”专」）】]?)##$1<br>",
      "kind": "{{$.category_name}},{{$.status}},{{$.update_time}}@js:result.replace(/30/,\"连载\").replace(/50/,\"完结\").replace(/\s..:.*/,\"\")",
      "lastChapter": "$.new_chapter_name##正文卷.|正文.|VIP卷.|默认卷.|卷_|VIP章节.|免费章节.|章节目录.|最新章节.|[\(（【].*?[求更票谢乐发订合补加架字修Kk].*?[】）\)]",
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
      "chapterName": "$.chapter_title##正文卷.|正文.|VIP卷.|默认卷.|卷_|VIP章节.|免费章节.|章节目录.|最新章节.|[\(（【].*?[求更票谢乐发订合补加架字修Kk].*?[】）\)]",
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
      "replaceRegex": "##.*\(\d+ / \d+\).*\n|新笔趣阁.*\s*|\s*.*下一页继续阅读.*|.本章阅读完毕.*\s*"
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
      "replaceRegex": "##.*\(\d+ / \d+\).*\n|新笔趣阁.*\s*|\s*.*下一页继续阅读.*|.本章阅读完毕.*\s*"
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
      "content": "class.text@text##\【看书.*|交流好书.*",
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
  },
  {
    "bookSourceComment": "",
    "bookSourceGroup": "校验可用",
    "bookSourceName": "话本小说",
    "bookSourceType": 0,
    "bookSourceUrl": "https://so.ihuaben.com/search?keyword=我是",
    "customOrder": 183,
    "enabled": true,
    "enabledCookieJar": true,
    "enabledExplore": true,
    "lastUpdateTime": 1681943269936,
    "respondTime": 1220,
    "ruleBookInfo": {
      "tocUrl": "text.章节目录@href"
    },
    "ruleContent": {
      "content": "#contentsource@html"
    },
    "ruleExplore": {},
    "ruleSearch": {
      "author": "a.text-muted@text",
      "bookList": ".searchresult",
      "bookUrl": "h2 a@href",
      "checkKeyWord": "",
      "name": "h2@text"
    },
    "ruleToc": {
      "chapterList": "-.chapters p",
      "chapterName": "a@text",
      "chapterUrl": "a@href",
      "nextTocUrl": ".pagination a@href",
      "updateTime": ".updateTime@text"
    },
    "searchUrl": "https://so.ihuaben.com/search?keyword={{key}}",
    "weight": 0
  },
  {
    "bookSourceComment": "\"error:搜索内容为空并且没有发现
\"",
    "bookSourceGroup": "校验可用",
    "bookSourceName": "逐浪网手机版",
    "bookSourceType": 0,
    "bookSourceUrl": "https://m.zhulang.com",
    "bookUrlPattern": "",
    "customOrder": 373,
    "enabled": true,
    "enabledCookieJar": false,
    "enabledExplore": true,
    "lastUpdateTime": 1659798729284,
    "loginUrl": "",
    "respondTime": 1469,
    "ruleBookInfo": {
      "author": "class.yellow@text",
      "coverUrl": "class.bk-info@img@data-src",
      "intro": "id.bk-brief@p@text",
      "name": "tag.h3.0@text",
      "tocUrl": "text.开始阅读@href"
    },
    "ruleContent": {
      "content": "class.rd-txt@p@text"
    },
    "ruleExplore": {},
    "ruleSearch": {
      "author": "h4@text",
      "bookList": "id.ret-list@li",
      "bookUrl": "a@href",
      "coverUrl": "img@data-src",
      "name": "h3@text"
    },
    "ruleToc": {
      "chapterList": "class.idx-ol@a",
      "chapterName": "text",
      "chapterUrl": "href",
      "nextTocUrl": "class.blue.0@option!0@value"
    },
    "searchUrl": "https://m.zhulang.com/search/index.html?k={{key}}",
    "weight": 0
  },
  {
    "bookSourceComment": "",
    "bookSourceGroup": "校验可用",
    "bookSourceName": "📚 追光阅读",
    "bookSourceType": 0,
    "bookSourceUrl": "http://touchlife.cootekservice.com",
    "customOrder": 440,
    "enabled": true,
    "enabledCookieJar": false,
    "enabledExplore": true,
    "exploreUrl": "现代都市::http://touchlife.cootekservice.com/doReader/get_books_by_classificationId?_token=e72ca407-9caa-475d-a829-46e15d3d4834&classificationId=4
东方玄幻::http://touchlife.cootekservice.com/doReader/get_books_by_classificationId?_token=e72ca407-9caa-475d-a829-46e15d3d4834&classificationId=13
武侠仙侠::http://touchlife.cootekservice.com/doReader/get_books_by_classificationId?_token=e72ca407-9caa-475d-a829-46e15d3d4834&classificationId=12
历史架空::http://touchlife.cootekservice.com/doReader/get_books_by_classificationId?_token=e72ca407-9caa-475d-a829-46e15d3d4834&classificationId=17
科幻末世::http://touchlife.cootekservice.com/doReader/get_books_by_classificationId?_token=e72ca407-9caa-475d-a829-46e15d3d4834&classificationId=16
游戏竞技::http://touchlife.cootekservice.com/doReader/get_books_by_classificationId?_token=e72ca407-9caa-475d-a829-46e15d3d4834&classificationId=18
西方玄幻::http://touchlife.cootekservice.com/doReader/get_books_by_classificationId?_token=e72ca407-9caa-475d-a829-46e15d3d4834&classificationId=9
豪门总裁::http://touchlife.cootekservice.com/doReader/get_books_by_classificationId?_token=e72ca407-9caa-475d-a829-46e15d3d4834&classificationId=2
古代言情::http://touchlife.cootekservice.com/doReader/get_books_by_classificationId?_token=e72ca407-9caa-475d-a829-46e15d3d4834&classificationId=5
现代言情::http://touchlife.cootekservice.com/doReader/get_books_by_classificationId?_token=e72ca407-9caa-475d-a829-46e15d3d4834&classificationId=10
青春校园::http://touchlife.cootekservice.com/doReader/get_books_by_classificationId?_token=e72ca407-9caa-475d-a829-46e15d3d4834&classificationId=6
仙侠奇缘::http://touchlife.cootekservice.com/doReader/get_books_by_classificationId?_token=e72ca407-9caa-475d-a829-46e15d3d4834&classificationId=7
婚恋情缘::http://touchlife.cootekservice.com/doReader/get_books_by_classificationId?_token=e72ca407-9caa-475d-a829-46e15d3d4834&classificationId=8
玄幻言情::http://touchlife.cootekservice.com/doReader/get_books_by_classificationId?_token=e72ca407-9caa-475d-a829-46e15d3d4834&classificationId=3
穿越重生::http://touchlife.cootekservice.com/doReader/get_books_by_classificationId?_token=e72ca407-9caa-475d-a829-46e15d3d4834&classificationId=1
null",
    "lastUpdateTime": 1685721799184,
    "respondTime": 2239,
    "ruleBookInfo": {},
    "ruleContent": {
      "content": "$..chapterContent"
    },
    "ruleExplore": {
      "author": "bookAuthor",
      "bookList": "result.classificationInfoBooks[*]",
      "bookUrl": "http://touchlife.cootekservice.com/doReader/enter_bookinfo_index?_token=e72ca407-9caa-475d-a829-46e15d3d4834&bookId={$.bookId}",
      "coverUrl": "bookCoverImage",
      "intro": "bookDesc",
      "kind": "bookBClassificationName",
      "name": "bookTitle"
    },
    "ruleReview": {},
    "ruleSearch": {
      "author": "bookAuthor",
      "bookList": "result",
      "bookUrl": "http://touchlife.cootekservice.com/doReader/enter_bookinfo_index?_token=e72ca407-9caa-475d-a829-46e15d3d4834&bookId={$.bookId}",
      "coverUrl": "bookCoverImage",
      "intro": "bookRecommendWords||bookDesc&&copyright_owner",
      "kind": "bookBClassificationName",
      "name": "bookTitle"
    },
    "ruleToc": {
      "chapterList": "result.detailedBookInfo.bookChapterAllInfo",
      "chapterName": "chapterTitle",
      "chapterUrl": "http://touchlife.cootekservice.com/doReader/get_content_by_chapterId?_token=e72ca407-9caa-475d-a829-46e15d3d4834&bookId={$.bookId}&chapterId={$.chapterId}"
    },
    "searchUrl": "http://touchlife.cootekservice.com/doReader/search_book?_token=e72ca407-9caa-475d-a829-46e15d3d4834&action=search_book&search_keyword={{key}}",
    "weight": 0
  },
  {
    "bookSourceGroup": "校验可用",
    "bookSourceName": "小说",
    "bookSourceType": 0,
    "bookSourceUrl": "http://www.yetianlian.info",
    "customOrder": 264,
    "enabled": true,
    "enabledCookieJar": true,
    "enabledExplore": true,
    "lastUpdateTime": 0,
    "respondTime": 2153,
    "ruleBookInfo": {
      "author": "span.1@text",
      "coverUrl": "img@src",
      "intro": "class.intro@text",
      "kind": "span.2@text",
      "lastChapter": "span.last.1@text",
      "name": "h2@text",
      "wordCount": "span.4@text"
    },
    "ruleContent": {
      "content": "div#content.showtxt@text",
      "nextContentUrl": "text.下一章@href"
    },
    "ruleSearch": {
      "author": "class.author@text",
      "bookList": "class.bookbox",
      "bookUrl": "a@href",
      "checkKeyWord": "我的",
      "coverUrl": "img@src",
      "kind": "class.cat@text",
      "lastChapter": "class.update@text",
      "name": "class.bookname@text"
    },
    "ruleToc": {
      "chapterList": "dd",
      "chapterName": "a@text",
      "chapterUrl": "a@href"
    },
    "searchUrl": "http://www.yetianlian.info/s.php?ie=utf-8&q={{key}}",
    "weight": 0
  },
  {
    "bookSourceComment": "",
    "bookSourceGroup": "校验可用",
    "bookSourceName": "猫眼看书",
    "bookSourceType": 0,
    "bookSourceUrl": "http://download.maoyankanshu.la/",
    "customOrder": 364,
    "enabled": false,
    "enabledCookieJar": false,
    "enabledExplore": true,
    "exploreUrl": "[
{\"title\": \"❀❀❀男生频道❀❀❀\",\"url\": \"\",
\"style\": {\"layout_flexGrow\": 0,
\"layout_flexBasisPercent\": 1
}},
{\"title\": \"必读榜\",\"url\": \"http://api.jxgtzxc.com/module/rank?type=1&channel=1&page={{page}}\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"潜力榜\",\"url\": \"http://api.jxgtzxc.com/module/rank?type=5&channel=1&page={{page}}\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"完本榜\",\"url\": \"http://api.jxgtzxc.com/module/rank?type=2&channel=1&page={{page}}\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"更新榜\",\"url\": \"http://api.jxgtzxc.com/module/rank?type=3&channel=1&page={{page}}\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"搜索榜\",\"url\": \"http://api.jxgtzxc.com/module/rank?type=4&channel=1&page={{page}}\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"评论榜\",\"url\": \"http://api.jxgtzxc.com/module/rank?type=6&channel=1&page={{page}}\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"❀❀全部分类❀❀\",\"url\": \"\",
\"style\": {\"layout_flexGrow\": 0,
\"layout_flexBasisPercent\": 1
}},
{\"title\": \"玄幻\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=lejRej\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"武侠\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=nel5aK\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"都市\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=mbk5ez\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"仙侠\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=vbmOeY\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"军事\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=penRe7\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"历史\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=xbojag\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"游戏\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=mep2bM\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"科幻\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=zbq2dp\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"轻小说\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=YerEdO\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"❀❀完结❀❀\",\"url\": \"\",
\"style\": {\"layout_flexGrow\": 0,
\"layout_flexBasisPercent\": 1
}},
{\"title\": \"玄幻\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=lejRej&isComplete=1\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"武侠\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=nel5aK&isComplete=1\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"都市\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=mbk5ez&isComplete=1\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"仙侠\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=vbmOeY&isComplete=1\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"军事\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=penRe7&isComplete=1\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"历史\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=xbojag&isComplete=1\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"游戏\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=mep2bM&isComplete=1\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"科幻\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=zbq2dp&isComplete=1\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"轻小说\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=YerEdO&isComplete=1\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"❀❀连载❀❀\",\"url\": \"\",
\"style\": {\"layout_flexGrow\": 0,
\"layout_flexBasisPercent\": 1
}},
{\"title\": \"玄幻\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=lejRej&isComplete=0\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"武侠\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=nel5aK&isComplete=0\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"都市\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=mbk5ez&isComplete=0\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"仙侠\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=vbmOeY&isComplete=0\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"军事\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=penRe7&isComplete=0\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"历史\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=xbojag&isComplete=0\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"游戏\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=mep2bM&isComplete=0\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"科幻\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=zbq2dp&isComplete=0\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"轻小说\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=YerEdO&isComplete=0\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"❀❀❀女生频道❀❀❀\",\"url\": \"\",
\"style\": {\"layout_flexGrow\": 0,
\"layout_flexBasisPercent\": 1
}},
{\"title\": \"必读榜\",\"url\": \"http://api.jxgtzxc.com/module/rank?type=1&channel=2&page={{page}}\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"潜力榜\",\"url\": \"http://api.jxgtzxc.com/module/rank?type=5&channel=2&page={{page}}\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"完本榜\",\"url\": \"http://api.jxgtzxc.com/module/rank?type=2&channel=2&page={{page}}\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"更新榜\",\"url\": \"http://api.jxgtzxc.com/module/rank?type=3&channel=2&page={{page}}\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"搜索榜\",\"url\": \"http://api.jxgtzxc.com/module/rank?type=4&channel=2&page={{page}}\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"评论榜\",\"url\": \"http://api.jxgtzxc.com/module/rank?type=6&channel=2&page={{page}}\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"❀❀全部分类❀❀\",\"url\": \"\",
\"style\": {\"layout_flexGrow\": 0,
\"layout_flexBasisPercent\": 1
}},
{\"title\": \"现代言情\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=9avmeG\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"古代言情\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=DdwRb1\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"幻想言情\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=7ax9by\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"青春校园\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=Pdy7aQ\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"唯美纯爱\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=kazYeJ\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"同人衍生\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=9aAOdv\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"❀❀完结❀❀\",\"url\": \"\",
\"style\": {\"layout_flexGrow\": 0,
\"layout_flexBasisPercent\": 1
}},
{\"title\": \"现代言情\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=9avmeG&isComplete=1\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"古代言情\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=DdwRb1&isComplete=1\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"幻想言情\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=7ax9by&isComplete=1\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"青春校园\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=Pdy7aQ&isComplete=1\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"唯美纯爱\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=kazYeJ&isComplete=1\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"同人衍生\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=9aAOdv&isComplete=1\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"❀❀连载❀❀\",\"url\": \"\",
\"style\": {\"layout_flexGrow\": 0,
\"layout_flexBasisPercent\": 1
}},
{\"title\": \"现代言情\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=9avmeG&isComplete=0\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"古代言情\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=DdwRb1&isComplete=0\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"幻想言情\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=7ax9by&isComplete=0\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"青春校园\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=Pdy7aQ&isComplete=0\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"唯美纯爱\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=kazYeJ&isComplete=0\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}},
{\"title\": \"同人衍生\",\"url\": \"http://api.jxgtzxc.com/novel?sort=1&page={{page}}&categoryId=9aAOdv&isComplete=0\",
\"style\": {\"layout_flexGrow\": 1,
\"layout_flexBasisPercent\": 0.29
}}
]",
    "header": "{
\"User-Agent\": \"okhttp/4.9.2\",
\"client-device\": \"LND-AL40\",
\"client-version\": \"2.2.0\",
\"client-brand\": \"HONOR\",
\"client-source\": \"android\",
\"client-name\": \"app.maoyankanshu.novel\",
\"Authorization\": \"bearereyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwOlwvXC9hcGkuam1sbGRzYy5jb21cL2F1dGhcL3RoaXJkIiwiaWF0IjoxNjY1OTU4NzE0LCJleHAiOjE3NTkyNzA3MTQsIm5iZiI6MTY2NTk1ODcxNCwianRpIjoiTzdkNGZXZGo4b3JEZVBTbCIsInN1YiI6MjEwMjgsInBydiI6ImExY2IwMzcxODAyOTZjNmExOTM4ZWYzMGI0Mzc5NDY3MmRkMDE2YzUifQ.QIK10Tnkc25NqBE0XW7CgdHUZFFpEY1hS7s9yxJF378\"
}",
    "lastUpdateTime": 1669302155213,
    "respondTime": 3141,
    "ruleBookInfo": {
      "author": "$.authorName",
      "coverUrl": "$.cover",
      "init": "$.data",
      "intro": "<p>{{$.summary}}</p>",
      "kind": "{{$.averageScore}}分
{{$..className}}
连载中{{$.status}}已完结
{{$.lastChapter.decTime}}
##连载中2|1已完结",
      "lastChapter": "{{$.lastChapter.chapterName}} • {{$.lastChapter.decTime}}",
      "name": "$.novelName",
      "tocUrl": "{{baseUrl}}/chapters",
      "wordCount": "$.wordNum"
    },
    "ruleContent": {
      "content": "$.content##^##<p>",
      "replaceRegex": "##一秒记住.*供精彩阅读。|7017k"
    },
    "ruleExplore": {
      "author": "",
      "bookList": "",
      "bookUrl": "",
      "coverUrl": "",
      "intro": "",
      "kind": "",
      "name": "",
      "wordCount": ""
    },
    "ruleReview": {},
    "ruleSearch": {
      "author": "$.authorName",
      "bookList": "$.data",
      "bookUrl": "/novel/{{$.novelId}}",
      "checkKeyWord": "深空彼岸",
      "coverUrl": "$.cover",
      "intro": "$.summary",
      "kind": "{{$.averageScore}}分
{{$..className}}
连载中{{$.status}}已完结
{{$.createdAt##\s.*}}
##连载中2|1已完结|连载中已完结",
      "lastChapter": "",
      "name": "$.novelName",
      "wordCount": "$.wordNum"
    },
    "ruleToc": {
      "chapterList": "$.data.list",
      "chapterName": "$.chapterName",
      "chapterUrl": "$.path
@js:java.aesBase64DecodeToString(result,\"f041c49714d39908\",\"AES/CBC/PKCS5Padding\",\"0123456789abcdef\")",
      "updateTime": "发布于 {{$.updatedAt}}, 共 {{$.wordNum}}字."
    },
    "searchUrl": "http://api.jxgtzxc.com/search?keyword={{key}}&page={{page}}",
    "weight": 0
  },
  {
    "bookSourceComment": "",
    "bookSourceGroup": "校验可用",
    "bookSourceName": "久久小说[9191]",
    "bookSourceType": 0,
    "bookSourceUrl": "http://m.9191net.com",
    "customOrder": 655,
    "enabled": true,
    "enabledCookieJar": true,
    "enabledExplore": true,
    "exploreUrl": "言情::http://m.9191net.com/search/3/%E8%A8%80%E6%83%85/{{page}}.html
穿越::http://m.9191net.com/search/3/%E7%A9%BF%E8%B6%8A/{{page}}.html
重生::http://m.9191net.com/search/3/%E9%87%8D%E7%94%9F/{{page}}.html
总裁::http://m.9191net.com/search/3/%E6%80%BB%E8%A3%81/{{page}}.html
都市::http://m.9191net.com/m/cat/ds/{{page}}.html
青春::http://m.9191net.com/m/cat/qc/{{page}}.html
武侠::http://m.9191net.com/m/cat/wx/{{page}}.html
仙侠::http://m.9191net.com/m/cat/xx/{{page}}.html
玄幻::http://m.9191net.com/m/cat/xh/{{page}}.html
奇幻::http://m.9191net.com/m/cat/qh/{{page}}.html
穿越::http://m.9191net.com/m/cat/cy/{{page}}.html
历史::http://m.9191net.com/m/cat/ls/{{page}}.html
架空::http://m.9191net.com/m/cat/jk/{{page}}.html
网游::http://m.9191net.com/m/cat/yx/{{page}}.html
竞技::http://m.9191net.com/m/cat/jg.html
科幻::http://m.9191net.com/m/cat/kh/{{page}}.html
灵异::http://m.9191net.com/m/cat/ly.html
恐怖::http://m.9191net.com/m/cat/kb/{{page}}.html
散文::http://m.9191net.com/m/cat/sw.html
名著::http://m.9191net.com/m/cat/mz/{{page}}.html
传迹::http://m.9191net.com/m/cat/zj.html
同人::http://m.9191net.com/m/cat/tr/{{page}}.html
全部::http://m.9191net.com/m/cat/qj/{{page}}/action/shop/todo/content/do/-1vunionvselectv1f2f3fconcati280x7cfmd5i281122xf0x7cxf5f6f7f8f9f10f11f12f13f14f15f16f17.html
最新::http://m.9191net.com/m/cat/zx/{{page}}/cat/favicon.html",
    "lastUpdateTime": 1682691978897,
    "respondTime": 554,
    "ruleBookInfo": {
      "author": "tag.p@text##分类：.*
状态：.*
格式：.*
大小：.*
更新：.*
RAR/ZIP.*|苹果端用户下载方式：.*",
      "init": "",
      "intro": "class.intro_info.0@html",
      "kind": "tag.p!0@a@text",
      "name": "tag.h2@text"
    },
    "ruleContent": {
      "content": "class.downButton@title&&class.downButton@href"
    },
    "ruleExplore": {
      "bookList": ""
    },
    "ruleSearch": {
      "author": "author",
      "bookList": "class.block",
      "bookUrl": "tag.a@href",
      "coverUrl": "tag.a@img@src",
      "intro": "tag.p@a@html",
      "name": "tag.h2@text"
    },
    "ruleToc": {
      "chapterList": "class.ablum_read",
      "chapterName": "tag.a@text"
    },
    "searchUrl": "http://m.9191net.com/search.html?keywords={{key}}&submit=",
    "weight": 0
  },
  {
    "bookSourceComment": "kaka",
    "bookSourceGroup": "校验可用",
    "bookSourceName": "📃UC小说",
    "bookSourceType": 0,
    "bookSourceUrl": "http://xiaoshuo.uc.cn/",
    "customOrder": 893,
    "enabled": true,
    "enabledCookieJar": false,
    "enabledExplore": true,
    "exploreUrl": "<js>
var cat1='都市,玄幻,仙侠,灵异,历史,游戏,科幻,武侠,奇幻,竞技';var list=[];
function getUrl(cats,url1){cats.split(',').forEach((i)=>{list.push(i+'::'+url1+i)})};
list.push('男→::');
getUrl(cat1,'http://read.xiaoshuo1-sm.com/novel/i.php?do=is_caterank&p=17&page={{page}}&onlyCpBooks=1&status=2&firstCate=');
list.join('\n')
</js>",
    "lastUpdateTime": 1677667652167,
    "respondTime": 3393,
    "ruleBookInfo": {
      "init": "<js>
var bookId=java.get('bid');
var encryptKey=\"37e81a9d8f02596e1b895d07c171d5c9\",user_id=\"8000000\",timestamp=parseInt((new Date).getTime()/1e3);
var o=bookId+timestamp+user_id+encryptKey;
var sign=java.md5Encode(o);
var list={'turl':'https://ocean.shuqireader.com/api/bcspub/qswebapi/book/chapterlist?_=&bookId='+bookId+'&user_id=8000000&sign='+sign+'&timestamp='+timestamp};list
</js>",
      "tocUrl": "turl"
    },
    "ruleContent": {
      "content": "ChapterContent@js:
function p(e) {
    return e.split(\"\").map(function (e) {
        return e.match(/[A-Za-z]/) ? (c = Math.floor(e.charCodeAt(0) / 97), k = (e.toLowerCase().charCodeAt(0) - 83) % 26 || 26, String.fromCharCode(k + (0 == c ? 64 : 96))) : e
    }).join(\"\")
}
java.base64Decode(p(result))"
    },
    "ruleExplore": {
      "author": "author",
      "bookList": "$.data",
      "bookUrl": "$.bid<js>java.put('bid',result);'http://xiaoshuo.uc.cn/#!/ct/cover/bid/'+result</js>",
      "coverUrl": "cover",
      "intro": "desc",
      "kind": "{{$.category}},{{$.tags}},读者{{$.reads}},{{$.status}}<js>result.replace(/1$/,'完结').replace(/0$/,'连载')</js>",
      "lastChapter": "$.uptime<js>java.getString('$.last_chapter_name')+' '+java.timeFormat(result*1000)</js>",
      "name": "title",
      "wordCount": "words"
    },
    "ruleReview": {},
    "ruleSearch": {
      "author": "author",
      "bookList": "$.data",
      "bookUrl": "$.bid<js>java.put('bid',result);'http://xiaoshuo.uc.cn/#!/ct/cover/bid/'+result</js>",
      "coverUrl": "cover",
      "intro": "desc",
      "kind": "category&&tags",
      "name": "title",
      "wordCount": "words"
    },
    "ruleToc": {
      "chapterList": "$.data.chapterList[0].volumeList<js>java.put('freeUrlPre',java.getString('$.data.freeContUrlPrefix'));java.put('shortUrlPre',java.getString('$.data.shortContUrlPrefix'));result</js>",
      "chapterName": "chapterName",
      "chapterUrl": "<js>var l=java.getString('$.contUrlSuffix');if(l.indexOf('reqEncryptParam')==-1){java.get('freeUrlPre')+l}else{java.get('shortUrlPre')+java.getString('$.shortContUrlSuffix')}</js>",
      "isVip": "chapterPrice"
    },
    "searchUrl": "http://read.xiaoshuo1-sm.com/novel/i.php?do=is_serchpay&page=1&size=10&q={{key}}&filterMigu=1&p=17&shuqi_h5=&_=1619653492249",
    "weight": 0
  },
  {
    "bookSourceComment": "",
    "bookSourceGroup": "校验可用",
    "bookSourceName": "蚂蚁文学网",
    "bookSourceType": 0,
    "bookSourceUrl": "https://m.myxzm.com/",
    "customOrder": 516,
    "enabled": true,
    "enabledCookieJar": false,
    "enabledExplore": true,
    "exploreUrl": "  总榜 ::/top/&&都市榜::/top/dushi.html&&现情榜::/top/xianqing.html&&穿越榜::/top/chuanyue.html&&重生榜::/top/chongsheng.html&&玄幻榜::/top/xuanhuan.html&&奇幻榜::/top/qihuan.html&&仙侠榜::/top/xianxia.html&&武侠榜::/top/wuxia.html&&职场榜::/top/zhichang.html&&官场榜::/top/guanchang.html&&恐怖榜::/top/kongbu.html&&灵异榜::/top/lingyi.html&&悬疑榜::/top/xuanyi.html&&科幻榜::/top/kehuan.html&&耽美榜::/top/danmei.html&&历史榜::/top/lishi.html&&军事榜::/top/juinshi.html&&游戏榜::/top/youxi.html&&竞技榜::/top/jingji.html&&短篇榜::/top/duanpian.html&&古言榜::/top/guyan.html&&￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣::&&金融投资小说::/heji/jrtzxs.html&&最好看的富豪类小说::/heji/hkfhxs.html&&系统类小说::/heji/xitonxs.html&&赘婿小说::/heji/zhuixuxs.html&&星空小说::/heji/xingkxs.html&&相术小说::/heji/xiangshuxs.html&&特工小说::/heji/tegongxs.html&&男扮女装小说::/heji/yndfxs.html&&网王小说::/heji/wangwxs.html&&鸿蒙小说::/heji/hmxiaoshuo.html&&恋爱小说::/heji/lianaixs.html&&a小说::/heji/axiaoshuo.html&&炼丹小说::/heji/liandanxs.html&&神话小说::/heji/shenhuaxs.html&&囚禁小说::/heji/qiujinxs.html&&王妃小说::/heji/wangfeixs.html&&吸血鬼小说::/heji/xxgxs.html&&召唤小说::/heji/zhaophuanxs.html&&exo小说::/heji/exoxsh.html&&抗战小说::/heji/kangzhanxs.html&&军婚小说::/heji/junhunxs.html&&多肉小说::/heji/duorouxs.html&&修真小说::/heji/xiuzhen.html&&幽默搞笑小说::/heji/ymgxxs.html&&伦理禁忌小说::/heji/lljjxs.html&&报复小说::/heji/bfxs.html&&神医小说::/heji/syxs.html&&励志小说::/heji/lzxs.html&&女主爽文小说::/heji/nzswxs.html&&宅斗小说::/heji/zdxs.html&&纯爱小说::/heji/caxs.html&&女强男强小说::/heji/nqnqxs.html&&宠婚小说::/heji/hcxs.html&&浪漫小说::/heji/lmxs.html&&推理小说::/heji/tlxs.html&&英雄救美小说::/heji/yxjmxs.html&&探险小说::/heji/txxs.html&&监狱题材小说::/heji/jytcxs.html&&宝宝小说::/heji/bbxs.html&&洪荒小说::/heji/hhxs.html&&异世小说::/heji/ysxs.html&&宫廷小说::/heji/gtxs.html&&轮回重生小说::/heji/lxcsxs.html&&婚姻爱情小说::/heji/hyaqxs.html&&百合小说::/heji/bhxs.html&&娱乐圈小说::/heji/ylqxs.html&&搞笑小说::/heji/gxxs.html&&神仙妖精小说::/heji/sxyjxs.html&&冤家小说::/heji/yjxs.html&&种田小说::/heji/ztxs.html&&轻松爽文小说::/heji/qsswxs.html&&校园小说::/heji/xyxs.html&&未来小说::/heji/wlxs.html&&虐恋情深小说::/heji/llqsxs.html&&民国小说::/heji/mgxs.html&&科幻小说::/heji/khxs.html&&修仙小说::/heji/xxxs.html&&空间小说::/heji/kjxs.html&&女强小说::/heji/nqxs.html&&豪门世家小说::/heji/hmsjxs.html&&逆袭小说::/heji/nxxs.html&&宫斗小说::/heji/gdxs.html&&贵族小说::/heji/gzxs.html&&鬼怪小说::/heji/gkxs.html&&网游小说::/heji/wyxs.html&&架空历史小说::/heji/jklsxs.html&&电影小说::/heji/dyxs.html&&神怪小说::/heji/sgxs.html&&讽刺小说::/heji/fcxs.html&&冶艳小说::/heji/zyxs.html&&轻小说::/heji/qxs.html&&明星同人小说::/heji/mxtrxs.html",
    "lastUpdateTime": 1624186185673,
    "respondTime": 329,
    "ruleBookInfo": {
      "author": "class.info@tag.span.3@tag.a@text",
      "init": "",
      "intro": "class.intro@tag.p@text",
      "lastChapter": "",
      "name": "class.base clearfix@dd@h2@text",
      "tocUrl": ""
    },
    "ruleContent": {
      "content": "class.content@html##《.*》 第.*章 .*免费试读"
    },
    "ruleExplore": {},
    "ruleSearch": {
      "author": "class.info@span@text",
      "bookList": "class.clearfix@li",
      "bookUrl": "class.tit@href",
      "coverUrl": "class.pic lazy@img@src",
      "intro": "class.intro@text",
      "kind": "class.serial@text&&class.type@text",
      "name": "class.tit@text"
    },
    "ruleToc": {
      "chapterList": "class.attentions@class.clearfix@li",
      "chapterName": "tag.a@text",
      "chapterUrl": "tag.a@href"
    },
    "searchUrl": "https://m.myxzm.com/search/?q={{key}}&page={{page}}",
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
