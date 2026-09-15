import 'dart:math' as math;

import '../components/AnimatedTaxiRoad.dart';
import '../manage_imports.dart';

class SplashScreen extends StatefulWidget {
  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Keep the branded intro on screen long enough to play through before navigating away.
  static const _minSplashDuration = Duration(milliseconds: 3200);
  final DateTime _shownAt = DateTime.now();

  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..forward();
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();

  late final Animation<double> _logoScale = CurvedAnimation(parent: _intro, curve: const Interval(0.0, 0.55, curve: Curves.elasticOut));
  late final Animation<double> _logoFade = CurvedAnimation(parent: _intro, curve: const Interval(0.0, 0.25, curve: Curves.easeOut));
  late final Animation<double> _tagline = CurvedAnimation(parent: _intro, curve: const Interval(0.62, 0.9, curve: Curves.easeOutCubic));
  late final Animation<double> _road = CurvedAnimation(parent: _intro, curve: const Interval(0.3, 0.75, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _checkNotifyPermission();
    getAppSettingsData();
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _waitForIntro() async {
    final remaining = _minSplashDuration - DateTime.now().difference(_shownAt);
    if (remaining > Duration.zero) await Future.delayed(remaining);
  }

  void init() async {
    List<ConnectivityResult> b = await Connectivity().checkConnectivity();
    if (b.contains(ConnectivityResult.none)) {
      return toast(language.yourInternetIsNotWorking);
    }
    await _waitForIntro();
    // Asked here (after the intro) rather than in main(), which would block the first frame.
    await Permission.notification.request();
    if (sharedPref.getBool(IS_FIRST_TIME) ?? true) {
      await Geolocator.requestPermission().then((value) async {
        launchScreen(context, WalkThroughScreen(),
            pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: true);
        Geolocator.getCurrentPosition().then((value) {
          sharedPref.setDouble(LATITUDE, value.latitude);
          sharedPref.setDouble(LONGITUDE, value.longitude);
        });
      }).catchError((e) {
        launchScreen(context, WalkThroughScreen(),
            pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: true);
      });
    } else {
      if (!appStore.isLoggedIn) {
        launchScreen(context, SignInScreen(),
            pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: true);
      } else {
        if (sharedPref.getString(CONTACT_NUMBER).validate().isEmptyOrNull) {
          launchScreen(context, EditProfileScreen(isGoogle: true),
              isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
        } else {
          getUserDetail(userId: sharedPref.getInt(USER_ID)).then((value) {
            appStore.setUserEmail(value.data!.email.validate());
            appStore.setUserName(value.data!.username.validate());
            appStore.setFirstName(value.data!.firstName.validate());
            appStore.setUserProfile(value.data!.profileImage.validate());
            appStore.setReferralCode(value.data!.referralCode.validate());

            sharedPref.setString(USER_EMAIL, value.data!.email.validate());
            sharedPref.setString(FIRST_NAME, value.data!.firstName.validate());
            sharedPref.setString(LAST_NAME, value.data!.lastName.validate());
            sharedPref.setString(
                USER_PROFILE_PHOTO, value.data!.profileImage.validate());

            appStore.setLoading(false);
            setState(() {});
          }).catchError((error) {
            log(error.toString());
            appStore.setLoading(false);
          });
          if (await checkPermission())
            await Geolocator.requestPermission().then((value) async {
              await Geolocator.getCurrentPosition().then((value) {
                sharedPref.setDouble(LATITUDE, value.latitude);
                sharedPref.setDouble(LONGITUDE, value.longitude);
                launchScreen(context, HomeScreen(),
                    pageRouteAnimation: PageRouteAnimation.Slide,
                    isNewTask: true);
              });
            }).catchError((e) {
              launchScreen(context, HomeScreen(),
                  pageRouteAnimation: PageRouteAnimation.Slide,
                  isNewTask: true);
            });
        }
      }
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandYellow,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.dark,
            statusBarColor: Colors.transparent,
            statusBarBrightness: Brightness.dark),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([_intro, _pulse]),
        builder: (context, _) {
          final logoScale = _logoScale.value;
          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [brandYellow, Color(0xFFFFC800)],
                    ),
                  ),
                ),
              ),
              Positioned.fill(child: CustomPaint(painter: _GlowPainter(_pulse.value))),
              Align(
                alignment: const Alignment(0, -0.2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 280,
                      height: 280,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(size: const Size(280, 280), painter: _RipplePainter(_pulse.value, _logoFade.value)),
                          Opacity(
                            opacity: _logoFade.value,
                            child: Transform.rotate(
                              angle: (1 - math.min(1.0, logoScale)) * -0.25,
                              child: Transform.scale(scale: 0.4 + 0.6 * logoScale, child: _logoCard()),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _animatedTitle(),
                    const SizedBox(height: 10),
                    Opacity(
                      opacity: _tagline.value,
                      child: Transform.translate(
                        offset: Offset(0, 16 * (1 - _tagline.value)),
                        child: Text(
                          'Your Smile is Our Destination',
                          style: TextStyle(color: brandBlack.withValues(alpha: 0.75), fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Opacity(opacity: _tagline.value, child: _loadingDots()),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Transform.translate(
                  offset: Offset(0, 180 * (1 - _road.value)),
                  child: const AnimatedTaxiRoad(height: 180),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _logoCard() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(38),
        boxShadow: [BoxShadow(color: brandBlack.withValues(alpha: 0.25), blurRadius: 30, offset: const Offset(0, 14))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(38),
        child: Image.asset(ic_app_logo, fit: BoxFit.cover),
      ),
    );
  }

  Widget _animatedTitle() {
    final letters = mAppName.split('');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < letters.length; i++)
          Builder(builder: (context) {
            final begin = math.min(0.35 + i * 0.05, 0.75);
            final t = Interval(begin, begin + 0.25, curve: Curves.easeOutBack).transform(_intro.value);
            return Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, 24 * (1 - t)),
                child: Text(
                  letters[i],
                  style: TextStyle(color: brandBlack, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _loadingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final wave = math.sin(_pulse.value * 2 * math.pi - i * 0.9);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          child: Transform.scale(
            scale: 0.6 + 0.4 * (wave + 1) / 2,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(color: i == 1 ? brandBlue : brandBlack, shape: BoxShape.circle),
            ),
          ),
        );
      }),
    );
  }

  void _checkNotifyPermission() async {
    String versionNo =
        sharedPref.getString(CURRENT_LAN_VERSION) ?? LanguageVersion;
    await getLanguageList(versionNo).then((value) {
      appStore.setLoading(false);
      app_update_check = value.rider_version;
      if (value.status == true) {
        setValue(CURRENT_LAN_VERSION, value.currentVersionNo.toString());
        if (value.data!.length > 0) {
          defaultServerLanguageData = value.data;
          performLanguageOperation(defaultServerLanguageData);
          setValue(LanguageJsonDataRes, value.toJson());
          bool isSetLanguage =
              sharedPref.getBool(IS_SELECTED_LANGUAGE_CHANGE) ?? false;
          if (!isSetLanguage) {
            for (int i = 0; i < value.data!.length; i++) {
              if (value.data![i].isDefaultLanguage == 1) {
                setValue(SELECTED_LANGUAGE_CODE, value.data![i].languageCode);
                setValue(
                    SELECTED_LANGUAGE_COUNTRY_CODE, value.data![i].countryCode);
                appStore.setLanguage(value.data![i].languageCode!,
                    context: context);
                break;
              }
            }
          }
        } else {
          defaultServerLanguageData = [];
          selectedServerLanguageData = null;
          setValue(LanguageJsonDataRes, "");
        }
      } else {
        String getJsonData = sharedPref.getString(LanguageJsonDataRes) ?? '';

        if (getJsonData.isNotEmpty) {
          ServerLanguageResponse languageSettings =
              ServerLanguageResponse.fromJson(json.decode(getJsonData.trim()));
          if (languageSettings.data!.length > 0) {
            defaultServerLanguageData = languageSettings.data;
            performLanguageOperation(defaultServerLanguageData);
          }
        }
      }
    }).catchError((error) {
      appStore.setLoading(false);
      log(error);
    });
    init();
    // if (await Permission.notification.isGranted) {
    //   init();
    // } else {
    //   await Permission.notification.request();
    //   init();
    // }
  }
}

/// Soft drifting light spots over the yellow background.
class _GlowPainter extends CustomPainter {
  final double t;

  _GlowPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final a = t * 2 * math.pi;
    void glow(Offset c, double r, Color color) {
      canvas.drawCircle(
        c,
        r,
        Paint()..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    glow(Offset(size.width * (0.2 + 0.04 * math.sin(a)), size.height * 0.16), size.width * 0.6, Colors.white.withValues(alpha: 0.35));
    glow(Offset(size.width * (0.85 + 0.03 * math.cos(a)), size.height * 0.55), size.width * 0.5, brandLightBlue.withValues(alpha: 0.10));
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) => oldDelegate.t != t;
}

/// White rings pulsing outward behind the logo.
class _RipplePainter extends CustomPainter {
  final double t;
  final double opacity;

  _RipplePainter(this.t, this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.drawCircle(center, 100, Paint()..color = Colors.white.withValues(alpha: 0.22 * opacity));
    for (var i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1.0;
      canvas.drawCircle(
        center,
        90 + p * 50,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = Colors.white.withValues(alpha: (1 - p) * 0.7 * opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) => oldDelegate.t != t || oldDelegate.opacity != opacity;
}
