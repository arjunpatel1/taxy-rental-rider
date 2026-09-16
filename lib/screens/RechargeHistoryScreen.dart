import '../manage_imports.dart';

/// Past recharges and bill payments of the rider.
class RechargeHistoryScreen extends StatefulWidget {
  @override
  State<RechargeHistoryScreen> createState() => _RechargeHistoryScreenState();
}

class _RechargeHistoryScreenState extends State<RechargeHistoryScreen> {
  List<Map<String, dynamic>> transactions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await getRechargeHistory(page: 1);
      if (mounted) setState(() => transactions = list);
    } catch (e) {
      toast(e.toString());
    }
    if (mounted) setState(() => loading = false);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'success':
        return Color(0xFF1E9E57);
      case 'pending':
        return Color(0xFFD48A00);
      default:
        return Color(0xFFD93025);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'success':
        return 'Success';
      case 'pending':
        return 'In process';
      case 'refund':
        return 'Refunded';
      default:
        return 'Failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text('Recharge history', style: boldTextStyle(color: Colors.white)),
        backgroundColor: brandBlue,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: brandBlue))
          : transactions.isEmpty
              ? Center(child: Text('No recharges yet.', style: secondaryTextStyle()))
              : ListView.separated(
                  padding: EdgeInsets.all(16),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final transaction = transactions[index];
                    final status = transaction['status'].toString();
                    return Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${transaction['operator_name']}', style: boldTextStyle(size: 15)),
                                SizedBox(height: 2),
                                Text('${transaction['number']} · ${transaction['service_type']}', style: secondaryTextStyle(size: 12)),
                                SizedBox(height: 4),
                                Text('${transaction['created_at']}'.split('T').first, style: secondaryTextStyle(size: 11)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('$currencySymbol${(transaction['total_amount'] as num).toStringAsFixed(2)}', style: boldTextStyle(size: 15)),
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: _statusColor(status).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                child: Text(_statusLabel(status), style: boldTextStyle(size: 11, color: _statusColor(status))),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
