import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Plays the two S Taxi alert sounds. Which tone is used, and whether it plays at all,
/// comes from the admin settings (sound_trip_* and sound_notification_* in app settings).
class SoundService {
  SoundService._();

  static final AudioPlayer _tripPlayer = AudioPlayer();
  static final AudioPlayer _notifyPlayer = AudioPlayer();

  /// Tones shipped with the app; the admin setting stores one of these keys.
  static const tones = <String, String>{
    'chime': 'sounds/notification.wav',
    'alert': 'sounds/trip_alert.wav',
    'ring': 'sounds/rideringtone.mp3',
  };

  static bool tripEnabled = true;
  static bool notificationEnabled = true;
  static String tripTone = 'ring';
  static String notificationTone = 'chime';

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
      await _tripPlayer.play(AssetSource(tones[tripTone] ?? tones['ring']!));
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
      await _notifyPlayer.play(AssetSource(tones[notificationTone] ?? tones['chime']!));
    } catch (e) {
      debugPrint('notification sound: $e');
    }
  }
}
