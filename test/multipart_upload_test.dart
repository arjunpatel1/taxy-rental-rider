import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taxi_booking/network/MultipartUpload.dart';

void main() {
  http.MultipartRequest request() => http.MultipartRequest('POST', Uri.parse('https://example.test/upload'));
  test('a pretty-printed response is decoded once after the entire body', () async {
    final result = await sendMultipartJson(request(), client: MockClient((_) async =>
      http.Response('{\n  "message": "Saved",\n  "reading": 100\n}', 200)));
    expect(result['reading'], 100);
    expect(result['message'], 'Saved');
  });
  test('server validation errors are failures rather than successful uploads', () async {
    await expectLater(sendMultipartJson(request(), client: MockClient((_) async =>
      http.Response('{"message":"Closing reading cannot be less than start"}', 422))),
      throwsA(predicate((e) => e.toString().contains('Closing reading'))));
  });
  test('empty and malformed server bodies allow a visible retry', () async {
    for (final body in ['', '<html>Server Error</html>', 'null']) {
      await expectLater(sendMultipartJson(request(), client: MockClient((_) async => http.Response(body, 200))), throwsException);
    }
  });
  test('an interrupted upload times out instead of leaving a permanent spinner', () async {
    await expectLater(sendMultipartJson(request(), timeout: Duration(milliseconds: 5),
      client: MockClient((_) => Completer<http.Response>().future)),
      throwsA(predicate((e) => e.toString().contains('timed out'))));
  });
}
