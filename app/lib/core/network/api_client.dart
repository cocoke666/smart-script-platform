import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'json_reader.dart';

/// 统一网络客户端。
///
/// 职责：
///   1. 自动附加 `Authorization: Bearer {accessToken}`；
///   2. Access Token 失效（401）时自动刷新，并把**原请求重试一次**；
///   3. 并发 401 只发起一次刷新（共享 Future 锁），避免刷新风暴；
///   4. Refresh Token 同样失效时清空本地凭证并通知上层回到登录页；
///   5. 把异常统一转换为 [ApiException]，网络异常绝不导致崩溃。
class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    String? baseUrl,
    Dio? dio,
    Dio? refreshDio,
  })  : _tokenStorage = tokenStorage,
        _baseUrl = baseUrl ?? AppConfig.baseUrl,
        _dio = dio ?? Dio() {
    _configure(_dio);
    // 刷新请求使用独立实例，避免再次进入拦截器造成递归刷新
    _refreshDio = refreshDio ?? Dio();
    _configure(_refreshDio);
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  /// 标记：本次请求是否需要携带 Token。
  static const String _authenticatedKey = 'authenticated';

  /// 标记：本次请求是否已经因 401 重试过（保证最多重试一次）。
  static const String _retriedKey = 'retried';

  final TokenStorage _tokenStorage;
  final String _baseUrl;
  final Dio _dio;
  late final Dio _refreshDio;

  /// 登录态彻底失效时的回调（由 AuthState 注册，用于清空状态并回到登录页）。
  ///
  /// 采用可变字段而非构造参数，避免 ApiClient 与 AuthState 之间的循环依赖。
  void Function()? onSessionExpired;

  /// 刷新中的共享 Future：并发请求只会触发一次刷新。
  Future<bool>? _refreshing;

  Dio get rawDio => _dio;

  void _configure(Dio dio) {
    dio.options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    );
  }

  Future<void> _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final needAuth = options.extra[_authenticatedKey] != false;
    if (needAuth) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  Future<void> _onError(DioException error, ErrorInterceptorHandler handler) async {
    final options = error.requestOptions;
    final status = error.response?.statusCode;
    final needAuth = options.extra[_authenticatedKey] != false;
    final alreadyRetried = options.extra[_retriedKey] == true;
    final isRefreshRequest = options.path.contains('/token/refresh');

    if (status == 401 && needAuth && !alreadyRetried && !isRefreshRequest) {
      final refreshed = await _refreshSession();
      if (refreshed) {
        try {
          final token = await _tokenStorage.getAccessToken();
          final retryOptions = options
            ..headers['Authorization'] = 'Bearer $token'
            ..extra[_retriedKey] = true;
          final response = await _dio.fetch<dynamic>(retryOptions);
          return handler.resolve(response);
        } on DioException catch (retryError) {
          return handler.next(retryError);
        }
      }
      // 刷新失败：本地凭证已清空，通知上层回到登录页
      onSessionExpired?.call();
    }
    handler.next(error);
  }

  /// 刷新登录态；并发调用共享同一个 Future，保证只刷新一次。
  Future<bool> _refreshSession() {
    final pending = _refreshing;
    if (pending != null) {
      return pending;
    }
    final future = _doRefresh();
    _refreshing = future;
    return future.whenComplete(() {
      _refreshing = null;
    });
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }
    try {
      final response = await _refreshDio.post<dynamic>(
        '${AppConfig.apiPrefix}/token/refresh',
        data: {
          'refreshToken': refreshToken,
          'deviceId': await _tokenStorage.getOrCreateDeviceId(),
        },
        options: Options(extra: {_authenticatedKey: false}),
      );
      final data = _unwrap(response);
      final accessToken = readString(data['accessToken']);
      final nextRefreshToken = readString(data['refreshToken']);
      if (accessToken.isEmpty || nextRefreshToken.isEmpty) {
        await _tokenStorage.clear();
        return false;
      }
      await _tokenStorage.saveAccessToken(accessToken);
      await _tokenStorage.saveRefreshToken(nextRefreshToken);
      return true;
    } on DioException catch (e) {
      // 401 等 HTTP 错误会以 DioException 抛出，必须先映射成业务异常，
      // 否则「Refresh Token 已失效」会被误判为普通失败，凭证不会被清空。
      return _handleRefreshFailure(_toApiException(e));
    } on ApiException catch (e) {
      return _handleRefreshFailure(e);
    } catch (_) {
      // 未知异常（如响应格式异常）：保留凭证，交由后续请求重试
      return false;
    }
  }

  /// 刷新失败处理：只有确认凭证失效才清空本地登录态。
  Future<bool> _handleRefreshFailure(ApiException error) async {
    if (error.isSessionExpired) {
      await _tokenStorage.clear();
    }
    return false;
  }

  /// POST 请求，返回统一响应体中的 `data`。
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: body,
        options: Options(extra: {_authenticatedKey: authenticated}),
      );
      return _unwrap(response);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  /// GET 请求，返回统一响应体中的 `data`。
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    bool authenticated = true,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: query,
        options: Options(extra: {_authenticatedKey: authenticated}),
      );
      return _unwrap(response);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  /// 解析 `{code, message, data}`；code != 0 时抛业务异常。
  Map<String, dynamic> _unwrap(Response<dynamic> response) {
    final payload = response.data;
    if (payload is! Map<String, dynamic>) {
      throw const ApiException(ApiErrorCode.parseError, '服务返回数据格式异常，请稍后重试');
    }
    final code = payload['code'];
    if (code is! int) {
      throw const ApiException(ApiErrorCode.parseError, '服务返回数据格式异常，请稍后重试');
    }
    if (code != ApiErrorCode.success) {
      final message = payload['message'];
      throw ApiException(
        code,
        message is String && message.isNotEmpty ? message : '请求失败，请稍后重试',
      );
    }
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : const <String, dynamic>{};
  }

  /// 把 Dio 异常转换为统一业务异常，保证客户端只看到安全文案。
  ApiException _toApiException(DioException error) {
    final response = error.response;
    if (response != null) {
      final payload = response.data;
      if (payload is Map<String, dynamic> && payload['code'] is int) {
        final message = payload['message'];
        return ApiException(
          payload['code'] as int,
          message is String && message.isNotEmpty ? message : '请求失败，请稍后重试',
        );
      }
      return ApiException(ApiErrorCode.systemError, '服务异常（${response.statusCode}），请稍后重试');
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(ApiErrorCode.networkTimeout, '网络连接超时，请稍后重试');
      case DioExceptionType.cancel:
        return const ApiException(ApiErrorCode.networkError, '请求已取消');
      default:
        return const ApiException(ApiErrorCode.networkError, '网络异常，请检查网络后重试');
    }
  }
}
