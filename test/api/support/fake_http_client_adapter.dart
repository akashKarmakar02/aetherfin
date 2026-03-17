import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef FakeResponseHandler = FutureOr<ResponseBody> Function(
  RequestOptions options,
);

class FakeHttpClientAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];
  final List<_FakeRoute> _routes = <_FakeRoute>[];

  void onRequest(
    bool Function(RequestOptions options) matches,
    FakeResponseHandler handler,
  ) {
    _routes.add(_FakeRoute(matches: matches, handler: handler));
  }

  void onGet(String path, FakeResponseHandler handler) {
    onRequest(
      (options) => options.method == 'GET' && options.path == path,
      handler,
    );
  }

  void onPost(String path, FakeResponseHandler handler) {
    onRequest(
      (options) => options.method == 'POST' && options.path == path,
      handler,
    );
  }

  void onPatch(String path, FakeResponseHandler handler) {
    onRequest(
      (options) => options.method == 'PATCH' && options.path == path,
      handler,
    );
  }

  void onDelete(String path, FakeResponseHandler handler) {
    onRequest(
      (options) => options.method == 'DELETE' && options.path == path,
      handler,
    );
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    for (final route in _routes) {
      if (route.matches(options)) {
        return route.handler(options);
      }
    }
    throw StateError('No fake route for ${options.method} ${options.uri}');
  }

  @override
  void close({bool force = false}) {}
}

class _FakeRoute {
  _FakeRoute({
    required this.matches,
    required this.handler,
  });

  final bool Function(RequestOptions options) matches;
  final FakeResponseHandler handler;
}

ResponseBody jsonResponse(
  Object? body, {
  int statusCode = 200,
  Map<String, List<String>> headers = const <String, List<String>>{
    Headers.contentTypeHeader: <String>[Headers.jsonContentType],
  },
}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: headers,
  );
}

ResponseBody textResponse(
  String body, {
  int statusCode = 200,
  Map<String, List<String>> headers = const <String, List<String>>{
    Headers.contentTypeHeader: <String>[Headers.textPlainContentType],
  },
}) {
  return ResponseBody.fromString(body, statusCode, headers: headers);
}

