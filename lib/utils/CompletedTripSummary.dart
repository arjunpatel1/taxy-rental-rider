import '../model/CurrentRequestModel.dart';
import '../model/RideDetailModel.dart';

/// Keep route metadata, but use the server's completed bill for payment.
OnRideRequest completedTripSummary(OnRideRequest cached, RideDetailModel detail) {
  final finalTrip = detail.data;
  if (finalTrip == null || finalTrip.id != cached.id || finalTrip.status != 'completed' || !detail.hasValidFinalFare) {
    throw const FormatException('Completed trip details are unavailable');
  }
  num amount(dynamic value) {
    final result = num.tryParse('$value');
    if (result == null || !result.isFinite || result < 0) {
      throw const FormatException('Final trip figures are unavailable');
    }
    return result;
  }
  final data = cached.toJson();
  data['total_amount'] = amount(finalTrip.totalAmount);
  data['distance'] = amount(finalTrip.distance);
  data['gst_amount'] = amount(finalTrip.gstAmount ?? 0);
  data['extra_charges_amount'] = amount(finalTrip.extraChargesAmount ?? 0);
  data['distance_unit'] = finalTrip.distanceUnit ?? cached.distanceUnit;
  data['payment_status'] = detail.payment?.paymentStatus ?? finalTrip.paymentStatus ?? cached.paymentStatus;
  data['is_rider_rated'] = finalTrip.isRiderRated ?? cached.isRiderRated;
  return OnRideRequest.fromJson(data);
}
