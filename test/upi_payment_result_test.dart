import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_booking/network/UpiPaymentResult.dart';

void main() {
  test('wrong PIN and explicit failure never report payment submitted', () {
    for (final response in [
      'Status=FAILURE',
      'Status=FAILED&responseCode=Z9',
      'Status=SUCCESS&responseCode=91',
      'Status=CANCELLED'
    ]) {
      expect(UpiPaymentResult.fromNative({'response': response}).appStatus,
          'failure');
    }
  });
  test('success is submitted for verification, never credited by the device',
      () {
    final result = UpiPaymentResult.fromNative({
      'response': 'Status=SUCCESS&responseCode=00&ApprovalRefNo=123456789012'
    });
    expect(result.appStatus, 'submitted');
    expect(result.utr, '123456789012');
  });
  test('missing result and cancellation remain unverified', () {
    for (final response in [
      {},
      {'cancelled': true},
      {'response': 'Status=SUBMITTED'},
      {'response': 'Status=%ZZ'}
    ]) {
      expect(UpiPaymentResult.fromNative(response).appStatus, 'pending');
    }
  });
  test('explicit failure overrides contradictory callback fields', () {
    expect(
        UpiPaymentResult.fromNative({
          'response': 'STATUS=Failure&ApprovalRefNo=123',
          'cancelled': false
        }).appStatus,
        'failure');
  });
  test('Android cancellation code alone does not discard reported success', () {
    expect(
        UpiPaymentResult.fromNative(
            {'response': 'Status=SUCCESS', 'cancelled': true}).appStatus,
        'submitted');
  });
}
