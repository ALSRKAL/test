package com.example.hajzy

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Create notification channels for Android 8.0+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createNotificationChannels()
        }
    }
    
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            
            // Chat messages channel (High priority)
            val chatChannel = NotificationChannel(
                "chat_channel",
                "رسائل المحادثة",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "إشعارات الرسائل الجديدة"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
            }
            
            // Bookings channel (High priority)
            val bookingChannel = NotificationChannel(
                "booking_channel",
                "الحجوزات",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "إشعارات الحجوزات الجديدة والتحديثات"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
            }
            
            // Reviews channel (Default priority)
            val reviewChannel = NotificationChannel(
                "review_channel",
                "التقييمات",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "إشعارات التقييمات الجديدة"
                enableVibration(true)
                setShowBadge(true)
            }
            
            // Default channel (Default priority)
            val defaultChannel = NotificationChannel(
                "default_channel",
                "إشعارات عامة",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "إشعارات التطبيق العامة"
                enableVibration(true)
                setShowBadge(true)
            }
            
            // Register all channels
            notificationManager.createNotificationChannel(chatChannel)
            notificationManager.createNotificationChannel(bookingChannel)
            notificationManager.createNotificationChannel(reviewChannel)
            notificationManager.createNotificationChannel(defaultChannel)
        }
    }
}
