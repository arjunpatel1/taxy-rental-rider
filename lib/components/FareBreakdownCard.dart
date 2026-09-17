import 'package:flutter/material.dart';

import '../utils/BrandTheme.dart';
import '../utils/Common.dart';
import '../utils/Extensions/app_common.dart';

/// Itemised final bill (trip_fare_data) shown on completed ride screens.
class FareBreakdownCard extends StatelessWidget {
  final Map<String, dynamic> bill;
  final num total;
  final String distanceUnit;

  const FareBreakdownCard({super.key, required this.bill, required this.total, this.distanceUnit = 'km'});

  static bool isFinal(Map<String, dynamic>? bill) => bill != null && bill['is_final'] == true;

  num _n(dynamic v) => v is num ? v : num.tryParse('$v') ?? 0;

  @override
  Widget build(BuildContext context) {
    final km = _n(bill['km']);
    final rows = <List<dynamic>>[];
    if (_n(bill['package_price']) > 0) {
      rows.add([bill['package_name'] ?? 'Rental package', '', _n(bill['package_price'])]);
      if (_n(bill['extra_km']) > 0) rows.add(['Extra distance', '${_n(bill['extra_km']).toStringAsFixed(1)} $distanceUnit', _n(bill['extra_km']) * _n(bill['extra_km_rate'])]);
      if (_n(bill['extra_hours']) > 0) rows.add(['Extra time', '${bill['extra_hours']} hr', _n(bill['extra_hours']) * _n(bill['extra_hour_rate'])]);
    } else {
      if (_n(bill['base_fare']) > 0) rows.add(['Base fare', '', _n(bill['base_fare'])]);
      rows.add(['Distance', '${_n(bill['billable_km'] ?? km).toStringAsFixed(1)} $distanceUnit × ${_n(bill['per_km'])}', _n(bill['distance_price'])]);
      if (_n(bill['time_price']) > 0) rows.add(['Time', '${_n(bill['minutes']).toInt()} min × ${_n(bill['per_minute'])}', _n(bill['time_price'])]);
      if (_n(bill['driver_allowance']) > 0) rows.add(['Driver allowance', '', _n(bill['driver_allowance'])]);
    }
    if (_n(bill['waiting_charge']) > 0) rows.add(['Waiting charge', '', _n(bill['waiting_charge'])]);
    if (_n(bill['surge_amount']) > 0) rows.add(['High demand', '', _n(bill['surge_amount'])]);
    if (_n(bill['discount']) > 0) rows.add(['Discount', '', -_n(bill['discount'])]);
    if (_n(bill['gst_amount']) > 0) rows.add(['GST ${_n(bill['gst_percent']).toStringAsFixed(0)}%', '', _n(bill['gst_amount'])]);

    final fromOdometer = bill['km_source'] == 'odometer';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(color: BrandTokens.fill, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _chip(Icons.route_rounded, '${km.toStringAsFixed(1)} $distanceUnit'),
              SizedBox(width: 8),
              if (bill['minutes'] != null) _chip(Icons.schedule_rounded, '${_n(bill['minutes']).toInt()} min'),
              Spacer(),
              if (fromOdometer) Text('Odometer ${bill['start_odometer']} → ${bill['end_odometer']}', style: secondaryTextStyle(size: 11)),
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
                      Expanded(child: Text(r[1], maxLines: 1, overflow: TextOverflow.ellipsis, style: secondaryTextStyle(size: 12))),
                    ] else
                      Spacer(),
                    printAmountWidget(amount: (r[2] as num).toStringAsFixed(2), size: 14, weight: FontWeight.w500, color: (r[2] as num) < 0 ? BrandTokens.success : null),
                  ],
                ),
              )),
          Divider(height: 18),
          Row(
            children: [
              Expanded(child: Text('Total fare', style: boldTextStyle(size: 16))),
              printAmountWidget(amount: total.toStringAsFixed(2), size: 18, weight: FontWeight.w700, color: BrandTokens.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) => Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: BrandTokens.blue),
          SizedBox(width: 4),
          Text(text, style: boldTextStyle(size: 12)),
        ]),
      );
}
