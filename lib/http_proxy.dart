import 'dart:convert';
import 'package:http/http.dart' as original_http;
import 'package:flutter/foundation.dart' show kIsWeb;

export 'package:http/http.dart' hide get, post, Request, Client;
Uri _proxyUri(Uri uri) {
  if (kIsWeb) {
    if (!uri.toString().contains('corsproxy.io')) {
      return Uri.parse('https://corsproxy.io/?' + Uri.encodeComponent(uri.toString()));
    }
  }
  return uri;
}

Future<original_http.Response> get(Uri url, {Map<String, String>? headers}) {
  return original_http.get(_proxyUri(url), headers: headers);
}

Future<original_http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) {
  return original_http.post(_proxyUri(url), headers: headers, body: body, encoding: encoding);
}

class Request extends original_http.Request {
  Request(String method, Uri url) : super(method, _proxyUri(url));
}

class Client extends original_http.BaseClient {
  final original_http.Client _inner = original_http.Client();
  
  @override
  Future<original_http.StreamedResponse> send(original_http.BaseRequest request) {
    // If someone created a Request without our custom Request class, we ideally recreate it,
    // but in this codebase, Request is only used with our wrapper.
    return _inner.send(request);
  }
}


