import '../manage_imports.dart';
import '../utils/BrandTheme.dart';

class ReviewScreen extends StatefulWidget {
  final Driver? driverData;
  final OnRideRequest rideRequest;
  final bool? schedule_ride;

  ReviewScreen(
      {this.driverData, required this.rideRequest, this.schedule_ride});

  @override
  ReviewScreenState createState() => ReviewScreenState();
}

class ReviewScreenState extends State<ReviewScreen> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  RideService rideService = RideService();
  TextEditingController reviewController = TextEditingController();
  num rattingData = 0;
  int currentIndex = -1;
  /// How the rider settles this trip: cash, wallet, or part of each.
  String payMethod = 'cash';
  TextEditingController walletPartController = TextEditingController();

  num get _fare => widget.rideRequest.totalAmount ?? 0;
  num get _walletPart => num.tryParse(walletPartController.text.trim()) ?? 0;

  String _payHint() {
    switch (payMethod) {
      case 'wallet':
        return 'The fare will be taken from your S Taxi wallet';
      case 'split':
        if (_walletPart <= 0 || _walletPart >= _fare) {
          return 'Enter how much to take from the wallet, less than the fare';
        }
        return 'Wallet ${appStore.currencyCode}$_walletPart, cash ${appStore.currencyCode}${_fare - _walletPart} to the driver';
      default:
        return 'Pay the driver in cash';
    }
  }
  OnRideRequest? servicesListData;

  @override
  void initState() {
    super.initState();
  }

  Future<void> getCurrentRequest() async {
    await getCurrentRideRequest().then((value) {
      servicesListData = value.onRideRequest;

      if (value.onRideRequest == null) {
        Future.delayed(
          Duration(seconds: 1),
          () {
            launchScreen(context, HomeScreen(),
                isNewTask: true,
                pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
          },
        );
      } else {
        Future.delayed(
          Duration(seconds: 1),
          () {
            launchScreen(
                context,
                RidePaymentDetailScreen(
                  rideId: value.id,
                ),
                isNewTask: true,
                pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
          },
        );
      }
    }).catchError((error) {
      log(error.toString());
    });
  }

  Widget _payOption({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return inkWellWidget(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? primaryColor.withValues(alpha: 0.08) : Colors.transparent,
          border: Border.all(
              color: selected ? primaryColor : Colors.grey.shade300,
              width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: selected ? primaryColor : Colors.grey),
            SizedBox(width: 8),
            Text(label,
                style: selected
                    ? boldTextStyle(color: primaryColor, size: 14)
                    : primaryTextStyle(size: 14)),
          ],
        ),
      ),
    );
  }

  Future<void> _savePaymentChoice() async {
    try {
      await rideRequestUpdate(
        request: {
          'payment_type': payMethod,
          'is_change_payment_type': 1,
          if (payMethod == 'split') 'wallet_amount': _walletPart,
        },
        rideId: widget.rideRequest.id,
      );
      await rideService.updateStatusOfRide(
        rideID: widget.rideRequest.id,
        req: {'on_stream_api_call': 0, 'payment_type': payMethod},
      );
    } catch (e) {
      // The rating still stands; the rider can change this from the trip page.
      log('Payment choice not saved: $e');
    }
  }

  Future<void> userReviewData({bool? skip}) async {
    if (skip != true && !formKey.currentState!.validate()) return;
    // A split has to name a wallet share smaller than the fare.
    if (widget.rideRequest.paymentStatus != PAID &&
        payMethod == 'split' &&
        (_walletPart <= 0 || _walletPart >= _fare)) {
      toast('Enter how much to take from the wallet, less than the fare');
      return;
    }
    hideKeyboard(context);
    if (rattingData == 0 && skip != true)
      return toast(language.pleaseSelectRating);
    formKey.currentState!.save();
    appStore.setLoading(true);
    Map req = {
      "ride_request_id": widget.rideRequest.id,
      "rating": skip == true ? 0 : rattingData,
      "comment": skip == true ? '' : reviewController.text.trim(),
    };
    await ratingReview(request: req).then((value) async {
      // Record how the rider chose to pay, so a trip booked as cash can still
      // be settled from the wallet and the other way round.
      if (widget.rideRequest.paymentStatus != PAID) {
        await _savePaymentChoice();
      }
      appStore.setLoading(false);
      if (widget.schedule_ride == true) {
        print("back");
        Navigator.pop(context);
      } else {
        print("not back");
        getCurrentRequest();
      }
    }).catchError((error) {
      appStore.setLoading(false);
      log(error.toString());
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: brandBlue,
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text('Rate your trip',
            style: boldTextStyle(color: Colors.white, size: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: MaterialButton(
              shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.white),
                  borderRadius: BorderRadius.circular(12)),
              onPressed: () {
                userReviewData(skip: true);
              },
              child: Text(language.skip,
                  style: boldTextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: formKey,
            child: SingleChildScrollView(
              padding:
                  EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: BrandTokens.blue.withValues(alpha: 0.25), width: 3)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(44),
                            child: commonCachedNetworkImage(widget.driverData!.profileImage.validate(), height: 84, width: 84, fit: BoxFit.cover),
                          ),
                        ),
                        SizedBox(height: 12),
                        Text('How was your trip with', style: secondaryTextStyle(size: 14)),
                        Text(
                          '${widget.driverData!.firstName.validate().capitalizeFirstLetter()} ${widget.driverData!.lastName.validate().capitalizeFirstLetter()}?'.trim(),
                          style: boldTextStyle(size: 20),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4),
                        Text(
                          [widget.driverData!.userDetail?.carModel.validate(), widget.driverData!.userDetail?.carPlateNumber.validate().toUpperCase()].where((v) => (v ?? '').isNotEmpty).join(' · '),
                          style: secondaryTextStyle(size: 12),
                        ),
                        SizedBox(height: 18),
                        RatingBar.builder(
                          direction: Axis.horizontal,
                          glow: false,
                          allowHalfRating: false,
                          itemCount: 5,
                          itemSize: 44,
                          unratedColor: BrandTokens.line,
                          itemPadding: EdgeInsets.symmetric(horizontal: 4),
                          itemBuilder: (context, _) => Icon(Icons.star_rounded, color: Color(0xFFFFB300)),
                          onRatingUpdate: (rating) {
                            setState(() => rattingData = rating);
                          },
                        ),
                        SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 180),
                          child: Text(
                            ['Tap a star to rate', 'Terrible', 'Bad', 'Okay', 'Good', 'Excellent!'][rattingData.toInt().clamp(0, 5)],
                            key: ValueKey(rattingData),
                            style: boldTextStyle(size: 15, color: rattingData >= 4 ? BrandTokens.success : (rattingData == 0 ? BrandTokens.inkSoft : BrandTokens.warning)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  if (rattingData > 0) ...[
                    Text(rattingData >= 4 ? 'What went well?' : 'What could be better?', style: boldTextStyle(size: 15)),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (rattingData >= 4
                              ? ['Safe driving', 'Clean car', 'On time', 'Polite driver', 'Smooth ride']
                              : ['Late pickup', 'Rash driving', 'Car not clean', 'Rude behaviour', 'Wrong route'])
                          .map((tag) {
                        final picked = reviewController.text.contains(tag);
                        return ChoiceChip(
                          label: Text(tag),
                          selected: picked,
                          showCheckmark: false,
                          selectedColor: BrandTokens.blue,
                          labelStyle: primaryTextStyle(size: 13, color: picked ? Colors.white : BrandTokens.ink),
                          onSelected: (_) {
                            final parts = reviewController.text.split(', ').where((t) => t.trim().isNotEmpty).toList();
                            picked ? parts.remove(tag) : parts.add(tag);
                            reviewController.text = parts.join(', ');
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                  ],
                  Text(language.addReviews, style: boldTextStyle(size: 15)),
                  SizedBox(height: 10),
                  AppTextField(
                    controller: reviewController,
                    decoration: inputDecoration(context,
                        label: language.writeYourComments),
                    textFieldType: TextFieldType.NAME,
                    minLines: 2,
                    maxLines: 5,
                  ),
                  // Tipping was removed. What the rider needs here is to say how
                  // they are paying, because many forget to choose at booking.
                  if (widget.rideRequest.paymentStatus != PAID) ...[
                    SizedBox(height: 20),
                    Text('How would you like to pay?',
                        style: boldTextStyle(size: 16)),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _payOption(
                            label: language.cash,
                            icon: Icons.payments_outlined,
                            selected: payMethod == 'cash',
                            onTap: () => setState(() => payMethod = 'cash'),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _payOption(
                            label: language.wallet,
                            icon: Icons.account_balance_wallet_outlined,
                            selected: payMethod == 'wallet',
                            onTap: () => setState(() => payMethod = 'wallet'),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _payOption(
                            label: 'Both',
                            icon: Icons.call_split_rounded,
                            selected: payMethod == 'split',
                            onTap: () => setState(() => payMethod = 'split'),
                          ),
                        ),
                      ],
                    ),
                    // Part from the wallet, the rest in cash: a 500 fare with
                    // 200 in the wallet is 200 wallet + 300 cash.
                    if (payMethod == 'split') ...[
                      SizedBox(height: 12),
                      TextField(
                        controller: walletPartController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Pay from wallet',
                          prefixText: appStore.currencyCode,
                        ),
                      ),
                    ],
                    SizedBox(height: 6),
                    Text(_payHint(), style: secondaryTextStyle(size: 12)),
                  ],
                  SizedBox(height: 16),
                  AppButtonWidget(
                    text: language.submit,
                    width: MediaQuery.of(context).size.width,
                    onTap: () {
                      userReviewData();
                    },
                  ),
                ],
              ),
            ),
          ),
          Observer(builder: (context) {
            return Visibility(
              visible: appStore.isLoading,
              child: loaderWidget(),
            );
          })
        ],
      ),
    );
  }
}
