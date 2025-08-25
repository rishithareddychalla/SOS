package com.example.sos_app // Make sure this matches your package name

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.telecom.TelecomManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.core.content.ContextCompat
import android.Manifest
import android.content.pm.PackageManager

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.sos_app/conference_call"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "startConferenceCall") {
                val numbers = call.argument<ArrayList<String>>("numbers")
                if (numbers != null && numbers.isNotEmpty()) {
                    startConferenceCall(numbers)
                    result.success("Conference call started")
                } else {
                    result.error("INVALID_ARGUMENT", "Phone number list cannot be null or empty.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun startConferenceCall(numbers: ArrayList<String>) {
        val telecomManager = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
        val phoneAccountHandleList = telecomManager.callCapablePhoneAccounts
        
        if (phoneAccountHandleList.isNotEmpty()) {
            val phoneAccountHandle = phoneAccountHandleList[0] // Use the first available phone account
            val extras = Bundle()
            val callExtras = Bundle()
            
            // Add additional numbers for the conference
            val conferenceUris = ArrayList<Uri>()
            for (i in 1 until numbers.size) {
                conferenceUris.add(Uri.fromParts("tel", numbers[i], null))
            }
            callExtras.putParcelableArrayList(TelecomManager.EXTRA_PHONE_ACCOUNT_HANDLE, conferenceUris)
            extras.putBundle(TelecomManager.EXTRA_OUTGOING_CALL_EXTRAS, callExtras)

            val uri = Uri.fromParts("tel", numbers[0], null)
            
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) == PackageManager.PERMISSION_GRANTED) {
                telecomManager.placeCall(uri, extras)
            }
        }
    }
}