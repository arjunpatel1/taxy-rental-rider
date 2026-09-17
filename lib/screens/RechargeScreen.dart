import '../manage_imports.dart';

/// Mobile recharge / bill payment: pick an operator, enter the number and amount,
/// pay from the wallet. The surcharge set by admin is shown before paying.
class RechargeScreen extends StatefulWidget {
  final String title;
  final List<String> serviceTypes;

  RechargeScreen({required this.title, required this.serviceTypes});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  late String selectedService = widget.serviceTypes.first;
  List<Map<String, dynamic>> operators = [];
  Map<String, dynamic>? selectedOperator;
  final numberController = TextEditingController();
  final amountController = TextEditingController();
  bool loadingOperators = false;
  bool paying = false;
  bool busy = false;
  num walletBalance = 0;
  String? circleCode;
  String? circleName;
  bool amountLocked = false;
  List<Map<String, String>> billDetails = [];

  @override
  void initState() {
    super.initState();
    _loadOperators();
    _loadWallet();
  }

  @override
  void dispose() {
    numberController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> _loadWallet() async {
    try {
      final wallet = await getWalletData();
      if (mounted) setState(() => walletBalance = wallet.walletData?.totalAmount ?? 0);
    } catch (e) {
      log('wallet: $e');
    }
  }

  Future<void> _loadOperators() async {
    setState(() {
      loadingOperators = true;
      operators = [];
      selectedOperator = null;
    });
    try {
      amountLocked = false;
      billDetails = [];
      final list = await getRechargeOperators(serviceType: selectedService);
      if (mounted) setState(() => operators = list);
    } catch (e) {
      toast(e.toString());
    }
    if (mounted) setState(() => loadingOperators = false);
  }

  num get _amount => num.tryParse(amountController.text.trim()) ?? 0;

  num get _surcharge {
    final operator = selectedOperator;
    if (operator == null) return 0;
    final value = (operator['surcharge_value'] as num?) ?? 0;
    return operator['surcharge_type'] == 'percentage' ? (_amount * value / 100) : value;
  }

  /// Looks up operator + circle from the typed mobile number (prepaid / postpaid).
  Future<void> _detectOperator() async {
    final number = numberController.text.trim();
    if (number.length < 10 || !(selectedService == 'Prepaid' || selectedService == 'Postpaid')) return;

    try {
      final detected = await detectRechargeOperator(number: number, serviceType: selectedService);
      if (detected == null || !mounted) return;
      setState(() {
        circleCode = (detected['circle_code'] ?? '').toString();
        circleName = (detected['circle'] ?? '').toString();
        if (detected['operator_id'] != null) {
          selectedOperator = operators.firstWhere(
            (operator) => operator['id'] == detected['operator_id'],
            orElse: () => selectedOperator ?? <String, dynamic>{},
          );
          if (selectedOperator!.isEmpty) selectedOperator = null;
        }
      });
    } catch (e) {
      log('detect operator: $e');
    }
  }

  /// Operator list with a search box - the lists run to 200+ entries for some services.
  Future<void> _pickOperator() async {
    if (operators.isEmpty) {
      toast('No operators available yet');
      return;
    }

    final searchController = TextEditingController();
    final chosen = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final query = searchController.text.trim().toLowerCase();
          final filtered = query.isEmpty
              ? operators
              : operators.where((o) => o['name'].toString().toLowerCase().contains(query)).toList();

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.8,
              builder: (_, controller) => Column(
                children: [
                  SizedBox(height: 12),
                  Container(height: 4, width: 44, decoration: BoxDecoration(color: dividerColor, borderRadius: BorderRadius.circular(4))),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Row(
                      children: [
                        Text('Choose $selectedService operator', style: boldTextStyle(size: 17)),
                        Spacer(),
                        Text('${filtered.length}', style: secondaryTextStyle(size: 13)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchController,
                      autofocus: false,
                      onChanged: (_) => setSheetState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search operator',
                        prefixIcon: Icon(Icons.search_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(child: Text('No operator matches "${searchController.text.trim()}"', style: secondaryTextStyle()))
                        : ListView.separated(
                            controller: controller,
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: dividerColor.withValues(alpha: 0.5)),
                            itemBuilder: (_, index) {
                              final operator = filtered[index];
                              final selected = selectedOperator?['id'] == operator['id'];
                              return ListTile(
                                onTap: () => Navigator.pop(sheetContext, operator),
                                leading: CircleAvatar(
                                  backgroundColor: brandBlue.withValues(alpha: 0.1),
                                  child: Text(operator['name'].toString().characters.first.toUpperCase(),
                                      style: boldTextStyle(size: 15, color: brandBlue)),
                                ),
                                title: Text(operator['name'].toString(), style: primaryTextStyle(size: 15)),
                                subtitle: operator['has_plans'] == true
                                    ? Text('Plans available', style: secondaryTextStyle(size: 11))
                                    : (operator['has_bill_fetch'] == true ? Text('Bill fetch available', style: secondaryTextStyle(size: 11)) : null),
                                trailing: selected ? Icon(Icons.check_circle_rounded, color: brandBlue) : null,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (chosen != null) {
      setState(() {
        selectedOperator = chosen;
        amountLocked = false;
        billDetails = [];
      });
    }
  }

  Future<void> _showPlans({bool offers = false}) async {
    if (selectedOperator == null) return toast('Select an operator first');
    if (offers && numberController.text.trim().length < 10) return toast('Enter the mobile number first');

    setState(() => busy = true);
    List<Map<String, dynamic>> list = [];
    try {
      list = offers
          ? await getRechargeOffers(operatorId: selectedOperator!['id'], number: numberController.text.trim())
          : await getRechargePlans(operatorId: selectedOperator!['id'], circle: circleCode);
    } catch (e) {
      toast(e.toString());
    }
    if (!mounted) return;
    setState(() => busy = false);

    if (list.isEmpty) {
      toast(offers ? 'No offers found for this number' : 'No plans available');
      return;
    }

    // plan types come back grouped (FULLTT, TOPUP, 3G/4G, ...) - show them as filter chips
    final groups = <String>{for (final plan in list) (plan['group'] ?? '').toString()}..removeWhere((g) => g.isEmpty);
    final searchController = TextEditingController();
    String activeGroup = 'All';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final query = searchController.text.trim().toLowerCase();
          final visible = list.where((plan) {
            final inGroup = activeGroup == 'All' || (plan['group'] ?? '').toString() == activeGroup;
            if (!inGroup) return false;
            if (query.isEmpty) return true;
            return '${plan['amount']} ${plan['validity']} ${plan['data']} ${plan['description']}'.toLowerCase().contains(query);
          }).toList();

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              builder: (_, controller) => Column(
                children: [
                  SizedBox(height: 12),
                  Container(height: 4, width: 44, decoration: BoxDecoration(color: dividerColor, borderRadius: BorderRadius.circular(4))),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(
                      children: [
                        Icon(offers ? Icons.local_offer_rounded : Icons.list_alt_rounded, color: brandBlue, size: 20),
                        SizedBox(width: 8),
                        Text(offers ? 'Special offers' : 'Browse plans', style: boldTextStyle(size: 18)),
                        Spacer(),
                        if (!offers && circleName != null && circleName!.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Color(0xFFE3ECFF), borderRadius: BorderRadius.circular(20)),
                            child: Text(circleName!, style: boldTextStyle(size: 11, color: brandBlue)),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchController,
                      onChanged: (_) => setSheetState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search amount, data or validity',
                        prefixIcon: Icon(Icons.search_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                  ),
                  if (groups.length > 1) ...[
                    SizedBox(height: 10),
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        children: ['All', ...groups].map((group) {
                          final selected = activeGroup == group;
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(group, style: boldTextStyle(size: 12, color: selected ? Colors.white : brandBlack)),
                              selected: selected,
                              showCheckmark: false,
                              selectedColor: brandBlue,
                              backgroundColor: Color(0xFFF1F4F9),
                              side: BorderSide(color: selected ? brandBlue : Colors.transparent),
                              onSelected: (_) => setSheetState(() => activeGroup = group),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  SizedBox(height: 6),
                  Expanded(
                    child: visible.isEmpty
                        ? Center(child: Text('Nothing matches that search', style: secondaryTextStyle()))
                        : ListView.builder(
                            controller: controller,
                            padding: EdgeInsets.fromLTRB(12, 4, 12, 16),
                            itemCount: visible.length,
                            itemBuilder: (_, index) {
                              final plan = visible[index];
                              final amount = (plan['amount'] as num?) ?? 0;
                              final validity = (plan['validity'] ?? '').toString();
                              final data = (plan['data'] ?? '').toString();

                              return Card(
                                elevation: 0,
                                color: Colors.white,
                                margin: EdgeInsets.symmetric(vertical: 5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(color: dividerColor.withValues(alpha: 0.6)),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    amountController.text = amount.toStringAsFixed(0);
                                    Navigator.pop(sheetContext);
                                    setState(() {});
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text('$currencySymbol${amount.toStringAsFixed(0)}', style: boldTextStyle(size: 20, color: brandBlue)),
                                            SizedBox(width: 10),
                                            if (validity.isNotEmpty && validity != 'N/A')
                                              _planChip(Icons.calendar_today_rounded, validity),
                                            if (data.isNotEmpty) ...[SizedBox(width: 6), _planChip(Icons.data_usage_rounded, data)],
                                            Spacer(),
                                            Icon(Icons.chevron_right_rounded, color: textSecondaryColor),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          (plan['description'] ?? '').toString(),
                                          style: secondaryTextStyle(size: 12),
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _planChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textSecondaryColor),
          SizedBox(width: 4),
          Text(label, style: boldTextStyle(size: 11, color: brandBlack)),
        ],
      ),
    );
  }

  Future<void> _fetchBill() async {
    if (busy) return;
    if (selectedOperator == null) return toast('Select an operator first');
    if (numberController.text.trim().isEmpty) return toast('Enter the number first');

    setState(() => busy = true);
    try {
      final bill = await fetchRechargeBill({'operator_id': selectedOperator!['id'], 'number': numberController.text.trim()});
      if (bill == null) {
        toast('Could not fetch the bill');
      } else {
        amountController.text = ((bill['amount'] as num?) ?? 0).toStringAsFixed(2);
        amountLocked = bill['amount_locked'] == true;
        billDetails = ((bill['details'] ?? []) as List)
            .map((row) => {'label': (row['label'] ?? '').toString(), 'value': (row['value'] ?? '').toString()})
            .toList();
      }
    } catch (e) {
      toast(e.toString());
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _pay() async {
    if (paying || busy) return;
    if (selectedOperator == null) return toast('Select an operator');
    if (numberController.text.trim().isEmpty) return toast('Enter the number');
    if (_amount <= 0) return toast('Enter a valid amount');

    final total = _amount + _surcharge;
    if (total > walletBalance) return toast('Your wallet balance is not enough. Please add money first.');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Confirm payment', style: boldTextStyle()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryRow('Operator', selectedOperator!['name'].toString()),
            _summaryRow('Number', numberController.text.trim()),
            _summaryRow('Amount', '$currencySymbol${_amount.toStringAsFixed(2)}'),
            if (_surcharge > 0) _summaryRow('Convenience fee', '$currencySymbol${_surcharge.toStringAsFixed(2)}'),
            Divider(),
            _summaryRow('Payable from wallet', '$currencySymbol${total.toStringAsFixed(2)}', bold: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: brandBlue),
            child: Text('Pay', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => paying = true);
    try {
      final result = await saveRecharge({
        'operator_id': selectedOperator!['id'],
        'number': numberController.text.trim(),
        'amount': _amount,
      });
      final data = Map<String, dynamic>.from(result['data'] ?? {});
      walletBalance = (result['wallet_balance'] as num?) ?? walletBalance;
      numberController.clear();
      amountController.clear();
      if (mounted) {
        setState(() => paying = false);
        _showResult(data, result['message']?.toString() ?? '');
      }
    } catch (e) {
      if (mounted) setState(() => paying = false);
      toast(e.toString());
    }
  }

  void _showResult(Map<String, dynamic> data, String message) {
    final status = (data['status'] ?? 'pending').toString();
    final result = TransactionResultScreen.fromStatus(status);
    final total = (data['total_amount'] as num?) ?? (data['amount'] as num?) ?? 0;
    final title = result == TransactionResult.success
        ? 'Payment successful'
        : result == TransactionResult.pending
            ? 'Payment in process'
            : 'Payment failed';
    final subtitle = result == TransactionResult.pending
        ? 'The operator is confirming it. We will update the status; if it fails, the money comes back to your wallet.'
        : result == TransactionResult.failed
            ? (message.isNotEmpty ? '$message\nThe amount has been returned to your wallet.' : 'The amount has been returned to your wallet.')
            : null;
    TransactionResultScreen.show(
      context,
      TransactionResultScreen(
        result: result,
        title: title,
        subtitle: subtitle,
        amount: '$currencySymbol${total.toStringAsFixed(total % 1 == 0 ? 0 : 2)}',
        details: [
          if (data['operator_name'] != null) MapEntry('Operator', '${data['operator_name']}'),
          MapEntry('Number', '${data['number'] ?? ''}'),
          if (((data['surcharge'] as num?) ?? 0) > 0) MapEntry('Convenience fee', '$currencySymbol${(data['surcharge'] as num).toStringAsFixed(2)}'),
          if (data['operator_txn_id'] != null && '${data['operator_txn_id']}'.isNotEmpty) MapEntry('Operator ref', '${data['operator_txn_id']}'),
          if (data['client_id'] != null) MapEntry('Transaction ID', '${data['client_id']}'),
        ],
        receipt: ReceiptData.fromRecharge(data),
        secondaryText: 'View history',
        onSecondary: () => launchScreen(context, RechargeHistoryScreen(), pageRouteAnimation: PageRouteAnimation.Slide),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: secondaryTextStyle(size: 13)),
          Text(value, style: bold ? boldTextStyle(size: 15) : primaryTextStyle(size: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _amount + _surcharge;

    return Scaffold(
      backgroundColor: Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(widget.title, style: boldTextStyle(color: Colors.white)),
        backgroundColor: brandBlue,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet_rounded, color: brandBlue),
                  SizedBox(width: 10),
                  Text('Wallet balance', style: primaryTextStyle(size: 14)),
                  Spacer(),
                  Text('$currencySymbol${walletBalance.toStringAsFixed(2)}', style: boldTextStyle(size: 16)),
                ],
              ),
            ),
            if (widget.serviceTypes.length > 1) ...[
              SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: widget.serviceTypes.map((type) {
                  final selected = selectedService == type;
                  return ChoiceChip(
                    label: Text(type, style: boldTextStyle(size: 13, color: selected ? Colors.white : brandBlack)),
                    selected: selected,
                    showCheckmark: false,
                    selectedColor: brandBlue,
                    backgroundColor: Colors.white,
                    onSelected: (_) {
                      selectedService = type;
                      _loadOperators();
                    },
                  );
                }).toList(),
              ),
            ],
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Operator', style: boldTextStyle(size: 14)),
                  SizedBox(height: 8),
                  if (loadingOperators)
                    Padding(padding: EdgeInsets.all(8), child: SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)))
                  else if (operators.isEmpty)
                    Text('No operators available yet.', style: secondaryTextStyle())
                  else
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _pickOperator,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: selectedOperator == null ? dividerColor : brandBlue),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.storefront_rounded, size: 20, color: selectedOperator == null ? textSecondaryColor : brandBlue),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  selectedOperator?['name']?.toString() ?? 'Select operator',
                                  style: selectedOperator == null ? secondaryTextStyle(size: 14) : boldTextStyle(size: 15),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.keyboard_arrow_down_rounded, color: textSecondaryColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: 16),
                  Text('Number', style: boldTextStyle(size: 14)),
                  SizedBox(height: 8),
                  TextField(
                    controller: numberController,
                    keyboardType: TextInputType.text,
                    onChanged: (value) {
                      if (value.trim().length == 10) _detectOperator();
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: selectedOperator?['number_label']?.toString().isNotEmpty == true
                          ? selectedOperator!['number_label'].toString()
                          : (selectedService == 'Prepaid' || selectedService == 'Postpaid' ? 'Mobile number' : 'Consumer / account number'),
                      prefixIcon: Icon(Icons.pin_rounded),
                    ),
                  ),
                  if (circleName != null && circleName!.isNotEmpty) ...[
                    SizedBox(height: 6),
                    Text('Circle: $circleName', style: secondaryTextStyle(size: 12)),
                  ],
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (selectedOperator?['has_plans'] == true)
                        OutlinedButton.icon(
                          onPressed: busy ? null : () => _showPlans(),
                          icon: Icon(Icons.list_alt_rounded, size: 18),
                          label: Text('Browse plans'),
                        ),
                      if (selectedOperator?['has_plans'] == true && selectedService == 'Prepaid')
                        OutlinedButton.icon(
                          onPressed: busy ? null : () => _showPlans(offers: true),
                          icon: Icon(Icons.local_offer_rounded, size: 18),
                          label: Text('Offers'),
                        ),
                      if (selectedOperator?['has_bill_fetch'] == true)
                        OutlinedButton.icon(
                          onPressed: busy ? null : _fetchBill,
                          icon: Icon(Icons.receipt_long_rounded, size: 18),
                          label: Text('Fetch bill'),
                        ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text('Amount', style: boldTextStyle(size: 14)),
                  SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    readOnly: amountLocked,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '0',
                      prefixText: '$currencySymbol ',
                      helperText: amountLocked ? 'Amount is fixed by the biller' : null,
                    ),
                  ),
                  if (billDetails.isNotEmpty) ...[
                    SizedBox(height: 12),
                    ...billDetails.map((row) => _summaryRow(row['label']!, row['value']!)),
                  ],
                  if (_amount > 0 && selectedOperator != null) ...[
                    SizedBox(height: 14),
                    _summaryRow('Amount', '$currencySymbol${_amount.toStringAsFixed(2)}'),
                    if (_surcharge > 0) _summaryRow('Convenience fee', '$currencySymbol${_surcharge.toStringAsFixed(2)}'),
                    _summaryRow('Total payable', '$currencySymbol${total.toStringAsFixed(2)}', bold: true),
                  ],
                ],
              ),
            ),
            SizedBox(height: 20),
            AppButtonWidget(
              width: MediaQuery.of(context).size.width,
              color: brandBlue,
              text: paying ? 'Please wait...' : 'Pay from wallet',
              textStyle: boldTextStyle(color: Colors.white),
              onTap: paying ? null : _pay,
            ),
            SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => launchScreen(context, RechargeHistoryScreen(), pageRouteAnimation: PageRouteAnimation.Slide),
                child: Text('View recharge history', style: boldTextStyle(color: brandBlue, size: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
