import '../manage_imports.dart';
import '../utils/BrandTheme.dart';

class NotificationScreen extends StatefulWidget {
  @override
  NotificationScreenState createState() => NotificationScreenState();
}

class NotificationScreenState extends State<NotificationScreen>
    with TickerProviderStateMixin {
  ScrollController scrollController = ScrollController();
  int currentPage = 1;

  bool mIsLastPage = false;
  List<NotificationData> notificationData = [];

  @override
  void initState() {
    super.initState();
    init();
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        if (!mIsLastPage) {
          appStore.setLoading(true);

          currentPage++;
          setState(() {});

          init();
        }
      }
    });
    afterBuildCreated(() => appStore.setLoading(true));
  }

  void init() async {
    getNotification(page: currentPage).then((value) {
      appStore.setLoading(false);
      mIsLastPage = value.notificationData!.length < currentPage;
      if (currentPage == 1) {
        notificationData.clear();
      }
      notificationData.addAll(value.notificationData ?? []);
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);
      log(error);
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Future<void> _refresh() async {
    currentPage = 1;
    mIsLastPage = false;
    init();
  }

  (IconData, Color) _styleFor(String? type, String? subject) {
    final value = '${type ?? ''} ${subject ?? ''}'.toLowerCase();
    if (value.contains('complete')) return (Icons.check_circle_rounded, Color(0xFF1E9E57));
    if (value.contains('cancel')) return (Icons.cancel_rounded, BrandTokens.danger);
    if (value.contains('wallet') || value.contains('topup')) return (Icons.account_balance_wallet_rounded, BrandTokens.blue);
    if (value.contains('complain')) return (Icons.support_agent_rounded, Color(0xFF7048E8));
    if (value.contains('arriv') || value.contains('accept')) return (Icons.local_taxi_rounded, BrandTokens.blue);
    return (Icons.notifications_rounded, BrandTokens.blue);
  }

  /// "5 min ago" style label from the server timestamp (sent as UTC without a zone marker).
  String _ago(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final value = raw.trim();
    final hasZone = value.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(value);
    final parsed = DateTime.tryParse(hasZone ? value : value.replaceFirst(' ', 'T') + 'Z')?.toLocal();
    if (parsed == null) return value;
    final diff = DateTime.now().difference(parsed);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return DateFormat('dd MMM yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandTokens.page,
      appBar: AppBar(title: Text(language.notification, style: boldTextStyle(color: Colors.white))),
      body: Observer(builder: (context) {
        if (notificationData.isEmpty) {
          if (appStore.isLoading) return Center(child: CircularProgressIndicator(color: brandBlue));
          return RefreshIndicator(
            color: brandBlue,
            onRefresh: _refresh,
            child: ListView(
              physics: AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: 120),
                Icon(Icons.notifications_off_rounded, size: 56, color: Colors.grey.shade400),
                SizedBox(height: 12),
                Text('No notifications yet', textAlign: TextAlign.center, style: boldTextStyle(size: 16)),
                SizedBox(height: 4),
                Text('Ride updates and wallet alerts will appear here.', textAlign: TextAlign.center, style: secondaryTextStyle(size: 13)),
              ],
            ),
          );
        }

        return Stack(
          children: [
            RefreshIndicator(
              color: brandBlue,
              onRefresh: _refresh,
              child: ListView.builder(
                controller: scrollController,
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 14, 16, 24),
                itemCount: notificationData.length,
                itemBuilder: (_, index) {
                  final data = notificationData[index];
                  final unread = data.isRead == 0;
                  final type = data.data?.type;
                  final subject = data.data?.subject;
                  final (icon, colour) = _styleFor(type, subject);
                  final rideId = (type != null && type != 'push_notification') ? data.data?.id : null;

                  return Container(
                    margin: EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: unread ? colour.withValues(alpha: 0.35) : BrandTokens.line),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          if (type == COMPLAIN_COMMENT && data.data?.complaintId != null) {
                            launchScreen(context, ComplaintListScreen(complaint: data.data!.complaintId!), pageRouteAnimation: PageRouteAnimation.Slide);
                          } else if (data.data?.id != null && (subject ?? '').toLowerCase().contains('complete')) {
                            launchScreen(context, RideDetailScreen(orderId: data.data!.id!), pageRouteAnimation: PageRouteAnimation.Slide);
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(color: colour.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                                child: Icon(icon, color: colour, size: 21),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            rideId != null ? '${language.rideId} #$rideId · ${subject ?? ''}' : '${subject ?? ''}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: boldTextStyle(size: 14),
                                          ),
                                        ),
                                        if (unread)
                                          Container(width: 8, height: 8, margin: EdgeInsets.only(left: 6), decoration: BoxDecoration(color: colour, shape: BoxShape.circle)),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text('${data.data?.message ?? ''}', style: primaryTextStyle(size: 13)),
                                    SizedBox(height: 6),
                                    Text(_ago(data.createdAt), style: secondaryTextStyle(size: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (appStore.isLoading)
              Positioned(left: 0, right: 0, bottom: 16, child: Center(child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.5, color: brandBlue)))),
          ],
        );
      }),
    );
  }
}
