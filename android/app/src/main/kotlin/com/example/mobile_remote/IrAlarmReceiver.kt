package com.example.mobile_remote

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.hardware.ConsumerIrManager
import android.os.Build
import android.os.PowerManager
import androidx.core.app.NotificationCompat

class IrAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
        val wakeLock = powerManager?.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "MobileRemote:IrAlarmWakeLock"
        )
        wakeLock?.acquire(10000)

        val frequency = intent.getIntExtra("frequency", 38000)
        val pattern = intent.getIntArrayExtra("pattern")
        val actionType = intent.getStringExtra("actionType") ?: "OFF" // "OFF" or "ON"

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

        val notifTitle = if (actionType == "ON") "Timer AC: Turn ON" else "Timer AC: Turn OFF"
        val notifContent = if (actionType == "ON") {
            "Sinyal IR Turn ON telah dikirim ke AC."
        } else {
            "Sinyal IR Turn OFF telah dikirim ke AC."
        }
        val notifId = if (actionType == "ON") 1002 else 1001

        showNotification(context, notifTitle, notifContent, notifId)

        val callbackAction = if (actionType == "ON") {
            "com.example.mobile_remote.AC_TURNED_ON"
        } else {
            "com.example.mobile_remote.AC_TURNED_OFF"
        }
        val callbackIntent = Intent(callbackAction)
        context.sendBroadcast(callbackIntent)

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
