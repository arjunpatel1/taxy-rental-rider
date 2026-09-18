package com.mighty.taxirider

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var pendingUpiResult: MethodChannel.Result? = null
    private val upiRequestCode = 7201

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "staxi/upi_payment")
            .setMethodCallHandler { call, result ->
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
                        pendingUpiResult = result
                        try {
                            startActivityForResult(Intent.createChooser(intent, "Pay with UPI"), upiRequestCode)
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
