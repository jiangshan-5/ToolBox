// A safe native placeholder stub for dart:js context on platforms that do not support it.

class JsContextStub {
  const JsContextStub();

  bool hasProperty(String property) => false;
  dynamic operator [](dynamic key) => null;
  dynamic callMethod(String method, [List? args]) => null;
}

const context = JsContextStub();

class JsObject {
  const JsObject();

  static dynamic jsify(dynamic object) => null;
  
  dynamic operator [](dynamic key) => null;
  void operator []=(dynamic key, dynamic value) {}
  dynamic callMethod(String method, [List? args]) => null;
}
