/// A device response is a report only. It never proves that money was received.
class UpiPaymentResult {
  final String appStatus;
  final String? utr;

  const UpiPaymentResult(this.appStatus, this.utr);

  factory UpiPaymentResult.fromNative(Map<dynamic, dynamic> result) {
    final values = <String, String>{};
    for (final entry in '${result['response'] ?? ''}'.split('&')) {
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
    final code = values['responsecode'];
    final failed = ['failure', 'failed', 'fail', 'cancelled', 'canceled']
            .contains(status) ||
        (code != null && code.isNotEmpty && code != '00' && code != '0');
    if (failed) return const UpiPaymentResult('failure', null);
    // Some UPI apps return RESULT_CANCELED even after payment. Without an
    // explicit failure response, keep the transaction pending for verification.
    final utr = values['approvalrefno'] ?? values['txnref'];
    return UpiPaymentResult(status == 'success' ? 'submitted' : 'pending',
        utr?.isEmpty == true ? null : utr);
  }
}
