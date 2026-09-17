import '../manage_imports.dart';
import '../utils/BrandTheme.dart';

/// Bank account for refunds and withdrawals: bank, holder, account number, IFSC and branch.
class BankInfoScreen extends StatefulWidget {
  @override
  BankInfoScreenState createState() => BankInfoScreenState();
}

class BankInfoScreenState extends State<BankInfoScreen> {
  final formKey = GlobalKey<FormState>();

  final bankNameController = TextEditingController();
  final accountHolderNameController = TextEditingController();
  final accountNumberController = TextEditingController();
  final ifscController = TextEditingController();
  final branchController = TextEditingController();

  UserBankAccount? bankDetail;
  bool saving = false;

  static final _ifscPattern = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    appStore.setLoading(true);
    await getUserDetail(userId: sharedPref.getInt(USER_ID)).then((value) {
      appStore.setLoading(false);
      if (value.data!.userBankAccount != null) {
        bankDetail = value.data!.userBankAccount!;
        bankNameController.text = bankDetail!.bankName.validate();
        accountHolderNameController.text = bankDetail!.accountHolderName.validate();
        accountNumberController.text = bankDetail!.accountNumber.validate();
        ifscController.text = bankDetail!.bankCode.validate();
        branchController.text = bankDetail!.bankAddress.validate();
        setState(() {});
      }
    }).catchError((error) {
      appStore.setLoading(false);
      log(error.toString());
    });
  }

  Future<void> updateBankInfo() async {
    if (saving || !formKey.currentState!.validate()) return;
    hideKeyboard(context);
    setState(() => saving = true);
    try {
      await updateBankDetail(
        bankName: bankNameController.text.trim(),
        accountName: accountHolderNameController.text.trim(),
        accountNumber: accountNumberController.text.trim(),
        bankCode: ifscController.text.trim().toUpperCase(),
        branch: branchController.text.trim(),
      );
      bankDetail ??= UserBankAccount();
      toast(language.bankInfoUpdated);
    } catch (e) {
      log(e.toString());
    }
    if (mounted) setState(() => saving = false);
  }

  InputDecoration _decoration(String label, IconData icon, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: BrandTokens.inkSoft, size: 20),
      );

  String? _required(String? v) => (v ?? '').trim().isEmpty ? language.thisFieldRequired : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(language.bankInfo, style: boldTextStyle(color: Colors.white))),
      body: Stack(
        children: [
          Form(
            key: formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(color: BrandTokens.blueSoft, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    Icon(Icons.shield_outlined, color: BrandTokens.blue, size: 20),
                    SizedBox(width: 10),
                    Expanded(child: Text('Used only to send your refunds and withdrawals.', style: secondaryTextStyle(size: 12, color: BrandTokens.ink))),
                  ]),
                ),
                SizedBox(height: 18),
                TextFormField(
                  controller: bankNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration('Bank Name', Icons.account_balance_outlined, hint: 'e.g. State Bank of India'),
                  validator: _required,
                ),
                SizedBox(height: 14),
                TextFormField(
                  controller: accountHolderNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration('Account Holder Name', Icons.person_outline_rounded, hint: 'As printed on passbook'),
                  validator: _required,
                ),
                SizedBox(height: 14),
                TextFormField(
                  controller: accountNumberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(18)],
                  decoration: _decoration('Account Number', Icons.numbers_rounded),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return language.thisFieldRequired;
                    if (value.length < 9) return 'Enter a valid account number';
                    return null;
                  },
                ),
                SizedBox(height: 14),
                TextFormField(
                  controller: ifscController,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')), LengthLimitingTextInputFormatter(11)],
                  decoration: _decoration('IFSC Code', Icons.qr_code_2_rounded, hint: 'e.g. SBIN0001234'),
                  validator: (v) {
                    final value = (v ?? '').trim().toUpperCase();
                    if (value.isEmpty) return language.thisFieldRequired;
                    if (!_ifscPattern.hasMatch(value)) return 'Enter a valid 11-character IFSC code';
                    return null;
                  },
                ),
                SizedBox(height: 14),
                TextFormField(
                  controller: branchController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration('Branch', Icons.location_city_outlined, hint: 'e.g. Anna Nagar, Madurai'),
                  validator: _required,
                ),
              ],
            ),
          ),
          Observer(builder: (context) => Visibility(visible: appStore.isLoading, child: loaderWidget())),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: saving ? null : updateBankInfo,
              child: saving
                  ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : Text(bankDetail != null ? language.updateBankDetail : language.addBankDetail),
            ),
          ),
        ),
      ),
    );
  }
}
