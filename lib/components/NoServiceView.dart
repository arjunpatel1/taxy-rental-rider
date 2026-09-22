import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../utils/Colors.dart';
import '../utils/Extensions/app_common.dart';

/// Shown when a booking cannot go ahead: either no cab accepted the trip, or
/// the pickup is outside the area S Taxi serves. Both offer a call to the
/// office so the rider can still book; only the no-cab case offers a retry,
/// because searching again from outside the service area would never succeed.
class NoServiceView extends StatelessWidget {
  final bool outsideArea;
  final VoidCallback? onTryAgain;
  final bool busy;

  const NoServiceView({super.key, required this.outsideArea, this.onTryAgain, this.busy = false});

  String get _supportNumber =>
      (appStore.settingModel.contactNumber ?? '').replaceAll(RegExp(r'[^0-9+]'), '');

  Future<void> _call() async {
    if (_supportNumber.isEmpty) {
      toast('Support number is not set yet.');
      return;
    }
    try {
      await launchUrl(Uri.parse('tel:$_supportNumber'), mode: LaunchMode.externalApplication);
    } catch (_) {
      toast('Could not start the call.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = outsideArea ? 'S Taxi is not available in this area yet' : 'No Cabs Available';
    final subtitle = outsideArea
        ? 'We are currently serving only in selected areas. This location is outside our service area.'
        : 'There are currently no cabs available in your area.';

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(color: Color(0xFFFFF4D6), shape: BoxShape.circle),
            child: Icon(outsideArea ? Icons.wrong_location_rounded : Icons.no_crash_rounded,
                size: 56, color: Color(0xFFE8A200)),
          ),
          SizedBox(height: 20),
          Text(title, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF14213D))),
          SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.4, color: Colors.grey.shade700)),
          SizedBox(height: 24),
          _button(
            filled: true,
            icon: Icons.call_rounded,
            title: outsideArea ? 'Call Us' : 'Call to Book',
            subtitle: outsideArea ? "We'll help you book a cab" : null,
            onTap: _call,
          ),
          if (!outsideArea) ...[
            SizedBox(height: 12),
            _button(
              filled: false,
              icon: Icons.refresh_rounded,
              title: busy ? 'Searching...' : 'Try Again',
              onTap: busy ? null : onTryAgain,
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(color: Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Icon(Icons.support_agent_rounded, color: primaryColor),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Need a cab urgently? Call us and our team will help you book a cab.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _button({required bool filled, required IconData icon, required String title, String? subtitle, VoidCallback? onTap}) {
    final color = filled ? Color(0xFFFFCC33) : Colors.white;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: filled ? null : Border.all(color: primaryColor, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: filled ? Color(0xFF14213D) : primaryColor),
              SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                        color: filled ? Color(0xFF14213D) : primaryColor)),
                    if (subtitle != null)
                      Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
