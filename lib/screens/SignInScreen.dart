import '../components/AnimatedTaxiRoad.dart';
import '../manage_imports.dart';

class SignInScreen extends StatefulWidget {
  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final FirebaseAuth auth = FirebaseAuth.instance;
  UserModel userModel = UserModel();

  GoogleAuthServices googleAuthService = GoogleAuthServices();

  AuthServices authService = AuthServices();

  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();

  FocusNode emailFocus = FocusNode();
  FocusNode passFocus = FocusNode();

  // String? privacyPolicy;
  // String? termsCondition;

  bool mIsRemember = false;
  bool isAcceptTermsNPrivacy = false;

  @override
  void initState() {
    super.initState();
    init();
    checkAndShowFirebasePopup();
  }

  void init() async {
    // await appSetting();
    await saveOneSignalPlayerId().then((value) {});
    mIsRemember = sharedPref.getBool(REMEMBER_ME) ?? false;
    if (mIsRemember) {
      emailController.text = sharedPref.getString(USER_EMAIL).validate();
      passController.text = sharedPref.getString(USER_PASSWORD).validate();
      setState(() {});
    }
  }

  Future<void> checkAndShowFirebasePopup() async {
    try {
      final docRef = FirebaseFirestore.instance.collection('show_popup').doc('config'); // single config document
      final doc = await docRef.get();
      if (!doc.exists) {
        // Create default document
        await docRef.set({
          "show_popup": false,
          "message": "",
          "title": "",
        });
        return;
      }
      bool showPopup = doc.data()?['show_popup'] ?? false;
      String message = doc.data()?['message'] ?? "";
      String title = doc.data()?['title'] ?? "";

      if (showPopup) {
        Future.delayed(Duration(milliseconds: 500), () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return popupDialog(title, message, context);
            },
          );
        });
      }
    } catch (e) {
      print("Popup Error: $e");
    }
  }

  // Future<void> appSetting() async {
  //   await getAppSettingApi().then((value) {
  //     print(value.termsCondition!.value);
  //     print(value.privacyPolicyModel!.value);
  //     if (value.privacyPolicyModel!.value != null) privacyPolicy = value.privacyPolicyModel!.value;
  //     if (value.termsCondition!.value != null) termsCondition = value.termsCondition!.value;
  //   }).catchError((error) {
  //     log(error.toString());
  //   });
  // }

  Future<void> logIn() async {
    hideKeyboard(context);
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      if (isAcceptTermsNPrivacy) {
        appStore.setLoading(true);

        Map req = {
          'email': emailController.text.trim(),
          'password': passController.text.trim(),
          "player_id": sharedPref.getString(PLAYER_ID).validate(),
          'user_type': RIDER,
        };
        log(req);
        await logInApi(req).then((value) {
          userModel = value.data!;
          auth.signInWithEmailAndPassword(email: emailController.text, password: passController.text).then((value) async {
            sharedPref.setString(UID, value.user!.uid);
            updateProfileUid();
            await checkPermission().then((value) async {
              await Geolocator.getCurrentPosition().then((value) {
                sharedPref.setDouble(LATITUDE, value.latitude);
                sharedPref.setDouble(LONGITUDE, value.longitude);
              });
            });
            appStore.setLoading(false);
            launchScreen(context, DashBoardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
          }).catchError((e) {
            appStore.setLoading(false);
            if (e.toString().contains('user-not-found') || e.toString().contains('invalid')) {
              authService.signUpWithEmailPassword(
                context,
                mobileNumber: userModel.contactNumber,
                email: userModel.email,
                fName: userModel.firstName,
                lName: userModel.lastName,
                userName: userModel.username,
                password: passController.text,
                userType: RIDER,
              );
            } else {
              launchScreen(context, DashBoardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
            }
            log(e.toString());
          });
          // appStore.setLoading(false);
        }).catchError((error) {
          appStore.isLoading = false;
          toast(error.toString());
        });
      } else {
        toast(language.pleaseAcceptTermsOfServicePrivacyPolicy);
      }
    }
  }

  void googleSignIn() async {
    hideKeyboard(context);
    appStore.setLoading(true);

    await googleAuthService.signInWithGoogle(context).then((value) async {
      appStore.setLoading(false);
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
    });
  }

  appleLoginApi() async {
    hideKeyboard(context);
    appStore.setLoading(true);
    await appleLogIn(context).then((value) {
      appStore.setLoading(false);
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Widget _brandHeader() {
    return Container(
      height: 230,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [brandYellow, Color(0xFFFFC800)]),
        boxShadow: [BoxShadow(color: brandYellow.withValues(alpha: 0.45), blurRadius: 24, offset: Offset(0, 12))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(left: 0, right: 0, bottom: 0, child: AnimatedTaxiRoad(height: 110)),
            Align(
              alignment: Alignment(0, -0.55),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.asset(ic_app_logo, width: 78, height: 78, fit: BoxFit.cover)),
                  SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(mAppName, style: TextStyle(color: brandBlack, fontSize: 28, fontWeight: FontWeight.w800)),
                      Text('Your Smile is Our Destination', style: TextStyle(color: brandBlack.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Form(
            key: formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: context.statusBarHeight + 8),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 900),
                    curve: Curves.easeOutBack,
                    builder: (context, t, child) => Opacity(
                      opacity: t.clamp(0.0, 1.0),
                      child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
                    ),
                    child: _brandHeader(),
                  ),
                  SizedBox(height: 24),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, child) => Opacity(
                      opacity: t,
                      child: Transform.translate(offset: Offset(0, 20 * (1 - t)), child: child),
                    ),
                    child: Column(
                      children: [
                        Text(language.welcome, style: boldTextStyle(size: 24)),
                        SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(text: '${language.signContinue} ', style: primaryTextStyle(size: 14)),
                              TextSpan(text: '🚗', style: primaryTextStyle(size: 20)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  AppTextField(
                    controller: emailController,
                    nextFocus: passFocus,
                    autoFocus: false,
                    textFieldType: TextFieldType.EMAIL,
                    keyboardType: TextInputType.emailAddress,
                    errorThisFieldRequired: language.thisFieldRequired,
                    decoration: inputDecoration(context, label: language.email),
                  ),
                  SizedBox(height: 16),
                  AppTextField(
                    controller: passController,
                    focus: passFocus,
                    autoFocus: false,
                    textFieldType: TextFieldType.PASSWORD,
                    errorThisFieldRequired: language.thisFieldRequired,
                    decoration: inputDecoration(context, label: language.password),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            height: 18.0,
                            width: 18.0,
                            child: Checkbox(
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              activeColor: primaryColor,
                              value: mIsRemember,
                              shape: RoundedRectangleBorder(borderRadius: radius(4)),
                              onChanged: (v) async {
                                mIsRemember = v!;
                                if (!mIsRemember) {
                                  sharedPref.remove(REMEMBER_ME);
                                } else {
                                  await sharedPref.setBool(REMEMBER_ME, mIsRemember);
                                  await sharedPref.setString(USER_EMAIL, emailController.text);
                                  await sharedPref.setString(USER_PASSWORD, passController.text);
                                }

                                setState(() {});
                              },
                            ),
                          ),
                          SizedBox(width: 8),
                          inkWellWidget(
                            onTap: () async {
                              mIsRemember = !mIsRemember;
                              setState(() {});
                            },
                            child: Text(language.rememberMe, style: primaryTextStyle(size: 14)),
                          ),
                        ],
                      ),
                      inkWellWidget(
                        onTap: () {
                          launchScreen(context, ForgotPasswordScreen(), pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
                        },
                        child: Text(language.forgotPassword, style: primaryTextStyle()),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(
                        height: 18,
                        width: 18,
                        child: Checkbox(
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          activeColor: primaryColor,
                          value: isAcceptTermsNPrivacy,
                          shape: RoundedRectangleBorder(borderRadius: radius(4)),
                          onChanged: (v) async {
                            isAcceptTermsNPrivacy = v!;
                            setState(() {});
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(text: language.iAgreeToThe + " ", style: primaryTextStyle(size: 12)),
                              TextSpan(
                                text: language.termsConditions.splitBefore(' &'),
                                style: boldTextStyle(color: primaryColor, size: 14),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    if (TNC_URL.isNotEmpty) {
                                      launchScreen(context, TermsConditionScreen(title: language.termsConditions, subtitle: TNC_URL), pageRouteAnimation: PageRouteAnimation.Slide);
                                    } else {
                                      toast(language.txtURLEmpty);
                                    }
                                  },
                              ),
                              TextSpan(text: ' & ', style: primaryTextStyle(size: 12)),
                              TextSpan(
                                text: language.privacyPolicy,
                                style: boldTextStyle(color: primaryColor, size: 14),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    if (PRIVACY_URL.isNotEmpty) {
                                      launchScreen(context, TermsConditionScreen(title: language.privacyPolicy, subtitle: PRIVACY_URL), pageRouteAnimation: PageRouteAnimation.Slide);
                                    } else {
                                      toast(language.txtURLEmpty);
                                    }
                                  },
                              ),
                            ],
                          ),
                          textAlign: TextAlign.left,
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 32),
                  AppButtonWidget(
                    width: MediaQuery.of(context).size.width,
                    text: language.logIn,
                    onTap: () async {
                      logIn();
                    },
                  ),
                  SizedBox(height: 16),
                  socialWidget(),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Observer(
            builder: (context) {
              return Visibility(
                visible: appStore.isLoading,
                child: loaderWidget(),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(language.donHaveAnAccount, style: primaryTextStyle()),
                SizedBox(width: 8),
                inkWellWidget(
                  onTap: () {
                    hideKeyboard(context);
                    launchScreen(context, SignUpScreen());
                  },
                  child: Text(language.signUp, style: boldTextStyle(size: 18)),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget socialWidget() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: Divider(color: dividerColor)),
              Padding(
                padding: EdgeInsets.only(left: 16, right: 16),
                child: Text(language.orLogInWith, style: primaryTextStyle()),
              ),
              Expanded(child: Divider(color: dividerColor)),
            ],
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            inkWellWidget(
              onTap: () async {
                googleSignIn();
              },
              child: socialWidgetComponent(img: ic_google),
            ),
            SizedBox(width: 12),
            inkWellWidget(
              onTap: () async {
                showDialog(
                  context: context,
                  builder: (_) {
                    return AlertDialog(
                      contentPadding: EdgeInsets.all(16),
                      content: OTPDialog(),
                    );
                  },
                );
                appStore.setLoading(false);
              },
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(border: Border.all(color: dividerColor), borderRadius: radius(defaultRadius)),
                child: Image.asset(ic_mobile, fit: BoxFit.cover, height: 30, width: 30),
              ),
            ),
            if (Platform.isIOS) SizedBox(width: 12),
            if (Platform.isIOS)
              inkWellWidget(
                onTap: () async {
                  appleLoginApi();
                },
                child: socialWidgetComponent(img: ic_apple),
              ),
          ],
        ),
      ],
    );
  }

  Widget socialWidgetComponent({required String img}) {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(border: Border.all(color: dividerColor), borderRadius: radius(defaultRadius)),
      child: Image.asset(img, fit: BoxFit.cover, height: 30, width: 30),
    );
  }
}
