/// A device response is a report only. It never proves that money was received,
/// and in practice it is often wrong: Google Pay has reported a paid
/// transaction as failed, and PhonePe frequently returns nothing at all for one
/// that succeeded. So this never concludes "failed" - the worst outcome is
/// telling a rider who paid that their payment failed. Anything short of an
/// explicit success is left pending for verification.
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

    // Only an explicit success is reported as such; everything else, including
    // an empty response or one the app calls a failure, is left for checking.
    return UpiPaymentResult(status == 'success' ? 'submitted' : 'pending', reference);
  }
}
