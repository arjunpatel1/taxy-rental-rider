import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_booking/model/EstimatePriceModel.dart';
import 'package:taxi_booking/utils/BookingFare.dart';
import 'package:taxi_booking/utils/VehicleAvailability.dart';

void main() {
  test('zero-driver outstation can be booked while local and rental show unavailable', () {
    for (final type in ['outstation_oneway', 'outstation_round', 'OUTSTATION_ONEWAY']) {
      expect(vehicleUnavailable(tripType: type, drivers: 0), isFalse);
      expect(vehicleUnavailable(tripType: type, drivers: null), isFalse);
    }
    for (final type in [null, 'Regular', 'local', 'rental']) {
      expect(vehicleUnavailable(tripType: type, drivers: 0), isTrue);
      expect(vehicleUnavailable(tripType: type, drivers: 1), isFalse);
    }
  });
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
