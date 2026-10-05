import '../manage_imports.dart';
import 'RideDetailScreen.dart';
import '../utils/BrandTheme.dart';
import '../components/FareBreakdownCard.dart';

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
  /// Stars the rider gives the driver. Rating had been taken off this
  /// screen and never put anywhere else, so a rider could not rate at all
  /// and the "trip completed" banner never cleared.
  double _driverRating = 0;
  bool _ratingSent = false;
  num rattingData = 0;
  int currentIndex = -1;
  /// How the rider settles this trip: cash, wallet, or part of each.
  String payMethod = 'cash';
  /// Wallet balance, loaded once so the rider can see what they can cover.
  num walletBalance = 0;
  bool walletLoaded = false;

  num get _fare => widget.rideRequest.totalAmount ?? 0;
  /// Wallet + cash always puts the whole balance towards the fare, never more
  /// than the fare itself; the rest is handed to the driver in cash.
  num get _walletPart => walletBalance >= _fare ? _fare : walletBalance;
  bool get _walletCoversFare => walletBalance >= _fare && _fare > 0;

  String _payHint() {
    switch (payMethod) {
      case 'wallet':
        return 'The full fare will be taken from your S Taxi wallet';
      case 'split':
        return 'Wallet ${appStore.currencyCode}${_walletPart.toStringAsFixed(2)}  ·  Cash ${appStore.currencyCode}${(_fare - _walletPart).toStringAsFixed(2)} to the driver';
      default:
        return 'Pay the driver ${appStore.currencyCode}${_fare.toStringAsFixed(2)} in cash';
    }
  }

  Future<void> _callSupport() async {
    final number = (appStore.settingModel.contactNumber ?? '')
        .replaceAll(RegExp(r'[^0-9+]'), '');
    if (number.isEmpty) {
      toast('Support number is not available right now');
      return;
    }
    try {
      await launchUrl(Uri.parse('tel:$number'), mode: LaunchMode.externalApplication);
    } catch (e) {
      toast('Could not open the dialer');
    }
  }

  Future<void> _loadWallet() async {
    try {
      final info = await getWalletData();
      if (!mounted) return;
      setState(() {
        walletBalance = info.totalAmount ?? info.walletData?.totalAmount ?? 0;
        walletLoaded = true;
      });
    } catch (e) {
      log('Wallet balance not loaded: $e');
      if (mounted) setState(() => walletLoaded = true);
    }
  }
  OnRideRequest? servicesListData;

  @override
  void initState() {
    super.initState();
    if ((sharedPref.getInt(IS_REVIEW_ACCOUNT) ?? 0) != 1) _loadWallet();
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
                  // The ride's own id. The response has no top-level id, so
                  // this was always null and the detail screen opened empty.
                  rideId: value.onRideRequest?.id ?? value.id,
                ),
                isNewTask: true,
                pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
          },
        );
      }
    }).catchError((error) {
      // Payment is already recorded by this point. If the trip cannot be
      // reloaded the rider must still leave this screen, not sit on it.
      log(error.toString());
      appStore.setLoading(false);
      if (!mounted) return;
      launchScreen(context, HomeScreen(),
          isNewTask: true,
          pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
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
        // Stacked, so a two-word option like "Wallet + Cash" wraps onto its
        // own second line instead of having the last word clipped away.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: selected ? primaryColor : Colors.grey),
            SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: selected
                    ? boldTextStyle(color: primaryColor, size: 13)
                    : primaryTextStyle(size: 13)),
          ],
        ),
      ),
    );
  }

  /// Settles a wallet or wallet+cash trip for real.
  ///
  /// Recording the payment type alone left the trip unpaid, so the rider was
  /// sent back to the same screen again and again with nothing debited. The
  /// wallet share is charged through the payment endpoint, which debits the
  /// rider, pays the driver and closes the trip; a cash remainder is still
  /// collected by the driver.
  Future<bool> _payFromWallet() async {
    final walletShare = payMethod == 'wallet' ? _fare : _walletPart;
    // When the balance covers the whole fare there is no cash to hand over,
    // so it settles as a wallet payment. Sending it as a split asked the
    // server to accept cash confirmed by the rider, which it refuses.
    final cashShare = _fare - walletShare;
    final settleAs = (payMethod == 'wallet' || cashShare <= 0) ? WALLET : 'split';
    final req = {
      'ride_request_id': widget.rideRequest.id,
      'rider_id': widget.rideRequest.riderId,
      'datetime': DateTime.now().toString(),
      'total_amount': _fare,
      'payment_type': settleAs,
      'txn_id': '',
      'payment_status': PAID,
      'transaction_detail': '',
      if (settleAs == 'split') 'wallet_amount': walletShare,
      if (settleAs == 'split') 'cash_amount': cashShare,
    };
    try {
      await savePayment(req);
      await rideService.updateStatusOfRide(
        rideID: widget.rideRequest.id,
        req: {'on_stream_api_call': 0, 'payment_type': payMethod},
      );
      return true;
    } catch (e) {
      log('Wallet payment failed: $e');
      toast(e.toString());
      return false;
    }
  }

  Future<void> _savePaymentChoice() async {
    try {
      await rideRequestUpdate(
        request: {
          'payment_type': payMethod,
          'is_change_payment_type': 1,
          if (payMethod == 'split') 'wallet_amount': _walletPart,
          if (payMethod == 'wallet') 'wallet_amount': _fare,
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

  /// Sends the rider's rating for this trip. Until this existed the server
  /// never saw a rider rating, so every finished trip stayed "current" and the
  /// home banner for it could not be cleared.
  /// Sends the rider's rating, if they gave one. A rating that fails must not
  /// stop the payment: the trip still has to be settled.
  Future<void> _sendRating() async {
    try {
      await ratingReview(request: {
        'ride_request_id': widget.rideRequest.id,
        'rating': _driverRating,
        'comment': reviewController.text.trim(),
      });
      if (mounted) _ratingSent = true;
    } catch (e) {
      log('Rating could not be sent: $e');
    }
  }

  Future<void> userReviewData({bool? skip}) async {
    // The rider only confirms how they are paying here; rating a driver moved
    // out of this screen because the fare is what they need at trip end.
    if (widget.rideRequest.paymentStatus != PAID && payMethod == 'wallet' && !_walletCoversFare) {
      toast('Your wallet balance is not enough for this trip');
      return;
    }
    hideKeyboard(context);
    appStore.setLoading(true);

    // Stars are optional: a rider who leaves them untouched just pays. One
    // given is sent with the same tap, so there is nothing else to press.
    if (_driverRating > 0 && !_ratingSent) {
      await _sendRating();
    }

    if (widget.rideRequest.paymentStatus != PAID) {
      if (payMethod == 'cash') {
        // The driver collects the fare; only the choice needs recording.
        await _savePaymentChoice();
      } else {
        // Wallet and wallet+cash are charged for real here. Recording the
        // choice alone left the trip unpaid and the rider stuck on this
        // screen with nothing debited.
        final paid = await _payFromWallet();
        if (!paid) {
          appStore.setLoading(false);
          return;
        }
      }
    }
    appStore.setLoading(false);
    if (!mounted) return;

    if (widget.schedule_ride == true) {
      Navigator.pop(context);
      return;
    }

    // Straight home. The rider has seen the fare, chosen how to pay and, if
    // they wanted, rated the driver — there is nothing further for them to do.
    // Reloading the trip instead sent them to a live-tracking page for a trip
    // that had already ended, which rendered empty and looked frozen.
    toast(widget.rideRequest.paymentStatus == PAID
        ? 'Thanks for riding with us'
        : (payMethod == 'cash'
            ? 'Please pay the driver $currencySymbol${_fare.toStringAsFixed(digitAfterDecimal)} in cash'
            : 'Payment complete'));
    launchScreen(context, HomeScreen(),
        isNewTask: true, pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
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
        title: Text('Trip payment',
            style: boldTextStyle(color: Colors.white, size: 18)),
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
                            child: commonCachedNetworkImage(widget.driverData!.profileImage.validate(), height: 64, width: 64, fit: BoxFit.cover),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text('Trip completed with', style: secondaryTextStyle(size: 13)),
                        Text(
                          '${widget.driverData!.firstName.validate().capitalizeFirstLetter()} ${widget.driverData!.lastName.validate().capitalizeFirstLetter()}'.trim(),
                          style: boldTextStyle(size: 18),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 18),
                  // The fare first: the rider's question at trip end is always
                  // how much to pay, so it is shown before anything else.
                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: BrandTokens.line),
                    ),
                    child: EstimateFareCard(
                      total: _fare,
                      gst: num.tryParse('${widget.rideRequest.gstAmount ?? ''}') ?? 0,
                      distance: num.tryParse('${widget.rideRequest.distance ?? ''}') ?? 0,
                      distanceUnit: widget.rideRequest.distanceUnit,
                      extraCharges: num.tryParse('${widget.rideRequest.extraChargesAmount ?? ''}') ?? 0,
                    ),
                  ),
                  if (widget.rideRequest.paymentStatus != PAID &&
                      (sharedPref.getInt(IS_REVIEW_ACCOUNT) ?? 0) != 1) ...[
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 18, color: BrandTokens.inkSoft),
                        SizedBox(width: 8),
                        Text('Wallet Balance', style: primaryTextStyle(size: 14)),
                        Spacer(),
                        Text(
                          walletLoaded ? '${appStore.currencyCode}${walletBalance.toStringAsFixed(2)}' : '...',
                          style: boldTextStyle(size: 15),
                        ),
                      ],
                    ),
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
                        // Greyed out while the balance cannot cover the whole
                        // fare, so the rider cannot pick a payment that fails.
                        Expanded(
                          child: Opacity(
                            opacity: _walletCoversFare ? 1 : 0.4,
                            child: IgnorePointer(
                              ignoring: !_walletCoversFare,
                              child: _payOption(
                                label: language.wallet,
                                icon: Icons.account_balance_wallet_outlined,
                                selected: payMethod == 'wallet',
                                onTap: () => setState(() => payMethod = 'wallet'),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Opacity(
                            opacity: walletBalance > 0 ? 1 : 0.4,
                            child: IgnorePointer(
                              ignoring: walletBalance <= 0,
                              child: _payOption(
                                label: 'Wallet +\nCash',
                                icon: Icons.call_split_rounded,
                                selected: payMethod == 'split',
                                onTap: () => setState(() => payMethod = 'split'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(_payHint(), style: boldTextStyle(size: 13, color: BrandTokens.blue)),
                    if (!_walletCoversFare && walletLoaded) ...[
                      SizedBox(height: 4),
                      Text('Not enough wallet balance to pay the full fare',
                          style: secondaryTextStyle(size: 12)),
                    ],
                  ],
                  SizedBox(height: 18),
                  // Raising a complaint had no home in the app; riders were
                  // told to call support with no number in front of them.
                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: BrandTokens.blue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.support_agent_rounded, color: BrandTokens.blue),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Any problem with this trip?', style: boldTextStyle(size: 14)),
                              SizedBox(height: 2),
                              Text('Call our support team and we will sort it out',
                                  style: secondaryTextStyle(size: 12)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _callSupport(),
                          child: Text('Complaint', style: boldTextStyle(color: BrandTokens.blue, size: 14)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  // A fare the driver has already collected leaves nothing to
                  // submit, so the button says what it does. Rating lives on
                  // the trip page, and an unrated trip offers the way there
                  // rather than leaving the rider to hunt for it.
                  // Rating sits above the one button that finishes the trip.
                  // Two buttons asked the rider to submit twice, and rating is
                  // optional: stars left untouched simply are not sent.
                  if (widget.rideRequest.isRiderRated != 1 && !_ratingSent) ...[
                    SizedBox(height: 18),
                    Text('Rate your driver (optional)',
                        style: boldTextStyle(size: 15)),
                    SizedBox(height: 10),
                    Center(
                      child: RatingBar.builder(
                        direction: Axis.horizontal,
                        glow: false,
                        allowHalfRating: false,
                        itemCount: 5,
                        itemSize: 36,
                        initialRating: _driverRating,
                        itemPadding: EdgeInsets.symmetric(horizontal: 4),
                        itemBuilder: (context, _) =>
                            Icon(Icons.star, color: Colors.amber),
                        onRatingUpdate: (value) =>
                            setState(() => _driverRating = value),
                      ),
                    ),
                    SizedBox(height: 10),
                    AppTextField(
                      controller: reviewController,
                      textFieldType: TextFieldType.OTHER,
                      isValidationRequired: false,
                      maxLines: 2,
                      decoration: inputDecoration(context,
                          label: 'Anything to say about the trip? (optional)'),
                    ),
                  ],
                  SizedBox(height: 18),
                  AppButtonWidget(
                    text: widget.rideRequest.paymentStatus == PAID
                        ? 'Done'
                        : language.submit,
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
