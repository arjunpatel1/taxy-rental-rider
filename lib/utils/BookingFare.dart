/// Chooses a display fare when an estimate omits optional discount fields.
class BookingFare {
  final num total;
  final num? discountedTotal;

  const BookingFare({required this.total, this.discountedTotal});

  bool get hasDiscount =>
      discountedTotal != null &&
      discountedTotal! >= 0 &&
      discountedTotal! < total;
  num get amount => hasDiscount ? discountedTotal! : total;
}
