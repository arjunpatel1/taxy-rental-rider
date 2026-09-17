import 'dart:async';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pinput/pinput.dart';

import '../manage_imports.dart';

/// Mobile + WhatsApp OTP sign-in, shown inline on the login page (no dialog).
/// Step 1 takes the number, step 2 the 6-digit code, with a resend timer.
class MobileOtpSignIn extends StatefulWidget {
  @override
  State<MobileOtpSignIn> createState() => _MobileOtpSignInState();
}

class _MobileOtpSignInState extends State<MobileOtpSignIn> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  String dialCode = defaultCountryCode;
  String fullNumber = '';
  bool codeSent = false;
  bool busy = false;
  int resendIn = 0;
  Timer? timer;

  @override
  void dispose() {
    timer?.cancel();
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    timer?.cancel();
    setState(() => resendIn = 30);
    timer = Timer.periodic(Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => resendIn--);
      if (resendIn <= 0) t.cancel();
    });
  }

  Future<void> _sendOtp() async {
    if (busy) return;
    if (!formKey.currentState!.validate()) return;

    hideKeyboard(context);
    fullNumber = '$dialCode ${phoneController.text.trim()}';
    setState(() => busy = true);

    try {
      await sendWhatsappOtp(fullNumber.replaceAll(' ', ''));
      otpController.clear();
      setState(() => codeSent = true);
      _startResendTimer();
    } catch (e) {
      toast(e.toString());
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _verify(String code) async {
    if (code.length < 6) {
      toast(language.pleaseEnterOtp);
      return;
    }

    hideKeyboard(context);
    setState(() => busy = true);

    try {
      // The server checks the WhatsApp OTP and hands back a Firebase custom token,
      // so the app still gets a Firebase user for chat / Firestore.
      final result = await verifyWhatsappOtp(fullNumber.replaceAll(' ', ''), code);
      final firebaseToken = (result['firebase_token'] ?? '').toString();
      if (firebaseToken.isNotEmpty) await FirebaseAuth.instance.signInWithCustomToken(firebaseToken);

      final request = {
        'email': '',
        'login_type': 'mobile',
        'user_type': RIDER,
        'username': fullNumber.split(' ').last,
        'accessToken': fullNumber.split(' ').last,
        'contact_number': fullNumber.replaceAll(' ', ''),
        'player_id': sharedPref.getString(PLAYER_ID).validate(),
        'otp_token': (result['otp_token'] ?? '').toString(),
      };

      final response = await logInApi(request, isSocialLogin: true);
      if (!mounted) return;

      if (response.data == null) {
        launchScreen(context, SignUpScreen(countryCode: dialCode, userName: fullNumber.split(' ').last, socialLogin: true));
      } else {
        updatePlayerId();
        launchScreen(context, HomeScreen(), isNewTask: true);
      }
    } catch (e) {
      toast(e.toString());
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: Duration(milliseconds: 250),
      alignment: Alignment.topCenter,
      child: codeSent ? _otpStep() : _numberStep(),
    );
  }

  Widget _numberStep() {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mobile number', style: boldTextStyle(size: 14)),
          SizedBox(height: 8),
          AppTextField(
            controller: phoneController,
            textFieldType: TextFieldType.PHONE,
            autoFocus: false,
            decoration: inputDecoration(
              context,
              label: language.phoneNumber,
              prefixIcon: IntrinsicHeight(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CountryCodePicker(
                      padding: EdgeInsets.zero,
                      initialSelection: dialCode,
                      showFlag: true,
                      showOnlyCountryWhenClosed: false,
                      alignLeft: false,
                      textStyle: primaryTextStyle(),
                      dialogBackgroundColor: Theme.of(context).cardColor,
                      dialogSize: Size(MediaQuery.of(context).size.width - 60, MediaQuery.of(context).size.height * 0.6),
                      searchStyle: primaryTextStyle(),
                      dialogTextStyle: primaryTextStyle(),
                      onInit: (code) => dialCode = code?.dialCode ?? dialCode,
                      onChanged: (code) => dialCode = code.dialCode ?? dialCode,
                    ),
                    VerticalDivider(color: Colors.grey.withValues(alpha: 0.4)),
                  ],
                ),
              ),
            ),
            validator: (value) {
              if (value!.trim().isEmpty) return language.thisFieldRequired;
              if (value.trim().length < 6) return language.thisFieldRequired;
              return null;
            },
          ),
          SizedBox(height: 16),
          _primaryButton('Send OTP', _sendOtp),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 14, color: textSecondaryColor),
              SizedBox(width: 6),
              Expanded(child: Text('Your number is only used to sign you in.', style: secondaryTextStyle(size: 12))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _otpStep() {
    final pinTheme = PinTheme(
      width: 46,
      height: 52,
      textStyle: boldTextStyle(size: 18),
      decoration: BoxDecoration(
        color: Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: dividerColor),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(children: [
                  TextSpan(text: 'Code sent to ', style: secondaryTextStyle(size: 13)),
                  TextSpan(text: fullNumber, style: boldTextStyle(size: 14)),
                ]),
              ),
            ),
            TextButton(
              onPressed: busy ? null : () => setState(() => codeSent = false),
              child: Text('Change', style: boldTextStyle(size: 13, color: brandBlue)),
            ),
          ],
        ),
        SizedBox(height: 12),
        Center(
          child: Pinput(
            length: 6,
            autofocus: true,
            controller: otpController,
            defaultPinTheme: pinTheme,
            focusedPinTheme: pinTheme.copyWith(
              decoration: pinTheme.decoration!.copyWith(border: Border.all(color: brandBlue, width: 1.6)),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofillHints: [AutofillHints.oneTimeCode],
            onCompleted: _verify,
          ),
        ),
        SizedBox(height: 16),
        _primaryButton('Verify & continue', () => _verify(otpController.text.trim())),
        SizedBox(height: 8),
        Center(
          child: resendIn > 0
              ? Text('Resend code in ${resendIn}s', style: secondaryTextStyle(size: 12))
              : TextButton(
                  onPressed: busy ? null : _sendOtp,
                  child: Text('Resend code', style: boldTextStyle(size: 13, color: brandBlue)),
                ),
        ),
      ],
    );
  }

  Widget _primaryButton(String label, VoidCallback onTap) {
    return AppButtonWidget(
      width: MediaQuery.of(context).size.width,
      color: brandBlue,
      onTap: busy ? null : onTap,
      child: busy
          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(label, style: boldTextStyle(color: Colors.white)),
    );
  }
}
