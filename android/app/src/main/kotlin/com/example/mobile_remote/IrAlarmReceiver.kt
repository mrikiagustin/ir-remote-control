package com.example.mobile_remote

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.hardware.ConsumerIrManager
import android.os.Build
import android.os.PowerManager
import android.os.SystemClock
import androidx.core.app.NotificationCompat

class IrAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
        val wakeLock = powerManager?.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "MobileRemote:IrAlarmWakeLock"
        )
        wakeLock?.acquire(15000)

        val frequency = intent.getIntExtra("frequency", 38000)
        val pattern = intent.getIntArrayExtra("pattern")
        val actionType = intent.getStringExtra("actionType") ?: "OFF" // "OFF", "ON", "ON_RESEND"
        val isResend = intent.getBooleanExtra("isResend", false)

        if (pattern != null && pattern.isNotEmpty()) {
            val irManager = context.getSystemService(Context.CONSUMER_IR_SERVICE) as? ConsumerIrManager
            if (irManager != null && irManager.hasIrEmitter()) {
                try {
                    irManager.transmit(frequency, pattern)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }

        if (actionType == "ON" && !isResend) {
            // Jadwalkan resend sinyal ON otomatis 10 detik kedepan via AlarmManager
            try {
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                val resendIntent = Intent(context, IrAlarmReceiver::class.java).apply {
                    putExtra("frequency", frequency)
                    putExtra("pattern", pattern)
                    putExtra("actionType", "ON")
                    putExtra("isResend", true)
                }
                val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val resendPendingIntent = PendingIntent.getBroadcast(
                    context,
                    997, // Request code khusus untuk ON resend
                    resendIntent,
                    flags
                )
                val triggerAtMillis = SystemClock.elapsedRealtime() + 10000L
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager?.setExactAndAllowWhileIdle(
                        AlarmManager.ELAPSED_REALTIME_WAKEUP,
                        triggerAtMillis,
                        resendPendingIntent
                    )
                } else {
                    alarmManager?.setExact(
                        AlarmManager.ELAPSED_REALTIME_WAKEUP,
                        triggerAtMillis,
                        resendPendingIntent
                    )
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        val notifTitle = if (actionType == "ON") {
            if (isResend) "Timer AC: Resend ON (+10s)" else "Timer AC: Turn ON"
        } else {
            "Timer AC: Turn OFF"
        }
        val notifContent = if (actionType == "ON") {
            if (isResend) "Sinyal IR Turn ON cadangan (+10s) berhasil dikirim ulang."
            else "Sinyal IR Turn ON telah dikirim ke AC (resend otomatis dalam 10s)."
        } else {
            "Sinyal IR Turn OFF telah dikirim ke AC."
        }
        val notifId = if (actionType == "ON") 1002 else 1001

        showNotification(context, notifTitle, notifContent, notifId)

        if (!isResend) {
            val callbackAction = if (actionType == "ON") {
                "com.example.mobile_remote.AC_TURNED_ON"
            } else {
                "com.example.mobile_remote.AC_TURNED_OFF"
            }
            val callbackIntent = Intent(callbackAction)
            context.sendBroadcast(callbackIntent)
        }

        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
    }

    private fun showNotification(context: Context, title: String, content: String, notificationId: Int) {
        val channelId = "ir_timer_channel"
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Timer AC",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifikasi status timer AC otomatis"
            }
            notificationManager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_lock_power_off)
            .setContentTitle(title)
            .setContentText(content)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        notificationManager.notify(notificationId, notification)
    }
}
