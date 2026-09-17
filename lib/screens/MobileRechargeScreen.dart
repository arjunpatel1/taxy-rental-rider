import 'dart:async';

import '../manage_imports.dart';

/// Mobile (prepaid) recharge, PhonePe-style: type the number, the operator and circle are
/// detected automatically, plans load inline, pick one and pay from the wallet.
class MobileRechargeScreen extends StatefulWidget {
  @override
  State<MobileRechargeScreen> createState() => _MobileRechargeScreenState();
}

class _MobileRechargeScreenState extends State<MobileRechargeScreen> {
  final numberController = TextEditingController();
  final searchController = TextEditingController();
  final amountController = TextEditingController();

  List<Map<String, dynamic>> operators = [];
  Map<String, dynamic>? operator;
  String? circleCode;
  String? circleName;

  List<Map<String, dynamic>> plans = [];
  String activeGroup = 'All';
  bool showingOffers = false;
  Map<String, dynamic>? selectedPlan;

  bool detecting = false;
  bool loadingPlans = false;
  bool paying = false;
  num walletBalance = 0;
  Timer? debounce;

  @override
  void initState() {
    super.initState();
    _loadOperators();
    _loadWallet();
  }

  @override
  void dispose() {
    debounce?.cancel();
    numberController.dispose();
    searchController.dispose();
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
    if (operators.isNotEmpty) return;
    try {
      final list = await getRechargeOperators(serviceType: 'Prepaid');
      if (mounted) setState(() => operators = list);
    } catch (e) {
      log('operators: $e');
    }
  }

  String get _digits => numberController.text.replaceAll(RegExp(r'\D'), '');

  void _onNumberChanged(String value) {
    debounce?.cancel();
    if (_digits.length < 10) {
      if (operator != null || plans.isNotEmpty) {
        setState(() {
          operator = null;
          circleName = null;
          plans = [];
          selectedPlan = null;
        });
      }
      return;
    }
    // small debounce so a pasted number triggers one lookup
    debounce = Timer(Duration(milliseconds: 250), _detectOperator);
  }

  /// Calls the operator lookup API as soon as a full 10-digit number is entered.
  Future<void> _detectOperator() async {
    if (detecting) return;
    final number = _digits;
    setState(() => detecting = true);
    try {
      // fees and plan flags come from the operator list, so make sure it is loaded first
      await _loadOperators();
      final detected = await detectRechargeOperator(number: number, serviceType: 'Prepaid');
      if (!mounted) return;
      // the number was edited while the lookup was running - look up the new one instead
      if (_digits != number) {
        setState(() => detecting = false);
        if (_digits.length == 10) _detectOperator();
        return;
      }
      if (detected != null && detected['operator_id'] != null) {
        final match = operators.where((o) => o['id'] == detected['operator_id']).toList();
        setState(() {
          operator = match.isNotEmpty ? match.first : {'id': detected['operator_id'], 'name': detected['operator_name'], 'has_plans': true};
          circleCode = detected['circle_code']?.toString();
          circleName = detected['circle']?.toString();
        });
        _loadPlans();
      } else {
        toast('Could not detect the operator. Please choose it.');
        _pickOperator();
      }
    } catch (e) {
      toast(e.toString());
    }
    if (mounted) setState(() => detecting = false);
  }

  Future<void> _loadPlans({bool offers = false}) async {
    if (operator == null) return;
    setState(() {
      loadingPlans = true;
      plans = [];
      selectedPlan = null;
      activeGroup = 'All';
      showingOffers = offers;
    });
    try {
      final list = offers
          ? (await getRechargeOffers(operatorId: operator!['id'], number: _digits)).map((o) => {...o, 'group': 'Offers'}).toList()
          : await getRechargePlans(operatorId: operator!['id'], circle: circleCode);
      if (mounted) setState(() => plans = list);
      if (offers && list.isEmpty) toast('No special offers for this number');
    } catch (e) {
      toast(e.toString());
    }
    if (mounted) setState(() => loadingPlans = false);
  }

  Future<void> _pickOperator() async {
    await _loadOperators();
    if (!mounted) return;
    if (operators.isEmpty) return toast('Operators are not available right now. Please try again.');
    final chosen = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12),
            Container(height: 4, width: 44, decoration: BoxDecoration(color: dividerColor, borderRadius: BorderRadius.circular(4))),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Align(alignment: Alignment.centerLeft, child: Text('Select operator', style: boldTextStyle(size: 17))),
            ),
            ...operators.map((o) => ListTile(
                  onTap: () => Navigator.pop(sheetContext, o),
                  leading: _operatorAvatar(o['name'].toString()),
                  title: Text(o['name'].toString(), style: primaryTextStyle(size: 15)),
                  trailing: operator?['id'] == o['id'] ? Icon(Icons.check_circle_rounded, color: brandBlue) : null,
                )),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (chosen != null) {
      setState(() => operator = chosen);
      _loadPlans();
    }
  }

  (Color, String) _operatorBrand(String name) {
    final n = name.toLowerCase();
    if (n.contains('airtel')) return (Color(0xFFE40000), 'A');
    if (n.contains('jio')) return (Color(0xFF0A3D91), 'J');
    if (n.contains('vi') || n.contains('vodafone') || n.contains('idea')) return (Color(0xFFE6007E), 'Vi');
    if (n.contains('bsnl')) return (Color(0xFFF08A00), 'B');
    if (n.contains('mtnl')) return (Color(0xFF0B7285), 'M');
    return (brandBlue, name.isEmpty ? '?' : name[0].toUpperCase());
  }

  Widget _operatorAvatar(String name, {double size = 40}) {
    final (colour, initials) = _operatorBrand(name);
    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
      child: Text(initials, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.36)),
    );
  }

  num get _amount => selectedPlan != null ? ((selectedPlan!['amount'] as num?) ?? 0) : (num.tryParse(amountController.text.trim()) ?? 0);

  num get _fee {
    final value = (operator?['surcharge_value'] as num?) ?? 0;
    return operator?['surcharge_type'] == 'percentage' ? (_amount * value / 100) : value;
  }

  Future<void> _pay() async {
    if (paying) return;
    if (_digits.length != 10) return toast('Enter a valid 10-digit mobile number');
    if (operator == null) return toast('Select the operator');
    if (_amount <= 0) return toast('Choose a plan or enter an amount');

    final total = _amount + _fee;
    if (total > walletBalance) {
      toast('Wallet balance is low. Add money to continue.');
      launchScreen(context, WalletTopupScreen(currentBalance: walletBalance), pageRouteAnimation: PageRouteAnimation.Slide).then((_) => _loadWallet());
      return;
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _operatorAvatar(operator!['name'].toString(), size: 44),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('+91 $_digits', style: boldTextStyle(size: 17)),
                        Text('${operator!['name']} Prepaid${circleName != null ? ' • $circleName' : ''}', style: secondaryTextStyle(size: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(height: 28),
              _billRow('Recharge amount', _amount),
              if (_fee > 0) _billRow('Convenience fee', _fee),
              Divider(height: 22),
              _billRow('Pay from wallet', total, bold: true),
              if (selectedPlan != null) ...[
                SizedBox(height: 10),
                Text((selectedPlan!['description'] ?? '').toString(), style: secondaryTextStyle(size: 12), maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
              SizedBox(height: 18),
              AppButtonWidget(
                width: MediaQuery.of(sheetContext).size.width,
                color: brandBlue,
                text: 'Pay $currencySymbol${total.toStringAsFixed(0)}',
                textStyle: boldTextStyle(color: Colors.white),
                onTap: () => Navigator.pop(sheetContext, true),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true) return;

    setState(() => paying = true);
    try {
      final result = await saveRecharge({'operator_id': operator!['id'], 'number': _digits, 'amount': _amount});
      final data = Map<String, dynamic>.from(result['data'] ?? {});
      walletBalance = (result['wallet_balance'] as num?) ?? walletBalance;
      if (data['status'] != 'failure' && mounted) {
        // clear the chosen pack so the same recharge is not paid again by accident
        setState(() {
          selectedPlan = null;
          amountController.clear();
        });
      }
      if (mounted) _showResult(data, result['message']?.toString() ?? '');
    } catch (e) {
      toast(e.toString());
    }
    if (mounted) setState(() => paying = false);
  }

  Widget _billRow(String label, num amount, {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: bold ? boldTextStyle(size: 15) : secondaryTextStyle(size: 14))),
          Text('$currencySymbol${amount.toStringAsFixed(2)}', style: bold ? boldTextStyle(size: 17, color: brandBlue) : primaryTextStyle(size: 14)),
        ],
      ),
    );
  }

  void _showResult(Map<String, dynamic> data, String message) {
    final status = (data['status'] ?? 'pending').toString();
    final result = TransactionResultScreen.fromStatus(status);
    final total = (data['total_amount'] as num?) ?? (data['amount'] as num?) ?? 0;
    final title = result == TransactionResult.success
        ? 'Recharge successful'
        : result == TransactionResult.pending
            ? 'Recharge in process'
            : 'Recharge failed';
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
          MapEntry('Mobile number', '${data['number'] ?? _digits}'),
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

  @override
  Widget build(BuildContext context) {
    final groups = <String>{for (final p in plans) (p['group'] ?? '').toString()}..removeWhere((g) => g.isEmpty);
    final query = searchController.text.trim().toLowerCase();
    final visiblePlans = plans.where((p) {
      if (activeGroup != 'All' && (p['group'] ?? '').toString() != activeGroup) return false;
      if (query.isEmpty) return true;
      return '${p['amount']} ${p['validity']} ${p['data']} ${p['description']}'.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text('Mobile Recharge'),
        actions: [
          IconButton(
            tooltip: 'History',
            icon: Icon(Icons.history_rounded),
            onPressed: () => launchScreen(context, RechargeHistoryScreen(), pageRouteAnimation: PageRouteAnimation.Slide),
          ),
        ],
      ),
      body: Column(
        children: [
          // number + detected operator
          Container(
            margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mobile number', style: secondaryTextStyle(size: 12)),
                TextField(
                  controller: numberController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  autofocus: true,
                  onChanged: _onNumberChanged,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: boldTextStyle(size: 22, letterSpacing: 1.2),
                  decoration: InputDecoration(
                    counterText: '',
                    prefixText: '+91  ',
                    prefixStyle: boldTextStyle(size: 22, color: textSecondaryColor),
                    hintText: '00000 00000',
                    border: InputBorder.none,
                    suffixIcon: detecting
                        ? Padding(padding: EdgeInsets.all(12), child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                        : (numberController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close_rounded),
                                onPressed: () {
                                  numberController.clear();
                                  _onNumberChanged('');
                                },
                              )
                            : null),
                  ),
                ),
                if (operator != null) ...[
                  Divider(height: 18),
                  Row(
                    children: [
                      _operatorAvatar(operator!['name'].toString()),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${operator!['name']} Prepaid', style: boldTextStyle(size: 15)),
                            if (circleName != null && circleName!.isNotEmpty) Text(circleName!, style: secondaryTextStyle(size: 12)),
                          ],
                        ),
                      ),
                      TextButton(onPressed: _pickOperator, child: Text('Change')),
                    ],
                  ),
                ] else if (_digits.length == 10 && !detecting) ...[
                  Divider(height: 18),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _pickOperator,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        Icon(Icons.sim_card_rounded, color: brandBlue),
                        SizedBox(width: 10),
                        Expanded(child: Text('Select operator', style: boldTextStyle(size: 14, color: brandBlue))),
                        Icon(Icons.chevron_right_rounded, color: brandBlue),
                      ]),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // plans
          Expanded(
            child: operator == null
                ? _emptyHint()
                : Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(14, 14, 8, 6),
                          child: Row(
                            children: [
                              Text('Choose a plan', style: boldTextStyle(size: 16)),
                              Spacer(),
                              if (operator!['has_plans'] == true)
                                TextButton.icon(
                                  onPressed: loadingPlans ? null : () => _loadPlans(offers: !showingOffers),
                                  icon: Icon(showingOffers ? Icons.list_alt_rounded : Icons.local_offer_rounded, size: 16),
                                  label: Text(showingOffers ? 'All plans' : 'My offers'),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: TextField(
                            controller: searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search ₹299, 2GB, 28 days…',
                              prefixIcon: Icon(Icons.search_rounded),
                              filled: true,
                              fillColor: Color(0xFFF4F6F9),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                            ),
                          ),
                        ),
                        if (groups.length > 1)
                          SizedBox(
                            height: 46,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              children: ['All', ...groups].map((g) {
                                final selected = activeGroup == g;
                                return Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: ChoiceChip(
                                    label: Text(_groupLabel(g), style: boldTextStyle(size: 12, color: selected ? Colors.white : brandBlack)),
                                    selected: selected,
                                    showCheckmark: false,
                                    selectedColor: brandBlue,
                                    backgroundColor: Color(0xFFF1F4F9),
                                    side: BorderSide.none,
                                    onSelected: (_) => setState(() => activeGroup = g),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        Expanded(
                          child: loadingPlans
                              ? Center(child: CircularProgressIndicator())
                              : visiblePlans.isEmpty
                                  ? Center(child: Text(plans.isEmpty ? 'No plans found. Enter an amount below.' : 'Nothing matches that search', style: secondaryTextStyle()))
                                  : ListView.builder(
                                      padding: EdgeInsets.fromLTRB(10, 2, 10, 12),
                                      itemCount: visiblePlans.length,
                                      itemBuilder: (_, i) => _planCard(visiblePlans[i]),
                                    ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: operator == null ? null : _payBar(),
    );
  }

  String _groupLabel(String group) {
    switch (group.toUpperCase()) {
      case 'FULLTT':
        return 'Unlimited';
      case 'TOPUP':
        return 'Talktime';
      case '3G/4G':
        return 'Data';
      case 'RATE CUTTER':
        return 'Entertainment';
      case 'ROMAING':
        return 'Roaming';
      default:
        return group;
    }
  }

  Widget _emptyHint() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(color: brandBlue.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(Icons.phone_iphone_rounded, size: 42, color: brandBlue),
            ),
            SizedBox(height: 14),
            Text('Enter a mobile number', style: boldTextStyle(size: 16)),
            SizedBox(height: 4),
            Text('We find the operator and circle automatically and show the latest plans.',
                textAlign: TextAlign.center, style: secondaryTextStyle(size: 13)),
          ],
        ),
      ),
    );
  }

  Widget _planCard(Map<String, dynamic> plan) {
    final amount = (plan['amount'] as num?) ?? 0;
    final validity = (plan['validity'] ?? '').toString();
    final data = (plan['data'] ?? '').toString();
    final selected = identical(selectedPlan, plan);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: selected ? brandBlue.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() {
            selectedPlan = selected ? null : plan;
            amountController.clear();
          }),
          child: Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? brandBlue : dividerColor.withValues(alpha: 0.7), width: selected ? 1.5 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('$currencySymbol${amount.toStringAsFixed(0)}', style: boldTextStyle(size: 20, color: brandBlue)),
                    Spacer(),
                    if (validity.isNotEmpty && validity != 'N/A') _chip(Icons.calendar_today_rounded, validity),
                    if (data.isNotEmpty) ...[SizedBox(width: 6), _chip(Icons.data_usage_rounded, data)],
                    SizedBox(width: 8),
                    Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: selected ? brandBlue : textSecondaryColor, size: 20),
                  ],
                ),
                SizedBox(height: 6),
                Text((plan['description'] ?? '').toString(), style: secondaryTextStyle(size: 12), maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: textSecondaryColor),
        SizedBox(width: 4),
        Text(label, style: boldTextStyle(size: 11)),
      ]),
    );
  }

  Widget _payBar() {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: Offset(0, -4))]),
        child: Row(
          children: [
            Expanded(
              child: selectedPlan != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$currencySymbol${_amount.toStringAsFixed(0)}', style: boldTextStyle(size: 20)),
                        Text('Wallet: $currencySymbol${walletBalance.toStringAsFixed(2)}', style: secondaryTextStyle(size: 12)),
                      ],
                    )
                  : TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Or enter amount',
                        prefixText: '$currencySymbol ',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
            ),
            SizedBox(width: 12),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: paying || _amount <= 0 ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(horizontal: 26),
                ),
                child: paying
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Pay', style: boldTextStyle(color: Colors.white, size: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
