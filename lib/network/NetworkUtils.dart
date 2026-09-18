import '../manage_imports.dart';
import 'package:http/http.dart' as http;

Map<String, String> buildHeaderTokens() {
  Map<String, String> header = {
    HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
    HttpHeaders.cacheControlHeader: 'no-cache',
    HttpHeaders.acceptHeader: 'application/json; charset=utf-8',
    'Access-Control-Allow-Headers': '*',
    'Access-Control-Allow-Origin': '*',
  };
  if (appStore.isLoggedIn) {
    header.putIfAbsent(HttpHeaders.authorizationHeader, () => 'Bearer ${sharedPref.getString(TOKEN)}');
  }
// print('NETWORK_LOG--> Header:${header.toString()}');
  return header;
}

Uri buildBaseUrl(String endPoint) {
  Uri url = Uri.parse(endPoint);
  if (!endPoint.startsWith('http')) url = Uri.parse('$mBaseUrl$endPoint');

  // log('URL: ${url.toString()}');

  return url;
}

Future<Response> buildHttpResponse(String endPoint, {HttpMethod method = HttpMethod.GET, Map? request, Map<String, String>? header_extra}) async {
  if (await isNetworkAvailable()) {
    var headers = buildHeaderTokens();
    Uri url = buildBaseUrl(endPoint);
    try {
      Response response;
      if (method == HttpMethod.POST) {
        response = await http.post(url, body: jsonEncode(request), headers: header_extra != null ? header_extra : headers).timeout(Duration(seconds: 20), onTimeout: () => throw 'Timeout');
      } else if (method == HttpMethod.DELETE) {
        response = await delete(url, headers: headers).timeout(Duration(seconds: 20), onTimeout: () => throw 'Timeout');
      } else if (method == HttpMethod.PUT) {
        response = await put(url, body: jsonEncode(request), headers: headers).timeout(Duration(seconds: 20), onTimeout: () => throw 'Timeout');
      } else {
        response = await get(url, headers: header_extra != null ? header_extra : headers).timeout(Duration(seconds: 20), onTimeout: () => throw 'Timeout');
      }
      apiURLResponseLog(
        url: url.toString(),
        endPoint: endPoint,
        headers: header_extra != null ? jsonEncode(header_extra) : jsonEncode(headers),
        hasRequest: method == HttpMethod.POST || method == HttpMethod.PUT,
        request: jsonEncode(request),
        statusCode: response.statusCode,
        responseBody: response.body,
        methodType: method.name,
      );
      return response;
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError("API_ERROR->${url.toString()}::" + e.toString(), s, fatal: true);
      throw 'Something Went Wrong';
    }
  } else {
    throw 'Your internet is not working';
  }
}

JsonDecoder decoder = JsonDecoder();
JsonEncoder encoder = JsonEncoder.withIndent('  ');

void prettyPrintJson(String input) {
  var object = decoder.convert(input);
  var prettyString = encoder.convert(object);
  prettyString.split('\n').forEach((element) => log(element));
}

void apiURLResponseLog({String url = "", String endPoint = "", String headers = "", String request = "", int statusCode = 0, dynamic responseBody = "", String methodType = "", bool hasRequest = false}) {
  // if (kReleaseMode) return;
  log("\u001B[39m \u001b[96m┌───────────────────────────────────────────────────────────────────────────────────────────────────────┐\u001B[39m");
  log("\u001B[0   m");
  log("\u001B[39m \u001b[96m Time: ${DateTime.now()}\u001B[39m");
  log("\u001b[31m Url: \u001B[39m $url");
  log("\u001b[31m Header: \u001B[39m \u001b[96m$headers\u001B[39m");
  if (request.isNotEmpty) log("\u001b[31m Request: \u001B[39m \u001b[96m$request\u001B[39m");
  log("${statusCode == 200 ? "\u001b[32m" : "\u001b[31m"}");
  log('Response ($methodType) $statusCode ${statusCode == 200 ? "\u001b[32m" : "\u001b[31m"} ');
  prettyPrintJson(responseBody);
  log("\u001B[0   m");
  log("\u001B[39m \u001b[96m└───────────────────────────────────────────────────────────────────────────────────────────────────────┘\u001B[39m");
}

//region Common
Future handleResponse(Response response, [bool? avoidTokenError]) async {
  if (!await isNetworkAvailable()) {
    throw 'Your internet is not working';
  }
  if (response.statusCode == 401) {
    logOutSuccess();
    // if (appStore.isLoggedIn) {
    //   Map req = {
    //     'email': sharedPref.getString(USER_EMAIL),
    //     'password': sharedPref.getString(USER_PASSWORD),
    //   };
    //
    //   await logInApi(req).then((value) {
    //     throw 'Please try again.';
    //   }).catchError((e) {
    //     throw TokenException(e);
    //   });
    // } else {
    //   throw '';
    // }
  }

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }

  throw _readableError(response);
}

/// Turns an error response into a message a rider can act on, instead of "Something went wrong".
String _readableError(Response response) {
  String? serverMessage;
  try {
    final body = jsonDecode(response.body);
    if (body is Map) {
      if (body['message'] is String && body['message'].toString().trim().isNotEmpty) {
        serverMessage = parseHtmlString(body['message']);
      }
      // validation errors: {"errors": {"field": ["msg"]}} or {"all_message": {...}}
      final errors = body['errors'] ?? body['all_message'];
      if ((serverMessage == null || serverMessage.isEmpty) && errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        serverMessage = first is List && first.isNotEmpty ? first.first.toString() : first.toString();
      }
    }
  } catch (_) {
    // body was not JSON (html error page, gateway error, ...)
  }

  if (serverMessage != null && serverMessage.trim().isNotEmpty) return serverMessage.trim();

  switch (response.statusCode) {
    case 400:
    case 422:
      return 'Please check the details and try again.';
    case 403:
      return 'You do not have permission for this action.';
    case 404:
      return 'This is not available anymore.';
    case 408:
      return 'The request took too long. Please try again.';
    case 429:
      return 'Too many attempts. Please wait a minute and try again.';
    case 500:
    case 502:
    case 503:
    case 504:
      FirebaseCrashlytics.instance.recordError('server_error_${response.statusCode}: ${response.request?.url}', StackTrace.current);
      return 'Our server is busy right now. Please try again in a moment.';
    default:
      FirebaseCrashlytics.instance.recordError('http_${response.statusCode}: ${response.request?.url}', StackTrace.current);
      return 'Something went wrong. Please try again.';
  }
}

enum HttpMethod { GET, POST, DELETE, PUT }

class TokenException implements Exception {
  final String message;

  const TokenException([this.message = ""]);

  String toString() => "FormatException: $message";
}
