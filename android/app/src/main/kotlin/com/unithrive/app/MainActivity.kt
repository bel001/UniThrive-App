package com.unithrive.app

import android.content.Intent
import android.provider.AlarmClock
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.unithrive.app/alarm_clock"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openAlarmClock" -> {
                    val title = call.argument<String>("title") ?: "UniThrive"
                    val hour = call.argument<Int>("hour")
                    val minute = call.argument<Int>("minute")
                    val intent = if (hour != null && minute != null) {
                        Intent(AlarmClock.ACTION_SET_ALARM).apply {
                            putExtra(AlarmClock.EXTRA_MESSAGE, title)
                            putExtra(AlarmClock.EXTRA_HOUR, hour)
                            putExtra(AlarmClock.EXTRA_MINUTES, minute)
                            putExtra(AlarmClock.EXTRA_SKIP_UI, false)
                        }
                    } else {
                        Intent(AlarmClock.ACTION_SHOW_ALARMS)
                    }
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    if (intent.resolveActivity(packageManager) != null) {
                        startActivity(intent)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
