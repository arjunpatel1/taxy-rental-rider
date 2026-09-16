import '../manage_imports.dart';

/// Bill payment: every non-mobile service that has operators (electricity, DTH, water, ...).
class BillPaymentScreen extends StatefulWidget {
  @override
  State<BillPaymentScreen> createState() => _BillPaymentScreenState();
}

class _BillPaymentScreenState extends State<BillPaymentScreen> {
  List<Map<String, dynamic>> services = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
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

  IconData _iconFor(String service) {
    final name = service.toLowerCase();
    if (name.contains('electric')) return Icons.bolt_rounded;
    if (name.contains('gas') || name.contains('cylinder')) return Icons.local_fire_department_rounded;
    if (name.contains('water')) return Icons.water_drop_rounded;
    if (name.contains('dth') || name.contains('cable')) return Icons.satellite_alt_rounded;
    if (name.contains('broadband') || name.contains('landline')) return Icons.wifi_rounded;
    if (name.contains('insurance')) return Icons.verified_user_rounded;
    if (name.contains('loan')) return Icons.account_balance_rounded;
    if (name.contains('fastag')) return Icons.directions_car_filled_rounded;
    if (name.contains('metro')) return Icons.train_rounded;
    if (name.contains('challan')) return Icons.receipt_long_rounded;
    if (name.contains('municipal') || name.contains('tax')) return Icons.location_city_rounded;
    if (name.contains('credit')) return Icons.credit_card_rounded;
    return Icons.receipt_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text('Bill payment', style: boldTextStyle(color: Colors.white)),
        backgroundColor: brandBlue,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: brandBlue))
          : services.isEmpty
              ? Center(child: Text('No bill payment services available yet.', style: secondaryTextStyle()))
              : GridView.count(
                  padding: EdgeInsets.all(16),
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.9,
                  children: services.map((service) {
                    final name = service['service_type'].toString();
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => launchScreen(context, RechargeScreen(title: name, serviceTypes: [name]), pageRouteAnimation: PageRouteAnimation.Slide),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(14)),
                              child: Icon(_iconFor(name), color: brandBlue, size: 24),
                            ),
                            SizedBox(height: 8),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Text(name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: boldTextStyle(size: 12)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}
