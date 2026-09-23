import 'package:flutter/material.dart';

import '../utils/BrandTheme.dart';
import '../utils/Common.dart';
import '../utils/Extensions/app_common.dart';

/// Itemised final bill (trip_fare_data) shown on completed ride screens.
class FareBreakdownCard extends StatelessWidget {
  final Map<String, dynamic> bill;
  final num total;
  final String distanceUnit;

  const FareBreakdownCard(
      {super.key,
      required this.bill,
      required this.total,
      this.distanceUnit = 'km'});

  static bool isFinal(Map<String, dynamic>? bill) =>
      bill != null && bill['is_final'] == true;

  num _n(dynamic v) => v is num ? v : num.tryParse('$v') ?? 0;

  @override
  Widget build(BuildContext context) {
    final km = _n(bill['km']);
    final rows = <List<dynamic>>[];
    final additional = _n(bill['additional_charges']);
    final gst = _n(bill['gst_amount']);
    final discount = _n(bill['discount']);
    final tripFare = _n(bill['trip_fare']) > 0
        ? _n(bill['trip_fare'])
        : total - additional - gst + discount;
    rows.add(['Trip Fare', '', tripFare]);
    if (additional > 0) rows.add(['Additional Trip Charges', '', additional]);
    if (discount > 0) rows.add(['Discount', '', -discount]);
    rows.add(['Tax', '', gst]);

    final fromOdometer = bill['km_source'] == 'odometer';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: BrandTokens.fill, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _chip(Icons.route_rounded,
                  '${km.toStringAsFixed(1)} $distanceUnit'),
              SizedBox(width: 8),
              if (bill['minutes'] != null)
                _chip(Icons.schedule_rounded,
                    '${_n(bill['minutes']).toInt()} min'),
              Spacer(),
              if (fromOdometer)
                Text(
                    'Odometer ${bill['start_odometer']} → ${bill['end_odometer']}',
                    style: secondaryTextStyle(size: 11)),
            ],
          ),
          SizedBox(height: 12),
          ...rows.map((r) => Padding(
                padding: EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Text(r[0].toString(), style: primaryTextStyle(size: 14)),
                    if ((r[1] as String).isNotEmpty) ...[
                      SizedBox(width: 6),
                      Expanded(
                          child: Text(r[1],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: secondaryTextStyle(size: 12))),
                    ] else
                      Spacer(),
                    printAmountWidget(
                        amount: (r[2] as num).toStringAsFixed(2),
                        size: 14,
                        weight: FontWeight.w500,
                        color: (r[2] as num) < 0 ? BrandTokens.success : null),
                  ],
                ),
              )),
          Divider(height: 18),
          Row(
            children: [
              Expanded(
                  child: Text('Total fare', style: boldTextStyle(size: 16))),
              printAmountWidget(
                  amount: total.toStringAsFixed(2),
                  size: 18,
                  weight: FontWeight.w700,
                  color: BrandTokens.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) => Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: BrandTokens.blue),
          SizedBox(width: 4),
          Text(text, style: boldTextStyle(size: 12)),
        ]),
      );
}

/// Estimate before the trip is billed: Trip Fare, Tax and Total Fare only.
/// The final bill adds Additional Trip Charges once the odometer is closed.
class EstimateFareCard extends StatelessWidget {
  final num total;
  final num gst;
  // Distance travelled, shown next to the trip fare as "Trip Fare 17km".
  final num? distance;
  final String? distanceUnit;
  // Waiting time, tolls and anything the driver added after the trip.
  final num extraCharges;

  const EstimateFareCard({
    super.key,
    required this.total,
    required this.gst,
    this.distance,
    this.distanceUnit,
    this.extraCharges = 0,
  });

  @override
  Widget build(BuildContext context) {
    final tax = gst < 0 ? 0 : gst;
    final extra = extraCharges < 0 ? 0 : extraCharges;
    // The trip fare is everything the rider is charged for the ride itself:
    // base fare, distance and time, with tax and any extras shown separately.
    final tripFare = total - tax - extra < 0 ? 0 : total - tax - extra;
    final km = distance == null || distance! <= 0
        ? ''
        : ' ${distance!.toStringAsFixed(distance! % 1 == 0 ? 0 : 1)}${distanceUnit ?? 'km'}';
    Widget row(String label, num amount, {bool bold = false}) => Padding(
          padding: EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Expanded(
                  child: Text(label,
                      style: bold
                          ? boldTextStyle(size: 16)
                          : primaryTextStyle(size: 14))),
              printAmountWidget(
                  amount: amount.toStringAsFixed(2),
                  size: bold ? 18 : 14,
                  weight: bold ? FontWeight.w700 : FontWeight.w500),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row('Trip Fare$km', tripFare),
        row('Tax', tax),
        if (extra > 0) row('Additional Trip Charges', extra),
        Divider(height: 18),
        row('Total Fare', total, bold: true),
      ],
    );
  }
}
