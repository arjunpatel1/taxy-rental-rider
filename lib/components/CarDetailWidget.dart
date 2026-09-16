import '../manage_imports.dart';

class CarDetailWidget extends StatefulWidget {
  final ServicesListData service;
  final String tripType;

  CarDetailWidget({required this.service, required this.tripType});

  @override
  CarDetailWidgetState createState() => CarDetailWidgetState();
}

class CarDetailWidgetState extends State<CarDetailWidget> {
  double locationDistance = 0.0;
  double fareDistance = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.service.distanceUnit == DISTANCE_TYPE_KM) {
      locationDistance = widget.service.dropoffDistanceInKm!.toDouble();
    } else {
      locationDistance = widget.service.dropoffDistanceInKm!.toDouble() * 0.621371;
    }
    locationDistance = double.parse(locationDistance.toStringAsFixed(digitAfterDecimal));

    double distance = double.parse(
      widget.service.dropoffDistanceInKm!.toStringAsFixed(digitAfterDecimal),
    );

    fareDistance = distance - widget.service.minimumDistance!.toDouble();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Widget _fareRow(String label, num amount, {String? sign}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: primaryTextStyle())),
          sign == null
              ? printAmountWidget(amount: amount.toStringAsFixed(digitAfterDecimal), weight: FontWeight.normal)
              : printAmountWidgetForEstimate(amount: amount.toStringAsFixed(digitAfterDecimal), weight: FontWeight.normal, sign: sign),
        ],
      ),
    );
  }

  /// Breakdown for rental (package + extra rates) and outstation (km x rate + driver allowance) fares.
  List<Widget> _tripFareRows(Map<String, dynamic> fare) {
    num value(String key) => (fare[key] as num?) ?? 0;

    if (fare['type'] == 'rental') {
      return [
        _fareRow('Rental package (${fare['hours']} ${fare['hours'] == 1 ? 'hr' : 'hrs'} / ${fare['km']} km)', value('package_price')),
        _fareRow('Extra km (per km)', value('extra_km_rate')),
        _fareRow('Extra time (per hour)', value('extra_hour_rate')),
        if (value('gst_amount') > 0) _fareRow('GST (${value('gst_percent')}%) on package', value('gst_amount'), sign: '+'),
        Text('Estimated fare. The final bill uses the odometer km and trip time: extra km and extra hours beyond the package are added at the rates above.', style: secondaryTextStyle(size: 12)),
        SizedBox(height: 8),
      ];
    }

    final days = value('days').toInt();
    final isRound = fare['type'] == 'outstation_round';
    return [
      Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text(isRound ? 'Outstation · Round trip' : 'Outstation · One-way', style: boldTextStyle()),
      ),
      _fareRow('Distance (${value('billable_km').round()} km × ${value('per_km')})', value('distance_price')),
      if (value('time_price') > 0) _fareRow('Drive time (${value('minutes').round()} min × ${value('per_minute')})', value('time_price'), sign: '+'),
      if (value('driver_allowance') > 0) _fareRow('Driver allowance ($days ${days == 1 ? 'day' : 'days'})', value('driver_allowance'), sign: '+'),
      if (value('gst_amount') > 0) _fareRow('GST (${value('gst_percent')}%)', value('gst_amount'), sign: '+'),
      Text(
        isRound
            ? 'Round trip is billed on total km, with a minimum km per day. Tolls, parking and state tax are extra.'
            : 'This is an estimated fare. The final fare is calculated from the actual km and trip time when the trip ends. Tolls, parking and state tax are extra.',
        style: secondaryTextStyle(size: 12),
      ),
      SizedBox(height: 8),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              alignment: Alignment.center,
              height: 5,
              width: 70,
              decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(defaultRadius)),
            ),
          ),
          SizedBox(height: 12),
          Center(child: Text(widget.service.name.validate(), style: boldTextStyle(size: 20))),
          SizedBox(height: 8),
          Text(language.fareBreakdown, style: boldTextStyle(size: 20)),
          SizedBox(height: 8),
          if (widget.service.tripFareData != null) ...[
            ..._tripFareRows(widget.service.tripFareData!),
            if (widget.service.discountAmount != null && widget.service.discountAmount! > 0) ...[
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text(language.couponDiscount, style: primaryTextStyle(color: Colors.green)), printAmountWidgetForEstimate(amount: '${widget.service.discountAmount!.toStringAsFixed(digitAfterDecimal)}', weight: FontWeight.normal, color: Colors.green, sign: "-")],
              ),
            ],
            if (widget.service.coinsUsed != null && widget.service.coinsUsed! > 0) ...[
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text('Coins', style: primaryTextStyle(color: Colors.green)), printAmountWidgetForEstimate(amount: '${widget.service.coinsUsed!.toStringAsFixed(digitAfterDecimal)}', weight: FontWeight.normal, color: Colors.green, sign: "-")],
              ),
            ],
            Divider(),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(language.totalFare, style: boldTextStyle(size: 24)), printAmountWidget(amount: '${widget.service.totalAmountAfterDiscount!.toStringAsFixed(digitAfterDecimal)}', weight: FontWeight.bold, size: 24)],
            ),
          ] else if (widget.tripType == tripTypeZoneWise) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(language.fixedPrice, style: primaryTextStyle()), printAmountWidget(amount: '${widget.service.subtotal!.toStringAsFixed(digitAfterDecimal)}', weight: FontWeight.normal)],
            ),
            if (widget.service.surgeAmount != null && widget.service.surgeAmount! > 0) ...[
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text(language.highDemandCharge, style: primaryTextStyle(color: Colors.red)), printAmountWidgetForEstimate(amount: '${widget.service.surgeAmount!.toStringAsFixed(digitAfterDecimal)}', weight: FontWeight.normal, color: Colors.red, sign: "+")],
              ),
            ],
            if (widget.service.discountAmount != null && widget.service.discountAmount! > 0) ...[
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text(language.couponDiscount, style: primaryTextStyle(color: Colors.green)), printAmountWidgetForEstimate(amount: '${widget.service.discountAmount!.toStringAsFixed(digitAfterDecimal)}', weight: FontWeight.normal, color: Colors.green, sign: "-")],
              ),
              SizedBox(height: 8),
            ],
            if (widget.service.coinsUsed != null && widget.service.coinsUsed! > 0) ...[
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text('Coins', style: primaryTextStyle(color: Colors.green)), printAmountWidgetForEstimate(amount: '${widget.service.coinsUsed!.toStringAsFixed(digitAfterDecimal)}', weight: FontWeight.normal, color: Colors.green, sign: "-")],
              ),
              SizedBox(height: 8),
            ],
            Divider(),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(language.totalFare, style: boldTextStyle(size: 24)), printAmountWidget(amount: '${widget.service.totalAmountAfterDiscount!.toStringAsFixed(digitAfterDecimal)}', weight: FontWeight.bold, size: 24)],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(language.baseFare, style: primaryTextStyle()), printAmountWidget(amount: '${widget.service.baseFare!.toStringAsFixed(digitAfterDecimal)}', weight: FontWeight.normal)],
            ),
            if (widget.service.distancePrice != null && widget.service.distancePrice! > 0) ...[
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(
                        widget.service.distancePrice! == 0 ? language.distanceFare : '${language.distanceFare} ( ${fareDistance.toStringAsFixed(2)} * ${widget.service.perDistance} )',
                        style: primaryTextStyle(),
                      )
                    ],
                  ),
                  printAmountWidgetForEstimate(amount: '${widget.service.distancePrice!.toStringAsFixed(digitAfterDecimal)}', weight: FontWeight.normal, sign: "+")
                ],
              ),
            ],
            if ((widget.service.perMinuteDrive ?? 0) > 0 || (widget.service.surgeAmount ?? 0) > 0) ...[
              if (widget.service.timePrice != null && widget.service.timePrice! > 0) ...[
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(language.extraRideTime, style: primaryTextStyle()), printAmountWidgetForEstimate(amount: '${widget.service.timePrice!.toStringAsFixed(digitAfterDecimal)}', weight: FontWeight.normal, sign: "+")],
                ),
              ],
              SizedBox(height: 8),
            ],
            Divider(),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(language.subTotal, style: boldTextStyle()), printAmountWidget(amount: '${widget.service.subtotal!.toStringAsFixed(digitAfterDecimal)}', weight: FontWeight.bold)],
            ),
            SizedBox(height: 8),
            if ((widget.service.gstAmount ?? 0) > 0) _fareRow('GST (${widget.service.gstPercent}%)', widget.service.gstAmount!, sign: '+'),
            if (widget.service.surgeAmount != null && widget.service.surgeAmount! > 0) ...[
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text(language.highDemandCharge, style: primaryTextStyle(color: Colors.red)), printAmountWidgetForEstimate(amount: '${widget.service.surgeAmount!.toStringAsFixed(digitAfterDecimal)}', weight: FontWeight.normal, color: Colors.red, sign: "+")],
              ),
            ],
            if (widget.service.coinsUsed != null && widget.service.coinsUsed! > 0) ...[
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text('Coins', style: primaryTextStyle(color: Colors.green)), printAmountWidgetForEstimate(amount: '${widget.service.coinsUsed!.toStringAsFixed(digitAfterDecimal)}', weight: FontWeight.normal, color: Colors.green, sign: "-")],
              ),
              SizedBox(height: 8),
            ],
            if (widget.service.discountAmount != null && widget.service.discountAmount! > 0) ...[
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text(language.couponDiscount, style: primaryTextStyle(color: Colors.green)), printAmountWidgetForEstimate(amount: '${widget.service.discountAmount!.toStringAsFixed(digitAfterDecimal)}', weight: FontWeight.normal, color: Colors.green, sign: "-")],
              ),
              SizedBox(height: 8),
            ],
            Divider(),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(language.totalFare, style: boldTextStyle(size: 24)), printAmountWidget(amount: '${widget.service.totalAmountAfterDiscount!.toStringAsFixed(digitAfterDecimal)}', weight: FontWeight.bold, size: 24)],
            ),
          ],
          SizedBox(height: 8),
          Text(widget.service.description.validate(), style: secondaryTextStyle(), textAlign: TextAlign.justify),
          AppButtonWidget(
            text: language.close,
            width: MediaQuery.of(context).size.width,
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
