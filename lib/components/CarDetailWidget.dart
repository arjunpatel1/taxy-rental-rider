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
          // One plain breakdown for every trip type: what the ride costs,
          // the tax on it, and the total. The make-up of the trip fare (base,
          // distance, time, allowance) belongs on the admin trip page, not in
          // front of a rider deciding which cab to take.
          Builder(builder: (_) {
            final total = widget.service.totalAmountAfterDiscount ??
                widget.service.totalAmount ??
                0;
            final tax = widget.service.gstAmount ?? 0;
            final tripFare = total - tax < 0 ? 0 : total - tax;
            final km = locationDistance > 0
                ? ' ${locationDistance.toStringAsFixed(locationDistance % 1 == 0 ? 0 : 1)}${widget.service.distanceUnit ?? 'km'}'
                : '';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fareRow('Trip Fare$km', tripFare),
                SizedBox(height: 8),
                _fareRow('Tax', tax),
                if ((widget.service.discountAmount ?? 0) > 0) ...[
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(language.couponDiscount, style: primaryTextStyle(color: Colors.green)),
                      printAmountWidgetForEstimate(
                          amount: '${widget.service.discountAmount!.toStringAsFixed(digitAfterDecimal)}',
                          weight: FontWeight.normal,
                          color: Colors.green,
                          sign: "-"),
                    ],
                  ),
                ],
                if ((widget.service.coinsUsed ?? 0) > 0) ...[
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Coins', style: primaryTextStyle(color: Colors.green)),
                      printAmountWidgetForEstimate(
                          amount: '${widget.service.coinsUsed!.toStringAsFixed(digitAfterDecimal)}',
                          weight: FontWeight.normal,
                          color: Colors.green,
                          sign: "-"),
                    ],
                  ),
                ],
                Divider(),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(language.totalFare, style: boldTextStyle(size: 22)),
                    printAmountWidget(
                        amount: '${total.toStringAsFixed(digitAfterDecimal)}',
                        weight: FontWeight.bold,
                        size: 22),
                  ],
                ),
              ],
            );
          }),
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
