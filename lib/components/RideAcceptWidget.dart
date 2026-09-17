import '../manage_imports.dart';
import '../utils/BrandTheme.dart';

class RideAcceptWidget extends StatefulWidget {
  final Driver? driverData;
  final OnRideRequest? rideRequest;

  RideAcceptWidget({this.driverData, this.rideRequest});

  @override
  RideAcceptWidgetState createState() => RideAcceptWidgetState();
}

class RideAcceptWidgetState extends State<RideAcceptWidget> {
  UserModel? userData;
  double duration = 0;

  @override
  void initState() {
    super.initState();
    init();
    listenForNewDuration();
  }

  void init() async {
    await getUserDetail(userId: widget.rideRequest!.driverId).then((value) {
      sharedPref.remove(IS_TIME);
      appStore.setLoading(false);
      userData = value.data;
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);
    });
  }

  void listenForNewDuration() {
    FirebaseFirestore.instance.collection(RIDE_COLLECTION).where('rider_id', isEqualTo: sharedPref.getInt(USER_ID)!).where('ride_id', isEqualTo: widget.rideRequest!.id).snapshots().listen((QuerySnapshot snapshot) {
      for (var doc in snapshot.docs) {
        var rideData = doc.data() as Map<String, dynamic>;

        if (rideData['duration'] != null) {
          duration = (rideData['duration'] as num).toDouble();
        } else {
          duration = 0;
        }
        setState(() {});
      }
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Future<void> cancelRequest(String reason) async {
    Map req = {
      "id": widget.rideRequest!.id,
      "cancel_by": RIDER,
      "status": CANCELED,
      "reason": reason,
    };
    await rideRequestUpdate(request: req, rideId: widget.rideRequest!.id).then((value) async {
      toast(value.message);
      chatMessageService.justDeleteChat(
        senderId: sharedPref.getString(UID).validate(),
        receiverId: userData!.uid.validate(),
      );
    }).catchError((error) {
      try {
        chatMessageService.justDeleteChat(
          senderId: sharedPref.getString(UID).validate(),
          receiverId: userData!.uid.validate(),
        );
      } catch (e) {}
      log(error.toString());
    });
  }

  String get _statusTitle {
    switch (widget.rideRequest!.status) {
      case ACCEPTED:
      case BID_ACCEPTED:
        return 'Driver is on the way';
      case ARRIVING:
        return 'Driver is arriving';
      case ARRIVED:
        return 'Driver has arrived';
      case IN_PROGRESS:
        return 'On the trip';
      default:
        return statusName(status: widget.rideRequest!.status.validate());
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.rideRequest!;
    final driver = widget.driverData!;
    final showOtp = ride.status != IN_PROGRESS && ride.status != COMPLETED;
    final showEta = (ride.status == ACCEPTED || ride.status == BID_ACCEPTED || ride.status == ARRIVING) && duration != 0;
    final arrived = ride.status == ARRIVED;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(18, 10, 18, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: BrandTokens.line, borderRadius: BorderRadius.circular(4)))),
          SizedBox(height: 14),

          // status + ETA
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_statusTitle, style: boldTextStyle(size: 18)),
                    SizedBox(height: 2),
                    Text(
                      arrived
                          ? 'Meet your driver at the pickup point'
                          : ride.status == IN_PROGRESS
                              ? 'Sit back and relax, share your trip for safety'
                              : 'Share the OTP only after you get in the cab',
                      style: secondaryTextStyle(size: 12),
                    ),
                  ],
                ),
              ),
              if (showEta)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: BrandTokens.blueSoft, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      Text(duration < 1 ? 'Now' : '${duration.toStringAsFixed(0)} min', style: boldTextStyle(size: 16, color: BrandTokens.blue)),
                      Text(language.ETA, style: secondaryTextStyle(size: 10)),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 14),

          // driver + car card
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: BrandTokens.line)),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: commonCachedNetworkImage(driver.profileImage.validate(), fit: BoxFit.cover, height: 52, width: 52),
                        ),
                      ],
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${driver.firstName.validate()} ${driver.lastName.validate()}'.trim(), maxLines: 1, overflow: TextOverflow.ellipsis, style: boldTextStyle(size: 16)),
                          SizedBox(height: 2),
                          Text(
                            [driver.userDetail?.carColor.validate(), driver.userDetail?.carModel.validate(), driver.driverService?.name.validate()].where((v) => (v ?? '').isNotEmpty).join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: secondaryTextStyle(size: 12),
                          ),
                          SizedBox(height: 6),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Color(0xFFFFF6CC), borderRadius: BorderRadius.circular(6), border: Border.all(color: Color(0xFFE8D36B))),
                            child: Text(driver.userDetail?.carPlateNumber.validate().toUpperCase() ?? '', style: boldTextStyle(size: 13, letterSpacing: 1)),
                          ),
                        ],
                      ),
                    ),
                    if (showOtp)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: BrandTokens.blue, borderRadius: BorderRadius.circular(14)),
                        child: Column(
                          children: [
                            Text('OTP', style: secondaryTextStyle(size: 10, color: Colors.white70)),
                            Text(ride.otp ?? '----', style: boldTextStyle(size: 20, color: Colors.white, letterSpacing: 2)),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12),
                Divider(height: 1),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _action(
                      icon: Icons.call_rounded,
                      label: 'Call',
                      onTap: () => launchUrl(Uri.parse('tel:${driver.contactNumber}'), mode: LaunchMode.externalApplication),
                    ),
                    if (userData != null)
                      _action(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Chat',
                        badge: chatCallWidget(Icons.chat_bubble_outline, chat: true),
                        onTap: () async {
                          if (userData == null || userData!.uid == null) {
                            init();
                            return;
                          }
                          launchScreen(context, ChatScreen(userData: userData, ride_id: ride.id!), pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
                        },
                      ),
                    _action(
                      icon: Icons.sos_rounded,
                      label: 'SOS',
                      danger: true,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(contentPadding: EdgeInsets.all(0), content: AlertScreen(rideId: ride.id, regionId: ride.regionId)),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 14),

          // route
          _routePoint(BrandTokens.success, 'PICKUP', ride.startAddress ?? ''),
          Padding(padding: EdgeInsets.only(left: 5), child: Container(width: 2, height: 16, color: BrandTokens.line)),
          _routePoint(BrandTokens.danger, 'DROP', ride.endAddress ?? ''),
          if (ride.multiDropLocation != null && ride.multiDropLocation!.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => showOnlyDropLocationsDialog(context, ride.multiDropLocation!),
                icon: Icon(Icons.add_location_alt_outlined, size: 18),
                label: Text(language.viewMore),
              ),
            ),
          SizedBox(height: 14),

          if (ride.status != IN_PROGRESS && ride.status != COMPLETED)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: BrandTokens.danger,
                  side: BorderSide(color: BrandTokens.danger.withValues(alpha: 0.35), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isDismissible: false,
                    isScrollControlled: true,
                    builder: (context) {
                      return CancelOrderDialog(
                        onCancel: (reason) async {
                          Navigator.pop(context);
                          appStore.setLoading(true);
                          sharedPref.remove(REMAINING_TIME);
                          sharedPref.remove(IS_TIME);
                          await cancelRequest(reason);
                          appStore.setLoading(false);
                        },
                      );
                    },
                  );
                },
                child: Text('Cancel ride', style: boldTextStyle(size: 15, color: BrandTokens.danger)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _routePoint(Color color, String label, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 3)),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: secondaryTextStyle(size: 11)),
              Text(address, maxLines: 2, overflow: TextOverflow.ellipsis, style: primaryTextStyle(size: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _action({required IconData icon, required String label, required VoidCallback onTap, bool danger = false, Widget? badge}) {
    final color = danger ? BrandTokens.danger : BrandTokens.blue;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.10), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 21),
                ),
                if (badge != null) Positioned(top: -2, right: -2, child: SizedBox(width: 16, height: 16, child: badge)),
              ],
            ),
            SizedBox(height: 4),
            Text(label, style: secondaryTextStyle(size: 12, color: danger ? BrandTokens.danger : BrandTokens.ink)),
          ],
        ),
      ),
    );
  }

  /// Unread-chat dot (the round buttons above draw the icon itself).
  Widget chatCallWidget(IconData icon, {bool chat = false}) {
    if (sharedPref.getString(UID) == null || !chat) return SizedBox();
    return StreamBuilder<int>(
      stream: chatMessageService.getUnReadCount(senderId: "${sharedPref.getString(UID)}", receiverId: widget.driverData!.uid.toString()),
      builder: (context, snapshot) {
        if (snapshot.hasData && (snapshot.data ?? 0) > 0) {
          return Container(decoration: BoxDecoration(color: BrandTokens.danger, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)));
        }
        return SizedBox();
      },
    );
  }
}

void showOnlyDropLocationsDialog(
  BuildContext context,
  List<MultiDropLocation> dropLocations,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          language.viewDropLocations,
          style: primaryTextStyle(size: 18, weight: FontWeight.w500),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: dropLocations.map((location) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.green, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text(location.address, style: primaryTextStyle(size: 14), overflow: TextOverflow.ellipsis, maxLines: 2)),
                      if (location.droppedAt != null)
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        )
                    ],
                  ),
                  Divider(
                    height: 10,
                  )
                ],
              );
            }).toList(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              language.close,
              style: primaryTextStyle(),
            ),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
        ],
      );
    },
  );
}
