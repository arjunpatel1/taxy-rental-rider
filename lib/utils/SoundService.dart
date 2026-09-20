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

  /// Set when the admin uploaded their own tone. It is streamed from the server
  /// because a tone that is not bundled in the app cannot be an Android
  /// notification sound, so only in-app alerts can use it.
  static String? tripToneUrl;
  static String? notificationToneUrl;

  /// Called once the app settings are loaded from the server.
  static void applySettings({
    String? tripToneKey,
    String? notificationToneKey,
    bool? trip,
    bool? notification,
    String? tripUrl,
    String? notificationUrl,
  }) {
    if (tripToneKey != null && tones.containsKey(tripToneKey)) tripTone = tripToneKey;
    if (notificationToneKey != null && tones.containsKey(notificationToneKey)) notificationTone = notificationToneKey;
    if (trip != null) tripEnabled = trip;
    if (notification != null) notificationEnabled = notification;
    tripToneUrl = (tripUrl != null && tripUrl.isNotEmpty) ? tripUrl : null;
    notificationToneUrl = (notificationUrl != null && notificationUrl.isNotEmpty) ? notificationUrl : null;
  }

  static Source _source(String? url, String toneKey, String fallbackKey) {
    if (url != null) return UrlSource(url);
    return AssetSource(tones[toneKey] ?? tones[fallbackKey]!);
  }

  /// Ride request / trip assigned: keeps ringing until [stopTripAlert].
  static Future<void> startTripAlert({bool loop = true}) async {
    if (!tripEnabled) return;
    try {
      await _tripPlayer.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);
      await _tripPlayer.stop();
      await _tripPlayer.play(_source(tripToneUrl, tripTone, 'ride_get_sound'));
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
      await _notifyPlayer.play(_source(notificationToneUrl, notificationTone, 'default_app_sound'));
    } catch (e) {
      debugPrint('notification sound: $e');
    }
  }
}
