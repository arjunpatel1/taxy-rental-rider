package com.mighty.taxirider

import android.app.Activity
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ActivityNotFoundException
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var pendingUpiResult: MethodChannel.Result? = null
    private val upiRequestCode = 7201

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val manager = getSystemService(NotificationManager::class.java)
        val attributes = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_NOTIFICATION).build()
        listOf("default_app_sound", "ride_get_sound", "alert", "alert_new").forEach { sound ->
            val channel = NotificationChannel("staxi_$sound", "S Taxi ${sound.replace('_', ' ')}", NotificationManager.IMPORTANCE_HIGH)
            channel.enableVibration(true)
            channel.setSound(Uri.parse("android.resource://$packageName/raw/$sound"), attributes)
            manager.createNotificationChannel(channel)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "staxi/notifications")
            .setMethodCallHandler { call, result ->
                if (call.method != "show") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val requestedSound = call.argument<String>("sound") ?: "default_app_sound"
                val sound = requestedSound.takeIf { it in setOf("default_app_sound", "ride_get_sound", "alert", "alert_new") }
                    ?: "default_app_sound"
                val title = call.argument<String>("title") ?: "S Taxi"
                val body = call.argument<String>("body") ?: ""
                val id = call.argument<String>("id") ?: System.currentTimeMillis().toString()
                val openApp = PendingIntent.getActivity(
                    this, 0, Intent(this, MainActivity::class.java),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                val notification = Notification.Builder(this, "staxi_$sound")
                    .setSmallIcon(R.mipmap.ic_launcher)
                    .setContentTitle(title)
                    .setContentText(body)
                    .setContentIntent(openApp)
                    .setAutoCancel(true)
                    .setCategory(Notification.CATEGORY_MESSAGE)
                    .setVisibility(Notification.VISIBILITY_PUBLIC)
                    .build()
                try {
                    getSystemService(NotificationManager::class.java).notify(id.hashCode(), notification)
                    result.success(null)
                } catch (error: SecurityException) {
                    result.error("NOTIFICATION_PERMISSION", error.message, null)
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "staxi/upi_payment")
            .setMethodCallHandler { call, result ->
                // The UPI apps installed on this phone, so the rider can pick
                // one inside the app. The system chooser is unreliable for UPI:
                // on many phones it opens empty, or returns "cancelled" even
                // after a payment went through.
                if (call.method == "listUpiApps") {
                    val probe = Intent(Intent.ACTION_VIEW, Uri.parse("upi://pay"))
                    val apps = packageManager.queryIntentActivities(probe, 0).map {
                        mapOf(
                            "package" to it.activityInfo.packageName,
                            "name" to it.loadLabel(packageManager).toString()
                        )
                    }
                    result.success(apps)
                    return@setMethodCallHandler
                }
                if (call.method != "pay") {
                    result.notImplemented()
                } else if (pendingUpiResult != null) {
                    result.error("BUSY", "A UPI payment is already open", null)
                } else {
                    val uri = Uri.parse(call.argument<String>("uri") ?: "")
                    if (uri.scheme != "upi" || uri.host != "pay") {
                        result.error("INVALID_URI", "Invalid UPI payment link", null)
                    } else {
                        val intent = Intent(Intent.ACTION_VIEW, uri)
                        if (intent.resolveActivity(packageManager) == null) {
                            result.error("NO_UPI_APP", "No UPI app found", null)
                            return@setMethodCallHandler
                        }
                        // Sent straight to the app the rider picked when there is
                        // one; a named package also stands a far better chance of
                        // returning its result than the chooser does.
                        val target = call.argument<String>("package")
                        if (!target.isNullOrEmpty()) intent.setPackage(target)
                        pendingUpiResult = result
                        try {
                            startActivityForResult(
                                if (target.isNullOrEmpty()) Intent.createChooser(intent, "Pay with UPI") else intent,
                                upiRequestCode
                            )
                        } catch (error: ActivityNotFoundException) {
                            pendingUpiResult = null
                            result.error("NO_UPI_APP", "No UPI app found", null)
                        }
                    }
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != upiRequestCode) return
        val result = pendingUpiResult ?: return
        pendingUpiResult = null
        val response = data?.getStringExtra("response") ?: data?.dataString ?: ""
        result.success(mapOf("response" to response, "cancelled" to (resultCode == Activity.RESULT_CANCELED)))
    }
}
