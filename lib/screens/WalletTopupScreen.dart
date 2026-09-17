import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../manage_imports.dart';

/// Add money to the wallet with any UPI app. The rider pays the business UPI id,
/// then the amount is credited once S Taxi verifies the payment.
class WalletTopupScreen extends StatefulWidget {
  final num currentBalance;

  WalletTopupScreen({this.currentBalance = 0});

  @override
  State<WalletTopupScreen> createState() => _WalletTopupScreenState();
}

class _WalletTopupScreenState extends State<WalletTopupScreen> with WidgetsBindingObserver {
  final amountController = TextEditingController();
  final utrController = TextEditingController();
  final quickAmounts = [100, 200, 500, 1000, 2000];
  List<Map<String, dynamic>> topups = [];
  bool busy = false;
  bool waitingForUpiApp = false;
  Map<String, dynamic>? pendingTopup;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHistory();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    amountController.dispose();
    utrController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the UPI app: ask what happened, then let the server verify it.
    if (state == AppLifecycleState.resumed && waitingForUpiApp && pendingTopup != null) {
      waitingForUpiApp = false;
      Future.delayed(Duration(milliseconds: 400), _askPaymentResult);
    }
  }

  Future<void> _loadHistory() async {
    try {
      final list = await getWalletTopups(page: 1);
      if (mounted) setState(() => topups = list);
    } catch (e) {
      log('topups: $e');
    }
  }

  num get _amount => num.tryParse(amountController.text.trim()) ?? 0;

  Future<void> _startTopup() async {
    if (busy) return;
    if (_amount < 1) {
      toast('Enter the amount you want to add');
      return;
    }

    setState(() => busy = true);
    try {
      final data = await initiateWalletTopup(amount: _amount);
      pendingTopup = data;
      final uri = Uri.parse(data['upi_uri'].toString());

      if (await canLaunchUrl(uri)) {
        waitingForUpiApp = true;
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        toast('No UPI app found on this phone');
        _showManualPay(data);
      }
    } catch (e) {
      toast(e.toString());
    }
    if (mounted) setState(() => busy = false);
  }

  /// No UPI app installed: show the UPI id so the rider can pay from another device.
  void _showManualPay(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Pay to this UPI ID', style: boldTextStyle()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText('${data['upi_id']}', style: boldTextStyle(size: 16, color: brandBlue)),
            SizedBox(height: 6),
            Text('${data['payee_name']}', style: secondaryTextStyle()),
            SizedBox(height: 10),
            Text('Amount: $currencySymbol${data['amount']}', style: primaryTextStyle()),
            Text('Reference: ${data['reference']}', style: secondaryTextStyle(size: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _askPaymentResult();
            },
            child: Text('I have paid'),
          ),
        ],
      ),
    );
  }

  void _askPaymentResult() {
    if (pendingTopup == null) return;
    utrController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('Did the payment go through?', style: boldTextStyle(size: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount $currencySymbol${pendingTopup!['amount']} to ${pendingTopup!['upi_id']}', style: secondaryTextStyle(size: 13)),
            SizedBox(height: 12),
            TextField(
              controller: utrController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'UPI reference / UTR (optional)',
                helperText: 'Adding it speeds up the verification',
                helperMaxLines: 2,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => _finishTopup('failure'), child: Text('Not paid')),
          ElevatedButton(
            onPressed: () => _finishTopup('success'),
            style: ElevatedButton.styleFrom(backgroundColor: brandBlue),
            child: Text('Yes, I paid', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _finishTopup(String appStatus) async {
    Navigator.pop(context);
    final reference = pendingTopup?['reference']?.toString();
    if (reference == null) return;

    setState(() => busy = true);
    try {
      final paidAmount = num.tryParse('${pendingTopup?['amount']}') ?? _amount;
      final result = await confirmWalletTopup(reference: reference, appStatus: appStatus, utr: utrController.text.trim());
      amountController.clear();
      pendingTopup = null;
      _loadHistory();
      if (!mounted) return;
      if (appStatus == 'success') {
        final data = result['data'] is Map ? Map<String, dynamic>.from(result['data']) : <String, dynamic>{};
        final state = TransactionResultScreen.fromStatus(data['status']?.toString() ?? 'awaiting_verification');
        TransactionResultScreen.show(
          context,
          TransactionResultScreen(
            result: state,
            title: state == TransactionResult.success ? 'Money added to wallet' : 'Payment submitted',
            subtitle: state == TransactionResult.success ? null : 'We are verifying your UPI payment. The amount will be added to your wallet shortly.',
            amount: '$currencySymbol${paidAmount.toStringAsFixed(paidAmount % 1 == 0 ? 0 : 2)}',
            details: [
              MapEntry('Reference', reference),
              if (utrController.text.trim().isNotEmpty) MapEntry('UTR', utrController.text.trim()),
            ],
          ),
        );
      } else {
        toast(result['message']?.toString() ?? 'Payment cancelled');
      }
    } catch (e) {
      toast(e.toString());
    }
    if (mounted) setState(() => busy = false);
  }

  /// Paid by bank transfer / cash / another phone: send the details for verification.
  Future<void> _manualRequest() async {
    final manualAmount = TextEditingController(text: _amount > 0 ? _amount.toStringAsFixed(0) : '');
    final manualUtr = TextEditingController();
    final manualNote = TextEditingController();
    File? screenshot;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add money manually', style: boldTextStyle(size: 18)),
                SizedBox(height: 4),
                Text('Paid by bank transfer, cash or from another phone? Send us the details and we will add it after checking.', style: secondaryTextStyle(size: 12)),
                SizedBox(height: 14),
                TextField(
                  controller: manualAmount,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Amount paid', prefixText: '$currencySymbol '),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: manualUtr,
                  decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'UPI reference / UTR (optional)'),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: manualNote,
                  decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Note (optional)', hintText: 'Paid to GPay number, cash to driver...'),
                ),
                SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 60, maxWidth: 1600);
                    if (picked != null) setSheetState(() => screenshot = File(picked.path));
                  },
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
                    child: screenshot == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_rounded, size: 32, color: brandBlue),
                              SizedBox(height: 6),
                              Text('Attach payment screenshot (optional)', style: secondaryTextStyle(size: 12)),
                            ],
                          )
                        : Image.file(screenshot!, fit: BoxFit.cover),
                  ),
                ),
                SizedBox(height: 16),
                AppButtonWidget(
                  width: MediaQuery.of(sheetContext).size.width,
                  color: brandBlue,
                  text: 'Send request',
                  textStyle: boldTextStyle(color: Colors.white),
                  onTap: () async {
                    final amount = num.tryParse(manualAmount.text.trim()) ?? 0;
                    if (amount < 1) {
                      toast('Enter the amount you paid');
                      return;
                    }
                    Navigator.pop(sheetContext);
                    setState(() => busy = true);
                    await submitManualTopup(
                      amount: amount,
                      utr: manualUtr.text.trim(),
                      note: manualNote.text.trim(),
                      screenshot: screenshot,
                      onSuccess: (data) async {
                        _loadHistory();
                        if (!mounted) return;
                        setState(() => busy = false);
                        TransactionResultScreen.show(
                          context,
                          TransactionResultScreen(
                            result: TransactionResult.pending,
                            title: 'Request sent',
                            subtitle: 'Our team will check your payment and add the money to your wallet.',
                            amount: '$currencySymbol${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}',
                            details: [if (manualUtr.text.trim().isNotEmpty) MapEntry('UTR', manualUtr.text.trim())],
                          ),
                        );
                      },
                      onError: (error) {
                        toast(error?.toString() ?? 'Could not send the request');
                        if (mounted) setState(() => busy = false);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'success':
        return Color(0xFF1E9E57);
      case 'awaiting_verification':
      case 'initiated':
        return Color(0xFFD48A00);
      default:
        return Color(0xFFD93025);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'success':
        return 'Credited';
      case 'awaiting_verification':
        return 'Verifying';
      case 'initiated':
        return 'Started';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text('Add money', style: boldTextStyle(color: Colors.white)),
        backgroundColor: brandBlue,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [brandBlue, Color(0xFF1760C8)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 30),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wallet balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('$currencySymbol${widget.currentBalance.toStringAsFixed(2)}', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 18),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Enter amount', style: boldTextStyle(size: 15)),
                SizedBox(height: 10),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  style: boldTextStyle(size: 22),
                  decoration: InputDecoration(border: OutlineInputBorder(), prefixText: '$currencySymbol ', hintText: '0'),
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: quickAmounts.map((amount) {
                    return ActionChip(
                      label: Text('$currencySymbol$amount', style: boldTextStyle(size: 13)),
                      backgroundColor: Color(0xFFF0F3F8),
                      onPressed: () {
                        amountController.text = amount.toString();
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),
                AppButtonWidget(
                  width: MediaQuery.of(context).size.width,
                  color: brandBlue,
                  text: busy ? 'Please wait...' : 'Add balance with UPI',
                  textStyle: boldTextStyle(color: Colors.white),
                  onTap: busy ? null : _startTopup,
                ),
                SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: busy ? null : _manualRequest,
                    icon: Icon(Icons.receipt_long_rounded, size: 18, color: brandBlue),
                    label: Text('Paid another way? Add manually', style: boldTextStyle(size: 13, color: brandBlue)),
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFF1E9E57)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Your UPI app opens to pay S Taxi. The wallet is credited once the payment is verified, usually within a few minutes.',
                        style: secondaryTextStyle(size: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Text('Recent top-ups', style: boldTextStyle(size: 16)),
          SizedBox(height: 10),
          if (topups.isEmpty)
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Center(child: Text('No top-ups yet.', style: secondaryTextStyle())),
            )
          else
            ...topups.map((topup) {
              final status = topup['status'].toString();
              return Container(
                margin: EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$currencySymbol${(topup['amount'] as num).toStringAsFixed(2)}', style: boldTextStyle(size: 16)),
                          SizedBox(height: 2),
                          Text('${topup['reference']}', style: secondaryTextStyle(size: 11)),
                          if ((topup['method'] ?? '') == 'manual') Text('Manual request', style: secondaryTextStyle(size: 11)),
                          if ((topup['method'] ?? '') == 'admin') Text('Added by S Taxi', style: secondaryTextStyle(size: 11)),
                          if ((topup['utr'] ?? '').toString().isNotEmpty) Text('UTR: ${topup['utr']}', style: secondaryTextStyle(size: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: _statusColor(status).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                      child: Text(_statusLabel(status), style: boldTextStyle(size: 11, color: _statusColor(status))),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
