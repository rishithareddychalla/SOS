package com.example.sos_app

import android.Manifest // Add this import
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.telecom.TelecomManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.ArrayList

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.sos_app/conference_call"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "startConferenceCall") {
                val numbers = call.argument<ArrayList<String>>("numbers")
                if (numbers != null && numbers.isNotEmpty()) {
                    startSingleCall(numbers)
                    result.success("Call initiated")
                } else {
                    result.error("INVALID_ARGUMENT", "Phone number list cannot be null or empty.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun startSingleCall(numbers: ArrayList<String>) {
        // Dial the first number
        val firstNumber = numbers[0]
        val uri = Uri.fromParts("tel", firstNumber, null)
        val extras = Bundle()

        // Check for CALL_PHONE permission before placing the call
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) == PackageManager.PERMISSION_GRANTED) {
            val telecomManager = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
            try {
                telecomManager.placeCall(uri, extras)
            } catch (e: SecurityException) {
                // Handle permission issues
                result?.error("PERMISSION_DENIED", "Unable to place call due to permission issues", null)
            }
        } else {
            // Permission not granted; handle in Flutter
            result?.error("PERMISSION_DENIED", "CALL_PHONE permission not granted", null)
        }
    }

    private var result: MethodChannel.Result? = null // Store result for error reporting
}