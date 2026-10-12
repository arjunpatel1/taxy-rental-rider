import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_booking/model/EstimatePriceModel.dart';
import 'package:taxi_booking/utils/BookingFare.dart';

void main() {
  test('Dewas live vehicle snapshot keeps categories and fare when no drivers are online', () {
    final json = jsonDecode(File('test/fixtures/dewas_vehicle_estimate.json').readAsStringSync());
    final result = EstimatePriceModel.fromJson(Map<String, dynamic>.from(json));
    final vehicles = result.data!.where((v) => v.totalAmount != null).toList();
    expect(vehicles.map((v) => v.name).toSet(), {'Auto', 'Bike', 'Mini', 'Sedan', 'SUV'});
    expect(vehicles.every((v) => v.driversAvailable == 0), isTrue);
    for (final vehicle in vehicles) {
      expect(BookingFare(total: vehicle.totalAmount!, discountedTotal: vehicle.totalAmountAfterDiscount).amount, greaterThan(0));
      expect(vehicle.serviceImage, startsWith('https://'));
    }
  });
}
