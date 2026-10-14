import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Consume one complete JSON response and close the upload connection on failure.
Future<dynamic> sendMultipartJson(http.MultipartRequest request,
    {http.Client? client, Duration timeout = const Duration(seconds: 45)}) async {
  final connection = client ?? http.Client();
  try {
    final response = await connection.send(request).timeout(timeout);
    final body = await response.stream.bytesToString().timeout(timeout);
    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw Exception('The server returned an invalid response. Please retry.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['message'] : null;
      throw Exception(message ?? 'Upload failed (${response.statusCode}). Please retry.');
    }
    if (decoded == null) throw Exception('The server returned an empty response. Please retry.');
    return decoded;
  } on TimeoutException {
    throw Exception('Upload timed out. Check your connection and retry.');
  } finally {
    connection.close();
  }
}
