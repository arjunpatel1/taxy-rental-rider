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

    if (list.isEmpty) return toast(offers ? 'No offers found for this number' : 'No plans available');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(offers ? 'Special offers' : 'Browse plans', style: boldTextStyle(size: 18)),
                  Spacer(),
                  if (!offers && circleName != null && circleName!.isNotEmpty) Text(circleName!, style: secondaryTextStyle(size: 12)),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: list.length,
                separatorBuilder: (_, __) => Divider(height: 18),
                itemBuilder: (_, index) {
                  final plan = list[index];
                  final amount = (plan['amount'] as num?) ?? 0;
                  return InkWell(
                    onTap: () {
                      amountController.text = amount.toStringAsFixed(0);
                      Navigator.pop(context);
                      setState(() {});
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Color(0xFFE3ECFF), borderRadius: BorderRadius.circular(8)),
                          child: Text('$currencySymbol${amount.toStringAsFixed(0)}', style: boldTextStyle(size: 14, color: brandBlue)),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((plan['validity'] ?? '').toString().isNotEmpty)
                                Text('Validity: ${plan['validity']}', style: boldTextStyle(size: 13)),
                              Text('${plan['description'] ?? ''}', style: secondaryTextStyle(size: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchBill() async {
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
    final color = status == 'success' ? Color(0xFF1E9E57) : (status == 'pending' ? Color(0xFFD48A00) : Color(0xFFD93025));
    final icon = status == 'success' ? Icons.check_circle_rounded : (status == 'pending' ? Icons.hourglass_top_rounded : Icons.cancel_rounded);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: color),
            SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: boldTextStyle(size: 16)),
            if (data['client_id'] != null) ...[
              SizedBox(height: 8),
              Text('Reference: ${data['client_id']}', style: secondaryTextStyle(size: 12)),
            ],
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
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
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: selectedOperator,
                      isExpanded: true,
                      decoration: InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                      hint: Text('Select operator', style: secondaryTextStyle()),
                      items: operators
                          .map((operator) => DropdownMenuItem(
                                value: operator,
                                child: Text(operator['name'].toString(), overflow: TextOverflow.ellipsis, style: primaryTextStyle(size: 14)),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => selectedOperator = value),
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
