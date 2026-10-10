/// Classifies the UPI app callback. Missing results stay pending; explicit
/// failures override success. A callback is a report for server verification.
class UpiPaymentResult {
  final String appStatus;
  final String? utr;

  const UpiPaymentResult(this.appStatus, this.utr);

  factory UpiPaymentResult.fromNative(Map<dynamic, dynamic> result) {
    var raw = '${result['response'] ?? ''}'.trim();

    // Some apps hand back the whole callback URI rather than just the query,
    // which used to leave the first field parsed as "upi://pay?txnid".
    final queryStart = raw.indexOf('?');
    if (queryStart >= 0 && raw.contains('://')) {
      raw = raw.substring(queryStart + 1);
    }

    final values = <String, String>{};
    for (final entry in raw.split('&')) {
      final separator = entry.indexOf('=');
      if (separator < 0) continue;
      try {
        values[Uri.decodeQueryComponent(entry.substring(0, separator))
                .trim()
                .toLowerCase()] =
            Uri.decodeQueryComponent(entry.substring(separator + 1)).trim();
      } on FormatException {
        return const UpiPaymentResult('pending', null);
      } on ArgumentError {
        return const UpiPaymentResult('pending', null);
      }
    }

    final status = (values['status'] ?? '').toLowerCase();
    final utr = values['approvalrefno'] ?? values['txnref'] ?? values['txnid'];
    final reference = (utr == null || utr.isEmpty) ? null : utr;

    // A non-success response code overrides a contradictory SUCCESS field.
    final code = (values['responsecode'] ?? '').trim();
    final failed = ['failure', 'failed', 'cancelled', 'canceled'].contains(status)
        || (code.isNotEmpty && code != '00');
    return UpiPaymentResult(failed ? 'failure' : status == 'success' ? 'submitted' : 'pending', reference);
  }
}
