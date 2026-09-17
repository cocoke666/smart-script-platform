import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// 一次被记录下来的请求。
class FakeRequestRecord {
  FakeRequestRecord({
    required this.path,
    required this.method,
    required this.authorization,
    required this.body,
  });

  final String path;
  final String method;
  final String? authorization;
  final String? body;
}

/// 预设响应。
class FakeResponse {
  FakeResponse(this.statusCode, this.body);

  /// 统一成功响应。
  factory FakeResponse.ok(Map<String, dynamic> data) {
    return FakeResponse(
      200,
      jsonEncode({'code': 0, 'message': 'success', 'data': data}),
    );
  }

  /// 统一失败响应（HTTP 状态 + 业务错误码）。
  factory FakeResponse.failure(int statusCode, int code, String message) {
    return FakeResponse(
      statusCode,
      jsonEncode({'code': code, 'message': message, 'data': null}),
    );
  }

  final int statusCode;
  final String body;
}

/// 假 HTTP 适配器：记录请求并按处理器返回预设响应。
///
/// 用它可以在不联网的前提下验证真实 [ApiClient] 的拦截器行为
/// （Token 注入、401 自动刷新、并发刷新加锁）。
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.handler);

  final Future<FakeResponse> Function(RequestOptions options, String? body) handler;

  final List<FakeRequestRecord> requests = [];

  /// 刷新接口被调用的次数。
  int refreshCount = 0;

  int countOf(String pathFragment) =>
      requests.where((request) => request.path.contains(pathFragment)).length;

  String? lastBodyOf(String pathFragment) {
    for (final request in requests.reversed) {
      if (request.path.contains(pathFragment)) {
        return request.body;
      }
    }
    return null;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    String? body;
    if (requestStream != null) {
      final chunks = await requestStream.toList();
      if (chunks.isNotEmpty) {
        body = utf8.decode(chunks.expand((chunk) => chunk).toList());
      }
    }
    final authorization = options.headers['Authorization']?.toString();
    requests.add(FakeRequestRecord(
      path: options.path,
      method: options.method,
      authorization: authorization,
      body: body,
    ));
    if (options.path.contains('/token/refresh')) {
      refreshCount += 1;
    }
    final response = await handler(options, body);
    return ResponseBody.fromString(
      response.body,
      response.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// 构造一个可直接使用的成功登录响应体。
Map<String, dynamic> loginData({
  String accessToken = 'access-1',
  String refreshToken = 'refresh-1',
  bool isNewUser = false,
  String phone = '138****8000',
  bool hasPassword = false,
}) {
  return {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'tokenType': 'Bearer',
    'expiresIn': 7200,
    'isNewUser': isNewUser,
    'user': {
      'id': 10001,
      'phone': phone,
      'nickname': '用户_123456',
      'avatar': null,
      'hasPassword': hasPassword,
    },
  };
}

/// 携带假适配器的 Dio 实例。
Dio dioWith(FakeHttpAdapter adapter) => Dio()..httpClientAdapter = adapter;
