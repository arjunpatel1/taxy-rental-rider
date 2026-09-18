import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_booking/model/EstimatePriceModel.dart';
import 'package:taxi_booking/utils/BookingFare.dart';
import 'package:taxi_booking/utils/Extensions/dataTypeExtensions.dart';

void main() {
  test('typed vehicle fields support extensions used by booking cards', () {
    final service = ServicesListData.fromJson({'id': 1, 'name': 'Auto', 'total_amount': 68.12});
    expect(service.name.validate(), 'Auto');
    expect(service.serviceImage.validate(), '');
    // Reproduce the previous runtime crash in the dynamic card argument.
    final dynamic previousCardArgument = service;
    expect(() => previousCardArgument.name.validate(), throwsNoSuchMethodError);
  });
  test('estimate without optional discount displays original fare', () {
    final service = ServicesListData.fromJson({'id': 1, 'total_amount': 462});
    final fare = BookingFare(
        total: service.totalAmount!,
        discountedTotal: service.totalAmountAfterDiscount);
    expect(fare.amount.toStringAsFixed(2), '462.00');
    expect(fare.hasDiscount, false);
  });
  test('lower discount including a fully discounted ride is displayed', () {
    expect(const BookingFare(total: 462, discountedTotal: 400).amount, 400);
    expect(const BookingFare(total: 462, discountedTotal: 0).amount, 0);
  });
  test('invalid discount cannot replace original fare', () {
    for (final discount in [-1, 462, 500]) {
      final fare = BookingFare(total: 462, discountedTotal: discount);
      expect(fare.amount, 462);
      expect(fare.hasDiscount, false);
    }
  });
}
