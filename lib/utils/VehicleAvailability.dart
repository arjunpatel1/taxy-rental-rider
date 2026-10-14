/// Office-booked outstation journeys do not require an online nearby driver.
bool vehicleUnavailable({required String? tripType, required num? drivers}) {
  final type = (tripType ?? '').toLowerCase();
  if (type == 'outstation_oneway' || type == 'outstation_round') return false;
  return (drivers ?? 0) <= 0;
}
