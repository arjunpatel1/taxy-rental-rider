import '../manage_imports.dart';

class CreateTabScreen extends StatefulWidget {
  final String? status;

  CreateTabScreen({this.status});

  @override
  CreateTabScreenState createState() => CreateTabScreenState();
}

class CreateTabScreenState extends State<CreateTabScreen> with AutomaticKeepAliveClientMixin {
  final ScrollController scrollController = ScrollController();
  int currentPage = 1;
  int totalPage = 1;
  List<RiderModel> riderData = [];

  // each tab tracks its own loading; the shared appStore flag made one tab hide the other's loader
  bool loading = true;
  bool loadingMore = false;
  String? error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    getRideList();
    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200 && !loading && !loadingMore && currentPage < totalPage) {
        currentPage++;
        setState(() => loadingMore = true);
        getRideList();
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Future<void> getRideList() async {
    try {
      final value = await getRiderRequestList(page: currentPage, status: widget.status, riderId: sharedPref.getInt(USER_ID));
      currentPage = value.pagination?.currentPage ?? currentPage;
      totalPage = value.pagination?.totalPages ?? 1;
      if (currentPage == 1) riderData.clear();
      riderData.addAll(value.data ?? []);
      error = null;
    } catch (e) {
      log(e.toString());
      if (currentPage > 1) currentPage--;
      error = e.toString();
    }
    setState(() {
      loading = false;
      loadingMore = false;
    });
  }

  Future<void> _refresh() async {
    currentPage = 1;
    await getRideList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (loading) return Center(child: loaderWidget());

    return RefreshIndicator(
      color: brandBlue,
      onRefresh: _refresh,
      child: riderData.isEmpty
          ? ListView(
              physics: AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: 60),
                emptyWidget(),
                Text(
                  error != null ? 'Could not load rides. Pull down to try again.' : _emptyText(),
                  style: secondaryTextStyle(size: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : AnimationLimiter(
              child: ListView.builder(
                physics: AlwaysScrollableScrollPhysics(),
                itemCount: riderData.length + (loadingMore ? 1 : 0),
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemBuilder: (_, index) {
                  if (index >= riderData.length) {
                    return Padding(padding: EdgeInsets.all(16), child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: brandBlue))));
                  }
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: Duration(milliseconds: 250),
                    child: SlideAnimation(verticalOffset: 24, child: FadeInAnimation(child: rideCardWidget(data: riderData[index]))),
                  );
                },
              ),
            ),
    );
  }

  /// The API sends UTC times without a zone marker; mark them so they show in local time.
  String _asUtc(String value) {
    if (value.isEmpty || value.endsWith('Z') || value.contains('+')) return value;
    return value.replaceFirst(' ', 'T') + 'Z';
  }

  String _emptyText() {
    if (widget.status == 'active') return 'No active or upcoming rides';
    if (widget.status == CANCELED) return 'No cancelled rides';
    return 'Your completed rides will show here';
  }

  (String, Color) _statusChip(RiderModel data) {
    final isOutstation = (data.tripType ?? '').startsWith('outstation');
    switch (data.status) {
      case COMPLETED:
        return ('Completed', Color(0xFF1E8E3E));
      case CANCELED:
        return ('Cancelled', Color(0xFFD93025));
      case NEW_RIDE_REQUESTED:
        return (isOutstation && data.driverId == null ? 'Awaiting driver' : 'Finding driver', Color(0xFFE37400));
      case IN_PROGRESS:
        return ('On trip', brandBlue);
      case ARRIVED:
        return ('Driver arrived', brandBlue);
      default:
        return ((data.status ?? '').replaceAll('_', ' ').capitalizeFirstLetter(), brandBlue);
    }
  }

  String _tripTypeLabel(String? type) {
    switch (type) {
      case 'rental':
        return 'Rental';
      case 'outstation_oneway':
        return 'Outstation · One way';
      case 'outstation_round':
        return 'Outstation · Round trip';
      default:
        return 'Local';
    }
  }

  Widget rideCardWidget({required RiderModel data}) {
    final (statusLabel, statusColor) = _statusChip(data);
    final amount = (data.totalAmount is num) ? data.totalAmount as num : num.tryParse('${data.totalAmount}') ?? 0;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (data.status == COMPLETED) {
              launchScreen(context, RideDetailScreen(orderId: data.id!), pageRouteAnimation: PageRouteAnimation.Slide);
            } else if (data.status == NEW_RIDE_REQUESTED && (data.tripType ?? '').startsWith('outstation')) {
              toast('Our team will assign a driver and notify you');
            }
          },
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: brandBlue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                      child: Text(_tripTypeLabel(data.tripType), style: boldTextStyle(size: 11, color: brandBlue)),
                    ),
                    SizedBox(width: 8),
                    Text('#${data.id}', style: secondaryTextStyle(size: 12)),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(statusLabel, style: boldTextStyle(size: 11, color: statusColor)),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                _addressRow(Icons.trip_origin, Color(0xFF1E8E3E), data.startAddress.validate()),
                Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: SizedBox(
                    height: 14,
                    child: DottedLine(direction: Axis.vertical, lineLength: double.infinity, lineThickness: 1, dashLength: 2, dashColor: Colors.grey.shade400),
                  ),
                ),
                _addressRow(Icons.location_on, Color(0xFFD93025), data.endAddress.validate(value: '-')),
                Divider(height: 22, thickness: 0.6),
                Row(
                  children: [
                    Icon(Ionicons.calendar_outline, color: textSecondaryColorGlobal, size: 15),
                    SizedBox(width: 6),
                    Expanded(child: Text(printDate(_asUtc(data.datetime.validate(value: data.createdAt.validate()))), style: secondaryTextStyle(size: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    if (amount > 0) printAmountWidget(amount: amount.toStringAsFixed(digitAfterDecimal), size: 15, color: textPrimaryColorGlobal, weight: FontWeight.bold),
                    if (data.status == COMPLETED) Icon(Icons.chevron_right, color: textSecondaryColorGlobal, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _addressRow(IconData icon, Color color, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        SizedBox(width: 8),
        Expanded(child: Text(text, style: primaryTextStyle(size: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
