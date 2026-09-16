import '../manage_imports.dart';

/// Bill payment: every non-mobile service that has operators (electricity, DTH, water, ...).
class BillPaymentScreen extends StatefulWidget {
  @override
  State<BillPaymentScreen> createState() => _BillPaymentScreenState();
}

class _BillPaymentScreenState extends State<BillPaymentScreen> {
  final searchController = TextEditingController();
  List<Map<String, dynamic>> services = [];
  bool loading = true;

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
    try {
      final list = await getRechargeServices();
      if (mounted) setState(() => services = list.where((s) => s['is_recharge'] != true).toList());
    } catch (e) {
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
    final visible = query.isEmpty
        ? services
        : services.where((s) => s['service_type'].toString().toLowerCase().contains(query)).toList();

    return Scaffold(
      backgroundColor: Color(0xFFF4F6F9),
      appBar: AppBar(title: Text('Bill payment')),
      body: loading
          ? Center(child: CircularProgressIndicator(color: brandBlue))
          : services.isEmpty
              ? Center(child: Text('No bill payment services available yet.', style: secondaryTextStyle()))
              : Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: TextField(
                        controller: searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search a service',
                          prefixIcon: Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                        ),
                      ),
                    ),
                    Expanded(
                      child: visible.isEmpty
                          ? Center(child: Text('No service matches "${searchController.text.trim()}"', style: secondaryTextStyle()))
                          : GridView.count(
                              padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
                              crossAxisCount: 4,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 0.78,
                              children: visible.map((service) {
                                final name = service['service_type'].toString();
                                final count = (service['operator_count'] as num?)?.toInt() ?? 0;
                                final (icon, colour) = _styleFor(name);

                                return Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    splashColor: colour.withValues(alpha: 0.12),
                                    highlightColor: colour.withValues(alpha: 0.06),
                                    onTap: () => launchScreen(context, RechargeScreen(title: name, serviceTypes: [name]),
                                        pageRouteAnimation: PageRouteAnimation.Slide),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          height: 42,
                                          width: 42,
                                          decoration: BoxDecoration(color: colour.withValues(alpha: 0.12), shape: BoxShape.circle),
                                          child: Icon(icon, color: colour, size: 21),
                                        ),
                                        SizedBox(height: 6),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 6),
                                          child: Text(name,
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: boldTextStyle(size: 11)),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
    );
  }
}
