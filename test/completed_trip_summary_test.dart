import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_booking/model/CurrentRequestModel.dart';
import 'package:taxi_booking/model/RideDetailModel.dart';
import 'package:taxi_booking/utils/CompletedTripSummary.dart';

void main() {
  final cached = OnRideRequest.fromJson({'id':189,'status':'completed',
    'total_amount':1000,'distance':0,'start_address':'Dewas pickup','payment_status':'pending'});
  test('payment uses the final odometer bill instead of booking figures', () {
    final detail = RideDetailModel.fromJson({'data':{'id':189,'status':'completed',
      'total_amount':1250,'distance':50,'gst_amount':50,'extra_charges_amount':200},
      'payment':{'payment_status':'paid'}});
    final summary = completedTripSummary(cached, detail);
    expect(summary.totalAmount,1250);
    expect(summary.distance,50);
    expect(summary.gstAmount,50);
    expect(summary.extraChargesAmount,200);
    expect(summary.paymentStatus,'paid');
    expect(summary.startAddress,'Dewas pickup');
    expect(cached.totalAmount,1000);
    expect(cached.distance,0);
  });
  test('a mismatched, unfinished or unreadable final bill cannot enable payment', () {
    for (final data in [
      {'id':190,'status':'completed','total_amount':1000,'distance':10},
      {'id':189,'status':'in_progress','total_amount':1000,'distance':10},
      {'id':189,'status':'completed','total_amount':null,'distance':10},
    ]) {
      expect(() => completedTripSummary(cached,RideDetailModel.fromJson({'data':data})),throwsFormatException);
    }
  });
}
