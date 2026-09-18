import '../manage_imports.dart';
import '../utils/BrandTheme.dart';

class SettingScreen extends StatefulWidget {
  @override
  SettingScreenState createState() => SettingScreenState();
}

class SettingScreenState extends State<SettingScreen> {
  SettingModel settingModel = SettingModel();
  String? privacyPolicy;
  String? termsCondition;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    LiveStream().on(CHANGE_LANGUAGE, (p0) {
      setState(() {});
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandTokens.page,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: brandBlue,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(language.settings, style: boldTextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _groupTitle('Account'),
            _group([
            Visibility(
              visible: sharedPref.getString(LOGIN_TYPE) != 'mobile' &&
                  sharedPref.getString(LOGIN_TYPE) != LoginTypeGoogle &&
                  sharedPref.getString(LOGIN_TYPE) != null,
              child: settingItemWidget(
                  Ionicons.ios_lock_closed_outline, language.changePassword,
                  () {
                launchScreen(context, ChangePasswordScreen(),
                    pageRouteAnimation: PageRouteAnimation.Slide);
              }),
            ),
            settingItemWidget(Ionicons.language_outline, language.language, () {
              launchScreen(context, LanguageScreen(),
                  pageRouteAnimation: PageRouteAnimation.Slide);
            }, isLast: true),
            ]),
            _groupTitle('Help & legal'),
            _group([
            if (appStore.privacyPolicy != null)
              settingItemWidget(
                  Ionicons.ios_document_outline, language.privacyPolicy, () {
                launchScreen(
                    context,
                    TermsConditionScreen(
                        title: language.privacyPolicy,
                        subtitle: PRIVACY_URL),
                    pageRouteAnimation: PageRouteAnimation.Slide);
              }),
            if (appStore.mHelpAndSupport != null)
              settingItemWidget(Ionicons.help_outline, language.helpSupport,
                  () {
                if (appStore.mHelpAndSupport != null) {
                  launchUrl(Uri.parse(appStore.mHelpAndSupport!));
                } else {
                  toast(language.txtURLEmpty);
                }
              }),
            if (appStore.termsCondition != null)
              settingItemWidget(
                  Ionicons.document_outline, language.termsConditions, () {
                if (appStore.termsCondition != null) {
                  launchScreen(
                      context,
                      TermsConditionScreen(
                          title: language.termsConditions,
                          subtitle: TNC_URL),
                      pageRouteAnimation: PageRouteAnimation.Slide);
                } else {
                  toast(language.txtURLEmpty);
                }
              }),
            settingItemWidget(
              Ionicons.information,
              language.aboutUs,
              () {
                launchScreen(
                    context, AboutScreen(settingModel: appStore.settingModel),
                    pageRouteAnimation: PageRouteAnimation.Slide);
              },
              isLast: true,
            ),
            ]),
            _groupTitle('Danger zone'),
            _group([
              settingItemWidget(
                  Ionicons.ios_trash_outline,
                  color: BrandTokens.danger,
                  language.deleteAccount, () {
                launchScreen(context, DeleteAccountScreen(),
                    pageRouteAnimation: PageRouteAnimation.Slide);
              }, isLast: true),
            ]),
            SizedBox(height: 18),
            Center(child: Text('S Taxi · Your Smile is Our Destination', style: secondaryTextStyle(size: 12))),
          ],
        ),
      ),
    );
  }

  Widget _groupTitle(String title) => Padding(
        padding: EdgeInsets.fromLTRB(4, 6, 4, 8),
        child: Text(title.toUpperCase(), style: secondaryTextStyle(size: 11, weight: FontWeight.w700, color: BrandTokens.inkSoft)),
      );

  /// White rounded card that holds a group of rows.
  Widget _group(List<Widget> children) => Container(
        margin: EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: BrandTokens.line)),
        child: Column(children: children.where((w) => w is! SizedBox).toList()),
      );

  Widget settingItemWidget(IconData icon, String title, Function() onTap,
      {bool isLast = false, Widget? suffixIcon, Color? color}) {
    return inkWellWidget(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isLast ? Colors.transparent : BrandTokens.line)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: (color ?? BrandTokens.blue).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 19, color: color ?? BrandTokens.blue),
            ),
            SizedBox(width: 12),
            Expanded(child: Text(title, style: primaryTextStyle(size: 14, color: color))),
            suffixIcon ?? Icon(Icons.chevron_right_rounded, color: BrandTokens.inkSoft),
          ],
        ),
      ),
    );
  }
}
