package com.example.mobile_remote

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.ConsumerIrManager
import android.os.Build
import android.os.SystemClock
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.mobile_remote/ir"
    private val EVENT_CHANNEL = "com.example.mobile_remote/events"
    private var irManager: ConsumerIrManager? = null
    private var eventSink: EventChannel.EventSink? = null

    private val acEventReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                "com.example.mobile_remote.AC_TURNED_OFF" -> eventSink?.success("AC_OFF_FIRED")
                "com.example.mobile_remote.AC_TURNED_ON" -> eventSink?.success("AC_ON_FIRED")
            }
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            irManager = getSystemService(Context.CONSUMER_IR_SERVICE) as? ConsumerIrManager
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    val filter = IntentFilter().apply {
                        addAction("com.example.mobile_remote.AC_TURNED_OFF")
                        addAction("com.example.mobile_remote.AC_TURNED_ON")
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        registerReceiver(acEventReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
                    } else {
                        registerReceiver(acEventReceiver, filter)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    try {
                        unregisterReceiver(acEventReceiver)
                    } catch (e: Exception) {
                        // ignore
                    }
                    eventSink = null
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasIrEmitter" -> {
                    val hasIr = irManager?.hasIrEmitter() ?: false
                    result.success(hasIr)
                }
                "getCarrierFrequencies" -> {
                    if (irManager?.hasIrEmitter() == true) {
                        val ranges = irManager?.carrierFrequencies
                        val list = mutableListOf<Map<String, Int>>()
                        ranges?.forEach { range ->
                            list.add(mapOf("min" to range.minFrequency, "max" to range.maxFrequency))
                        }
                        result.success(list)
                    } else {
                        result.success(emptyList<Map<String, Int>>())
                    }
                }
                "transmit" -> {
                    val frequency = call.argument<Int>("frequency") ?: 38000
                    val patternList = call.argument<List<Int>>("pattern")
                    if (patternList == null || patternList.isEmpty()) {
                        result.error("INVALID_ARGUMENT", "Pattern cannot be empty", null)
                        return@setMethodCallHandler
                    }

                    if (irManager == null || !irManager!!.hasIrEmitter()) {
                        result.error("NO_IR_EMITTER", "Device does not have an IR emitter", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val pattern = patternList.toIntArray()
                        irManager!!.transmit(frequency, pattern)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("TRANSMIT_FAILED", e.localizedMessage, null)
                    }
                }
                "scheduleSleepTimer" -> {
                    val delaySeconds = call.argument<Int>("delaySeconds") ?: 0
                    val frequency = call.argument<Int>("frequency") ?: 38000
                    val patternList = call.argument<List<Int>>("pattern")
                    val actionType = call.argument<String>("actionType") ?: "OFF" // "OFF" or "ON"
                    val requestCode = if (actionType == "ON") 998 else 999

                    if (patternList == null || patternList.isEmpty() || delaySeconds <= 0) {
                        result.error("INVALID_ARGUMENT", "Invalid delay or pattern", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                        val intent = Intent(this, IrAlarmReceiver::class.java).apply {
                            putExtra("frequency", frequency)
                            putExtra("pattern", patternList.toIntArray())
                            putExtra("actionType", actionType)
                        }

                        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        } else {
                            PendingIntent.FLAG_UPDATE_CURRENT
                        }

                        val pendingIntent = PendingIntent.getBroadcast(
                            this,
                            requestCode,
                            intent,
                            flags
                        )

                        val triggerAtMillis = SystemClock.elapsedRealtime() + (delaySeconds * 1000L)

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            alarmManager?.setExactAndAllowWhileIdle(
                                AlarmManager.ELAPSED_REALTIME_WAKEUP,
                                triggerAtMillis,
                                pendingIntent
                            )
                        } else {
                            alarmManager?.setExact(
                                AlarmManager.ELAPSED_REALTIME_WAKEUP,
                                triggerAtMillis,
                                pendingIntent
                            )
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SCHEDULE_FAILED", e.localizedMessage, null)
                    }
                }
                "cancelSleepTimer" -> {
                    val actionType = call.argument<String>("actionType") ?: "OFF"
                    val requestCode = if (actionType == "ON") 998 else 999
                    try {
                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                        val intent = Intent(this, IrAlarmReceiver::class.java)
                        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        } else {
                            PendingIntent.FLAG_UPDATE_CURRENT
                        }
                        val pendingIntent = PendingIntent.getBroadcast(
                            this,
                            requestCode,
                            intent,
                            flags
                        )
                        alarmManager?.cancel(pendingIntent)

                        // Jika batalkan ON, batalkan juga pending resend (997)
                        if (actionType == "ON") {
                            val resendPendingIntent = PendingIntent.getBroadcast(
                                this,
                                997,
                                intent,
                                flags
                            )
                            alarmManager?.cancel(resendPendingIntent)
                        }

                        result.success(true)
                    } catch (e: Exception) {
                        result.error("CANCEL_FAILED", e.localizedMessage, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
