import '../manage_imports.dart';
import '../utils/BrandTheme.dart';

/// Bill payment: every non-mobile service that has operators (electricity, DTH, water, ...).
class BillPaymentScreen extends StatefulWidget {
  @override
  State<BillPaymentScreen> createState() => _BillPaymentScreenState();
}

class _BillPaymentScreenState extends State<BillPaymentScreen> {
  final searchController = TextEditingController();
  List<Map<String, dynamic>> services = [];
  bool loading = true;
  bool failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      final list = await getRechargeServices();
      if (mounted) setState(() => services = list.where((s) => s['is_recharge'] != true).toList());
    } catch (e) {
      if (mounted) setState(() => failed = true);
      toast(e.toString());
    }
    if (mounted) setState(() => loading = false);
  }

  /// Icon + colour per biller category, so the grid reads at a glance.
  (IconData, Color) _styleFor(String service) {
    final name = service.toLowerCase();
    if (name.contains('electric')) return (Icons.bolt_rounded, Color(0xFFF5A524));
    if (name.contains('cylinder')) return (Icons.propane_tank_rounded, Color(0xFFE8590C));
    if (name.contains('gas')) return (Icons.local_fire_department_rounded, Color(0xFFE8590C));
    if (name.contains('water')) return (Icons.water_drop_rounded, Color(0xFF1E90F0));
    if (name.contains('dth connection')) return (Icons.add_to_queue_rounded, Color(0xFF7048E8));
    if (name.contains('dth') || name.contains('cable')) return (Icons.satellite_alt_rounded, Color(0xFF7048E8));
    if (name.contains('broadband')) return (Icons.router_rounded, Color(0xFF0CA678));
    if (name.contains('landline')) return (Icons.phone_in_talk_rounded, Color(0xFF0CA678));
    if (name.contains('insurance')) return (Icons.verified_user_rounded, Color(0xFF2F9E44));
    if (name.contains('loan')) return (Icons.account_balance_rounded, Color(0xFF1C7ED6));
    if (name.contains('fastag')) return (Icons.directions_car_filled_rounded, Color(0xFF364FC7));
    if (name.contains('metro')) return (Icons.train_rounded, Color(0xFF0B7285));
    if (name.contains('challan')) return (Icons.gavel_rounded, Color(0xFFC92A2A));
    if (name.contains('municipal') || name.contains('tax')) return (Icons.location_city_rounded, Color(0xFF5F3DC4));
    if (name.contains('credit')) return (Icons.credit_card_rounded, Color(0xFFD6336C));
    if (name.contains('dmr')) return (Icons.swap_horiz_rounded, Color(0xFF495057));
    return (Icons.receipt_long_rounded, brandBlue);
  }

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final visible = query.isEmpty ? services : services.where((s) => s['service_type'].toString().toLowerCase().contains(query)).toList();
    final showSearch = services.length > 6;

    return Scaffold(
      backgroundColor: BrandTokens.page,
      appBar: AppBar(title: Text('Bill payment')),
      body: loading
          ? Center(child: CircularProgressIndicator(color: brandBlue))
          : failed
              ? _message(Icons.cloud_off_rounded, 'Could not load services', 'Please check your internet and try again.', onRetry: _load)
              : services.isEmpty
                  ? _message(Icons.receipt_long_rounded, 'No bill services yet', 'Bill payment services will appear here once they are enabled.', onRetry: _load)
                  : RefreshIndicator(
                      color: brandBlue,
                      onRefresh: _load,
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(16, 14, 16, 24),
                        children: [
                          if (showSearch) ...[
                            TextField(
                              controller: searchController,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Search a service',
                                prefixIcon: Icon(Icons.search_rounded),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                              ),
                            ),
                            SizedBox(height: 14),
                          ],
                          Text('Pay your bills', style: boldTextStyle(size: 16)),
                          SizedBox(height: 2),
                          Text('Paid straight from your S Taxi wallet', style: secondaryTextStyle(size: 12)),
                          SizedBox(height: 12),
                          if (visible.isEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: Text('No service matches "${searchController.text.trim()}"', textAlign: TextAlign.center, style: secondaryTextStyle()),
                            ),
                          ...visible.map((service) {
                            final name = service['service_type'].toString();
                            final count = (service['operator_count'] as num?)?.toInt() ?? 0;
                            final (icon, colour) = _styleFor(name);

                            return Container(
                              margin: EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: BrandTokens.line)),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  splashColor: colour.withValues(alpha: 0.12),
                                  onTap: () => launchScreen(context, RechargeScreen(title: name, serviceTypes: [name]), pageRouteAnimation: PageRouteAnimation.Slide),
                                  child: Padding(
                                    padding: EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        Container(
                                          height: 46,
                                          width: 46,
                                          decoration: BoxDecoration(color: colour.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                                          child: Icon(icon, color: colour, size: 24),
                                        ),
                                        SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(name, style: boldTextStyle(size: 15)),
                                              SizedBox(height: 2),
                                              Text(count == 1 ? '1 biller' : '$count billers', style: secondaryTextStyle(size: 12)),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.chevron_right_rounded, color: BrandTokens.inkSoft),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
    );
  }

  Widget _message(IconData icon, String title, String subtitle, {VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade400),
            SizedBox(height: 14),
            Text(title, style: boldTextStyle(size: 16)),
            SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: secondaryTextStyle(size: 13)),
            if (onRetry != null) ...[
              SizedBox(height: 18),
              OutlinedButton.icon(onPressed: onRetry, icon: Icon(Icons.refresh_rounded, size: 18), label: Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}
