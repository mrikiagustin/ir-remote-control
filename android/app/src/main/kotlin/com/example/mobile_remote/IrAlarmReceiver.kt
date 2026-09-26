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
            "MobileRemote:IrSleepWakeLock"
        )
        wakeLock?.acquire(10000) // Tahan CPU 10 detik

        val frequency = intent.getIntExtra("frequency", 38000)
        val pattern = intent.getIntArrayExtra("pattern")

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

        // Tampilkan notifikasi konfirmasi bahwa AC sudah dimatikan
        showNotification(context)

        // Broadcast event ke Flutter jika sedang hidup/foreground
        val callbackIntent = Intent("com.example.mobile_remote.AC_TURNED_OFF")
        context.sendBroadcast(callbackIntent)

        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
    }

    private fun showNotification(context: Context) {
        val channelId = "ir_sleep_timer_channel"
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Timer Sleep AC",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifikasi status pematian AC otomatis"
            }
            notificationManager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_lock_power_off)
            .setContentTitle("Timer Sleep AC")
            .setContentText("Sinyal IR Turn Off telah dikirim ke AC.")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        notificationManager.notify(1001, notification)
    }
}
