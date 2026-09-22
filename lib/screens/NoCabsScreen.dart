import '../components/NoServiceView.dart';
import '../manage_imports.dart';

/// Full screen shown when a search ends with no driver accepting the trip.
class NoCabsScreen extends StatefulWidget {
  final int rideId;

  const NoCabsScreen({super.key, required this.rideId});

  @override
  State<NoCabsScreen> createState() => _NoCabsScreenState();
}

class _NoCabsScreenState extends State<NoCabsScreen> {
  bool busy = false;

  Future<void> _tryAgain() async {
    setState(() => busy = true);
    try {
      await retryRideRequest(widget.rideId);
      if (!mounted) return;
      // The booking dashboard picks up the new search and shows it.
      launchScreen(context, DashBoardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
    } catch (e) {
      toast(e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) launchScreen(context, HomeScreen(), isNewTask: true);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close_rounded, color: Colors.black87),
            onPressed: () => launchScreen(context, HomeScreen(), isNewTask: true),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: NoServiceView(outsideArea: false, onTryAgain: _tryAgain, busy: busy),
          ),
        ),
      ),
    );
  }
}
