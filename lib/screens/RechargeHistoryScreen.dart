import '../manage_imports.dart';

/// Past recharges and bill payments of the rider.
class RechargeHistoryScreen extends StatefulWidget {
  @override
  State<RechargeHistoryScreen> createState() => _RechargeHistoryScreenState();
}

class _RechargeHistoryScreenState extends State<RechargeHistoryScreen> {
  final scrollController = ScrollController();
  List<Map<String, dynamic>> transactions = [];
  bool loading = true;
  bool loadingMore = false;
  bool failed = false;
  int page = 1;
  int totalPages = 1;
  String filter = 'all';

  static const filters = {'all': 'All', 'success': 'Success', 'pending': 'In process', 'failed': 'Failed'};

  @override
  void initState() {
    super.initState();
    _load();
    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200 && !loading && !loadingMore && page < totalPages) {
        _load(nextPage: true);
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({bool nextPage = false}) async {
    final target = nextPage ? page + 1 : 1;
    if (nextPage) setState(() => loadingMore = true);
    try {
      final (list, pages) = await getRechargeHistoryPage(page: target);
      if (!mounted) return;
      setState(() {
        if (!nextPage) transactions = [];
        transactions.addAll(list);
        page = target;
        totalPages = pages;
        failed = false;
      });
    } catch (e) {
      if (!nextPage) failed = true;
      toast(e.toString());
    }
    if (mounted) {
      setState(() {
        loading = false;
        loadingMore = false;
      });
    }
  }

  List<Map<String, dynamic>> get _visible {
    if (filter == 'all') return transactions;
    if (filter == 'failed') return transactions.where((t) => !['success', 'pending'].contains(t['status'])).toList();
    return transactions.where((t) => t['status'] == filter).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'success':
        return Color(0xFF1E9E57);
      case 'pending':
        return Color(0xFFD48A00);
      case 'refund':
        return brandBlue;
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

  IconData _serviceIcon(String service) {
    final s = service.toLowerCase();
    if (s.contains('dth')) return Icons.satellite_alt_rounded;
    if (s.contains('google')) return Icons.shop_rounded;
    if (s.contains('electric')) return Icons.bolt_rounded;
    if (s.contains('water')) return Icons.water_drop_rounded;
    if (s.contains('gas') || s.contains('lpg')) return Icons.local_fire_department_rounded;
    if (s.contains('broadband') || s.contains('landline')) return Icons.wifi_rounded;
    if (s.contains('insurance')) return Icons.health_and_safety_rounded;
    if (s.contains('fastag')) return Icons.toll_rounded;
    return Icons.smartphone_rounded;
  }

  String _date(dynamic raw) {
    final parsed = DateTime.tryParse('$raw');
    if (parsed == null) return '$raw';
    return DateFormat('dd MMM yyyy, hh:mm a').format(parsed.toLocal());
  }

  num _num(dynamic v) => v is num ? v : num.tryParse('$v') ?? 0;

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return Scaffold(
      backgroundColor: Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text('Recharge history', style: boldTextStyle(color: Colors.white)),
        backgroundColor: brandBlue,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.fromLTRB(16, 10, 16, 4),
              children: filters.entries.map((e) {
                final selected = filter == e.key;
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(e.value),
                    selected: selected,
                    showCheckmark: false,
                    selectedColor: brandBlue,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: selected ? brandBlue : Colors.grey.shade300),
                    labelStyle: boldTextStyle(size: 13, color: selected ? Colors.white : textPrimaryColorGlobal),
                    onSelected: (_) => setState(() => filter = e.key),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: loading
                ? Center(child: CircularProgressIndicator(color: brandBlue))
                : RefreshIndicator(
                    color: brandBlue,
                    onRefresh: () => _load(),
                    child: visible.isEmpty
                        ? ListView(
                            physics: AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: 120),
                              Icon(failed ? Icons.cloud_off_rounded : Icons.receipt_long_rounded, size: 56, color: Colors.grey.shade400),
                              SizedBox(height: 12),
                              Text(failed ? 'Could not load. Pull down to retry.' : 'No transactions here yet', style: secondaryTextStyle(), textAlign: TextAlign.center),
                            ],
                          )
                        : ListView.separated(
                            controller: scrollController,
                            physics: AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: visible.length + (loadingMore ? 1 : 0),
                            separatorBuilder: (_, __) => SizedBox(height: 10),
                            itemBuilder: (_, index) {
                              if (index >= visible.length) {
                                return Center(child: Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: brandBlue))));
                              }
                              return _tile(visible[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tile(Map<String, dynamic> t) {
    final status = '${t['status']}';
    final color = _statusColor(status);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDetails(t),
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: brandBlue.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: Icon(_serviceIcon('${t['service_type']}'), color: brandBlue, size: 22),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${t['operator_name']}', style: boldTextStyle(size: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 2),
                    Text('${t['number']}', style: secondaryTextStyle(size: 12)),
                    SizedBox(height: 2),
                    Text(_date(t['created_at']), style: secondaryTextStyle(size: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$currencySymbol${_num(t['total_amount']).toStringAsFixed(2)}', style: boldTextStyle(size: 15)),
                  SizedBox(height: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                    child: Text(_statusLabel(status), style: boldTextStyle(size: 11, color: color)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(Map<String, dynamic> t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => _RechargeDetailSheet(
        transaction: t,
        statusColor: _statusColor,
        statusLabel: _statusLabel,
        date: _date,
        onUpdated: (updated) {
          final i = transactions.indexWhere((x) => x['id'] == updated['id']);
          if (i >= 0) setState(() => transactions[i] = {...transactions[i], ...updated});
        },
      ),
    );
  }
}

class _RechargeDetailSheet extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final Color Function(String) statusColor;
  final String Function(String) statusLabel;
  final String Function(dynamic) date;
  final void Function(Map<String, dynamic>) onUpdated;

  const _RechargeDetailSheet({required this.transaction, required this.statusColor, required this.statusLabel, required this.date, required this.onUpdated});

  @override
  State<_RechargeDetailSheet> createState() => _RechargeDetailSheetState();
}

class _RechargeDetailSheetState extends State<_RechargeDetailSheet> {
  late Map<String, dynamic> t = widget.transaction;
  bool checking = false;

  num _num(dynamic v) => v is num ? v : num.tryParse('$v') ?? 0;

  Future<void> _checkStatus() async {
    if (checking) return;
    setState(() => checking = true);
    try {
      final updated = await getRechargeStatus(clientId: '${t['client_id']}');
      if (!mounted) return;
      setState(() => t = {...t, ...updated});
      widget.onUpdated(t);
      toast(t['status'] == 'pending' ? 'Still in process. Please check again in a few minutes.' : 'Status updated');
    } catch (e) {
      toast(e.toString());
    }
    if (mounted) setState(() => checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final status = '${t['status']}';
    final color = widget.statusColor(status);
    final surcharge = _num(t['surcharge']);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
            SizedBox(height: 18),
            Icon(status == 'success' ? Icons.check_circle_rounded : status == 'pending' ? Icons.schedule_rounded : Icons.error_rounded, color: color, size: 52),
            SizedBox(height: 8),
            Text('$currencySymbol${_num(t['total_amount']).toStringAsFixed(2)}', style: boldTextStyle(size: 24)),
            SizedBox(height: 4),
            Text(widget.statusLabel(status), style: boldTextStyle(color: color)),
            if ('${t['message'] ?? ''}'.isNotEmpty) ...[
              SizedBox(height: 6),
              Text('${t['message']}', style: secondaryTextStyle(size: 12), textAlign: TextAlign.center),
            ],
            SizedBox(height: 18),
            _row('Operator', '${t['operator_name']}'),
            _row('Number', '${t['number']}'),
            _row('Service', '${t['service_type']}'),
            _row('Amount', '$currencySymbol${_num(t['amount']).toStringAsFixed(2)}'),
            if (surcharge > 0) _row('Convenience fee', '$currencySymbol${surcharge.toStringAsFixed(2)}'),
            _row('Transaction ID', '${t['client_id']}', copy: true),
            if ('${t['operator_txn_id'] ?? ''}'.isNotEmpty) _row('Operator ref', '${t['operator_txn_id']}', copy: true),
            _row('Date', widget.date(t['created_at'])),
            if (status != 'failure' && status != 'refund') ...[
              SizedBox(height: 16),
              ReceiptActions(data: ReceiptData.fromRecharge(t)),
            ],
            if (status == 'pending') ...[
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: brandBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: checking ? null : _checkStatus,
                  icon: checking ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(Icons.refresh_rounded),
                  label: Text(checking ? 'Checking...' : 'Check status'),
                ),
              ),
            ],
            if (status != 'success' && status != 'pending') ...[
              SizedBox(height: 12),
              Text('The amount was returned to your wallet.', style: secondaryTextStyle(size: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool copy = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: secondaryTextStyle(size: 13)),
          SizedBox(width: 12),
          Expanded(child: Text(value, style: boldTextStyle(size: 13), textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis)),
          if (copy)
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                toast('Copied');
              },
              child: Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.copy_rounded, size: 16, color: brandBlue)),
            ),
        ],
      ),
    );
  }
}
