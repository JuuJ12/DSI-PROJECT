package com.example.dsi_project

import android.content.pm.PackageManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val CHANNEL = "dsi_project/maps"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			if (call.method == "getMapsApiKey") {
				try {
					val ai = applicationContext.packageManager.getApplicationInfo(applicationContext.packageName, PackageManager.GET_META_DATA)
					val bundle = ai.metaData
					// Try the standard Google Maps meta-data key first, then fall back to MAPS_API_KEY
					val apiKey = bundle?.getString("com.google.android.geo.API_KEY")
						?: bundle?.getString("MAPS_API_KEY")
						?: ""
					Log.d("MainActivity", "getMapsApiKey -> '${apiKey.takeIf { it.isNotEmpty() } ?: "<empty>"}'")
					result.success(apiKey)
				} catch (e: Exception) {
					Log.e("MainActivity", "Error reading MAPS API key", e)
					result.success("")
				}
			} else {
				result.notImplemented()
			}
		}
	}
}
