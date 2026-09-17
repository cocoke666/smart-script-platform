/// JSON 安全读取工具。
///
/// 服务端字段缺失、类型不符或为 null 时返回兜底值，
/// 保证模型解析永远不会因为空值抛异常导致 App 崩溃。
library;

/// 读取整数，缺失或类型不符时返回 [fallback]。
int readInt(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

/// 读取字符串，缺失或类型不符时返回 [fallback]。
String readString(dynamic value, {String fallback = ''}) {
  if (value is String) {
    return value;
  }
  if (value == null) {
    return fallback;
  }
  return value.toString();
}

/// 读取可空字符串：空串与 null 统一返回 null，便于 UI 判断占位。
String? readNullableString(dynamic value) {
  final text = readString(value);
  return text.isEmpty ? null : text;
}

/// 读取布尔值，缺失或类型不符时返回 [fallback]。
bool readBool(dynamic value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    return value.toLowerCase() == 'true';
  }
  return fallback;
}

/// 读取对象数组，非数组时返回空列表。
List<Map<String, dynamic>> readMapList(dynamic value) {
  if (value is List) {
    return value.whereType<Map<String, dynamic>>().toList();
  }
  return const <Map<String, dynamic>>[];
}
