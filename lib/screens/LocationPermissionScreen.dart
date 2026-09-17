import '../manage_imports.dart';
import '../utils/BrandTheme.dart';

/// Shown when the app cannot read the location. It closes itself as soon as location works,
/// including when the rider enables it from system settings and comes back.
class LocationPermissionScreen extends StatefulWidget {
  @override
  LocationPermissionScreenState createState() => LocationPermissionScreenState();
}

class LocationPermissionScreenState extends State<LocationPermissionScreen> with WidgetsBindingObserver {
  bool checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // the screen may have been opened after a one-off GPS timeout: close straight away if location is fine
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryContinue(requestIfNeeded: false));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _tryContinue(requestIfNeeded: false);
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Future<void> _tryContinue({bool requestIfNeeded = true}) async {
    if (checking) return;
    setState(() => checking = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestIfNeeded) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever && requestIfNeeded) {
        toast(language.pleaseEnableLocationPermission);
        await Geolocator.openAppSettings();
      } else if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        if (!await Geolocator.isLocationServiceEnabled()) {
          if (requestIfNeeded) await Geolocator.openLocationSettings();
        } else {
          try {
            final position = await Geolocator.getCurrentPosition().timeout(Duration(seconds: 12));
            sharedPref.setDouble(LATITUDE, position.latitude);
            sharedPref.setDouble(LONGITUDE, position.longitude);
          } catch (_) {
            // a slow GPS fix is not a permission problem; the map keeps trying on its own
          }
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
            return;
          }
        }
      }
    } catch (e) {
      log('location permission: $e');
    }
    setState(() => checking = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        key: locationScreenKey,
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              children: [
                Spacer(),
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(color: BrandTokens.blueSoft, shape: BoxShape.circle),
                  child: Lottie.asset(locationAnim, fit: BoxFit.contain),
                ),
                SizedBox(height: 32),
                Text('Turn on location', style: boldTextStyle(size: 24), textAlign: TextAlign.center),
                SizedBox(height: 10),
                Text(
                  'S Taxi uses your location to set the pickup point, show nearby cabs and share your live trip for safety.',
                  style: secondaryTextStyle(size: 14),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                _point(Icons.my_location_rounded, 'Accurate pickup, no calling the driver'),
                _point(Icons.local_taxi_rounded, 'See cabs near you in real time'),
                _point(Icons.shield_outlined, 'Live trip tracking for your safety'),
                Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: checking ? null : () => _tryContinue(),
                    child: checking
                        ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                        : Text('Allow location access'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _point(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: BrandTokens.blueSoft, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: BrandTokens.blue),
          ),
          SizedBox(width: 12),
          Expanded(child: Text(text, style: primaryTextStyle(size: 14))),
        ],
      ),
    );
  }
}
