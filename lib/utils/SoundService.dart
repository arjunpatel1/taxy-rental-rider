import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Plays the two S Taxi alert sounds. Which tone is used, and whether it plays at all,
/// comes from the admin settings (sound_trip_* and sound_notification_* in app settings).
class SoundService {
  SoundService._();

  static final AudioPlayer _tripPlayer = AudioPlayer();
  static final AudioPlayer _notifyPlayer = AudioPlayer();

  /// The four tones the admin can pick under Push Notification > App Alert Sounds.
  /// Same names as the Android notification sounds, so a push and an in-app alert match.
  static const tones = <String, String>{
    'default_app_sound': 'sounds/default_app_sound.wav',
    'ride_get_sound': 'sounds/ride_get_sound.wav',
    'alert': 'sounds/alert.wav',
    'alert_new': 'sounds/alert_new.wav',
  };

  static bool tripEnabled = true;
  static bool notificationEnabled = true;
  static String tripTone = 'ride_get_sound';
  static String notificationTone = 'default_app_sound';

  /// Called once the app settings are loaded from the server.
  static void applySettings({String? tripToneKey, String? notificationToneKey, bool? trip, bool? notification}) {
    if (tripToneKey != null && tones.containsKey(tripToneKey)) tripTone = tripToneKey;
    if (notificationToneKey != null && tones.containsKey(notificationToneKey)) notificationTone = notificationToneKey;
    if (trip != null) tripEnabled = trip;
    if (notification != null) notificationEnabled = notification;
  }

  /// Ride request / trip assigned: keeps ringing until [stopTripAlert].
  static Future<void> startTripAlert({bool loop = true}) async {
    if (!tripEnabled) return;
    try {
      await _tripPlayer.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);
      await _tripPlayer.stop();
      await _tripPlayer.play(AssetSource(tones[tripTone] ?? tones['ride_get_sound']!));
    } catch (e) {
      debugPrint('trip alert sound: $e');
    }
  }

  static Future<void> stopTripAlert() async {
    try {
      await _tripPlayer.stop();
    } catch (e) {
      debugPrint('stop trip alert: $e');
    }
  }

  /// Any other notification (cancelled, arrived, admin message, wallet, ...): one short tone.
  static Future<void> playNotification() async {
    if (!notificationEnabled) return;
    try {
      await _notifyPlayer.stop();
      await _notifyPlayer.play(AssetSource(tones[notificationTone] ?? tones['default_app_sound']!));
    } catch (e) {
      debugPrint('notification sound: $e');
    }
  }
}
