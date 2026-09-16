import 'package:intl/intl.dart';

import '../components/AnimatedTaxiRoad.dart';
import '../manage_imports.dart';

/// Rider home dashboard shown after login: greeting, "where to", wallet / points,
/// quick actions, active ride and recent rides. Booking itself happens on [DashBoardScreen] (the map).
class HomeScreen extends StatefulWidget {
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  num walletBalance = 0;
  num coins = 0;
  List<RiderModel> recentRides = [];
  CurrentRequestModel? currentRequest;
  bool isLoading = true;

  bool get _hasActiveRide => currentRequest?.onRideRequest != null || currentRequest?.rideRequest != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([
      getWalletData().then((value) {
        walletBalance = value.walletData?.totalAmount ?? 0;
      }).catchError((e) {
        log('wallet: $e');
      }),
      getCoinWalletList(page: 1).then((value) {
        coins = value.totalCoins ?? 0;
      }).catchError((e) {
        log('coins: $e');
      }),
      getRiderRequestList(page: 1, riderId: sharedPref.getInt(USER_ID)).then((value) {
        recentRides = (value.data ?? []).take(3).toList();
      }).catchError((e) {
        log('rides: $e');
      }),
      getCurrentRideRequest().then((value) {
        currentRequest = value;
      }).catchError((e) {
        log('current ride: $e');
      }),
    ]);
    isLoading = false;
    setState(() {});
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _displayName {
    final name = appStore.firstName.validate().isNotEmpty ? appStore.firstName : sharedPref.getString(FIRST_NAME).validate();
    return name.isNotEmpty ? name : 'Rider';
  }

  void _openBooking([String rideType = rideTypeLocal]) =>
      launchScreen(context, DashBoardScreen(openBooking: true, initialRideType: rideType), pageRouteAnimation: PageRouteAnimation.Slide).then((_) => _load());

  void _open(Widget screen) => launchScreen(context, screen, pageRouteAnimation: PageRouteAnimation.Slide).then((_) => _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color(0xFFF4F6F9),
      drawer: DrawerComponent(onClose: (_) {}),
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: brandBlue,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      body: RefreshIndicator(
        color: brandBlue,
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _header(),
            if (_hasActiveRide) _activeRideBanner(),
            _statsRow(),
            _sectionTitle('Services'),
            _quickActions(),
            _referBanner(),
            _sectionTitle('Recent rides', actionLabel: 'See all', onAction: () => _open(RideListScreen())),
            _recentRides(),
            SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _header() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [brandBlue, Color(0xFF1B5FD0)]),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
        child: Stack(
          children: [
            Positioned(left: 0, right: 0, bottom: 0, child: Opacity(opacity: 0.9, child: AnimatedTaxiRoad(height: 96))),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 104),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _circleButton(Icons.menu_rounded, () => _scaffoldKey.currentState!.openDrawer()),
                      Spacer(),
                      _circleButton(Icons.notifications_none_rounded, () => _open(NotificationScreen())),
                      SizedBox(width: 10),
                      GestureDetector(onTap: () => _open(EditProfileScreen()), child: _avatar()),
                    ],
                  ),
                  SizedBox(height: 18),
                  Text('$_greeting,', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text(_displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                  SizedBox(height: 16),
                  _whereToBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withValues(alpha: 0.85),
      shape: CircleBorder(),
      child: InkWell(customBorder: CircleBorder(), onTap: onTap, child: Padding(padding: EdgeInsets.all(9), child: Icon(icon, color: brandBlack, size: 22))),
    );
  }

  Widget _avatar() {
    final url = appStore.userProfile.validate();
    final initial = _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'S';
    final fallback = Container(
      color: brandBlue,
      alignment: Alignment.center,
      child: Text(initial, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
    );
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
      child: ClipOval(
        child: url.startsWith('http') ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback) : fallback,
      ),
    );
  }

  Widget _whereToBar() {
    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _openBooking,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(color: brandBlue, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.search_rounded, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text('Where are you going?', style: TextStyle(color: textSecondaryColor, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: brandBlue, borderRadius: BorderRadius.circular(20)),
                child: Text('Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activeRideBanner() {
    final ride = currentRequest?.onRideRequest ?? currentRequest?.rideRequest;
    final status = (ride?.status ?? '').replaceAll('_', ' ');
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Material(
        color: brandBlue,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _open(DashBoardScreen()),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(Icons.local_taxi_rounded, color: brandBlue),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your ride is in progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                      if (status.isNotEmpty) Text(status.capitalizeFirstLetter(), style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                Text('Track', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statsRow() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              icon: Icons.account_balance_wallet_rounded,
              iconBg: brandBlue,
              label: 'Wallet',
              value: isLoading ? Text('...', style: boldTextStyle(size: 20)) : printAmountWidget(amount: walletBalance.toStringAsFixed(digitAfterDecimal), size: 20, color: brandBlack),
              trailing: 'Add',
              onTap: () => _open(WalletTopupScreen(currentBalance: walletBalance)),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _statCard(
              icon: Icons.stars_rounded,
              iconBg: Color(0xFF2E7D6B),
              label: 'Points',
              value: Text(isLoading ? '...' : '${coins.toInt()}', style: TextStyle(color: brandBlack, fontSize: 20, fontWeight: FontWeight.w800)),
              onTap: () => _open(CoinWalletListScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({required IconData icon, required Color iconBg, required String label, required Widget value, required VoidCallback onTap, String? trailing}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(color: textSecondaryColor, fontSize: 13, fontWeight: FontWeight.w600)),
                    SizedBox(height: 2),
                    FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: value),
                  ],
                ),
              ),
              if (trailing != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: brandBlue, borderRadius: BorderRadius.circular(20)),
                  child: Text(trailing, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {String? actionLabel, VoidCallback? onAction}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 22, 8, 10),
      child: Row(
        children: [
          Expanded(child: Text(title, style: TextStyle(color: brandBlack, fontSize: 18, fontWeight: FontWeight.w800))),
          if (actionLabel != null) TextButton(onPressed: onAction, child: Text(actionLabel, style: TextStyle(color: brandBlue, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _quickActions() {
    final actions = [
      _QuickAction('Local', Icons.local_taxi_rounded, Color(0xFFE3ECFF), brandBlue, () => _openBooking(rideTypeLocal)),
      _QuickAction('Rental', Icons.timer_outlined, Color(0xFFE8F0FE), brandBlue, () => _openBooking(rideTypeRental)),
      _QuickAction('Outstation', Icons.alt_route_rounded, Color(0xFFE6F6FF), brandLightBlue, () => _openBooking(rideTypeOutstation)),
      _QuickAction('Schedule', Icons.event_available_rounded, Color(0xFFEFF3F8), brandBlack, () => _open(ScheduleRideListScreen())),
      _QuickAction('My rides', Icons.receipt_long_rounded, Color(0xFFF0F0F3), textSecondaryColor, () => _open(RideListScreen())),
      _QuickAction('Rewards', Icons.card_giftcard_rounded, Color(0xFFE0F2EF), Color(0xFF12836B), () => _open(RewardListScreen())),
      _QuickAction('Refer & earn', Icons.group_add_rounded, Color(0xFFE9F8EF), Color(0xFF1E9E57), () => _open(ReferEarnScreen())),
      _QuickAction('Recharge', Icons.smartphone_rounded, Color(0xFFEDE7FF), Color(0xFF5B3DF5), () => _open(RechargeScreen(title: 'Mobile recharge', serviceTypes: ['Prepaid', 'Postpaid', 'Data Card', 'DTH']))),
      _QuickAction('Bill payment', Icons.receipt_long_rounded, Color(0xFFE9F8EF), Color(0xFF1E9E57), () => _open(BillPaymentScreen())),
      _QuickAction('SOS', Icons.sos_rounded, Color(0xFFFDE8E8), Color(0xFFD93025), () => _open(EmergencyContactScreen())),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
        children: actions.map((a) {
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: a.onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(color: a.background, borderRadius: BorderRadius.circular(14)),
                    child: Icon(a.icon, color: a.foreground, size: 24),
                  ),
                  SizedBox(height: 8),
                  Text(a.label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: brandBlack, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _referBanner() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(ReferEarnScreen()),
          child: Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [brandBlue, Color(0xFF1760C8)]),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Invite friends, earn points', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                      SizedBox(height: 4),
                      Text('Share your referral code and get rewarded when they ride with S Taxi.', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: Text('Refer now', style: TextStyle(color: brandBlue, fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Icon(Icons.card_giftcard_rounded, color: Colors.white70, size: 64),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _recentRides() {
    if (isLoading) {
      return Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: brandBlue)));
    }
    if (recentRides.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: Row(
            children: [
              Icon(Icons.route_rounded, color: brandBlue, size: 32),
              SizedBox(width: 14),
              Expanded(child: Text('No rides yet. Book your first S Taxi ride!', style: TextStyle(color: textSecondaryColor, fontSize: 14, fontWeight: FontWeight.w600))),
            ],
          ),
        ),
      );
    }
    return Column(children: recentRides.map(_rideCard).toList());
  }

  Widget _rideCard(RiderModel ride) {
    final status = ride.status.validate();
    final Color statusColor = status == COMPLETED ? Color(0xFF1E9E57) : (status == CANCELED ? Color(0xFFD93025) : brandBlue);
    String date = ride.datetime.validate();
    try {
      date = DateFormat('d MMM, h:mm a').format(DateTime.parse(ride.datetime.validate()));
    } catch (_) {}

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: ride.id == null ? null : () => _open(RideDetailScreen(orderId: ride.id!)),
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Icon(Icons.radio_button_checked, color: brandBlue, size: 16),
                    Container(width: 2, height: 22, color: dividerColor),
                    Icon(Icons.location_on_rounded, color: Color(0xFFD93025), size: 18),
                  ],
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ride.startAddress.validate(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: brandBlack, fontSize: 14, fontWeight: FontWeight.w600)),
                      SizedBox(height: 14),
                      Text(ride.endAddress.validate(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: brandBlack, fontSize: 14, fontWeight: FontWeight.w600)),
                      SizedBox(height: 8),
                      Text(date, style: TextStyle(color: textSecondaryColor, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(status.replaceAll('_', ' ').capitalizeFirstLetter(), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomBar() {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: brandBlue,
      unselectedItemColor: textSecondaryColor,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
      onTap: (index) {
        switch (index) {
          case 1:
            _open(RideListScreen());
            break;
          case 2:
            _open(WalletScreen());
            break;
          case 3:
            _open(SettingScreen());
            break;
        }
      },
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Rides'),
        BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Wallet'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Account'),
      ],
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  _QuickAction(this.label, this.icon, this.background, this.foreground, this.onTap);
}
