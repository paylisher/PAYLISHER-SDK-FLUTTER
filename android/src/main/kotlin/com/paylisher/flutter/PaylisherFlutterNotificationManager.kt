package com.paylisher.flutter

import android.content.Context
import android.util.Log
import com.paylisher.android.notification.NotificationHelper
import com.paylisher.android.notification.NotificationPushData
import com.paylisher.android.notification.PushButton
import io.flutter.plugin.common.EventChannel
import com.google.gson.Gson
import com.paylisher.android.db.NotificationType

class PaylisherFlutterNotificationManager(private val context: Context) : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    private val TAG = "PaylisherFlutterNotif"
    private val gson = Gson()

    companion object {
        var instance: PaylisherFlutterNotificationManager? = null

        fun getInstance(context: Context): PaylisherFlutterNotificationManager {
            if (instance == null) {
                instance = PaylisherFlutterNotificationManager(context)
            }
            return instance!!
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        Log.d(TAG, "Notification EventChannel attached")
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        Log.d(TAG, "Notification EventChannel detached")
    }

    fun handleNotification(data: NotificationPushData) {
        val eventMap = mapOf(
            "event" to "notificationReceived",
            "data" to mapOf(
                "title" to data.title,
                "message" to data.message,
                "imageUrl" to data.imageUrl,
                "iconUrl" to data.iconUrl,
                "action" to data.action,
                "silent" to data.silent,
                "type" to getNotificationTypeString(data),
                "buttons" to data.buttons?.map { mapOf("label" to it.label, "action" to it.action) }
            )
        )
        
        eventSink?.success(eventMap) ?: Log.w(TAG, "EventSink is null, cannot send notification to Flutter")
    }

    private fun getNotificationTypeString(data: NotificationPushData): String {
        // You might need to adjust this based on how NotificationPushData stores type if not directly accessible or different mapping needed
        // Assuming we can infer or pass type. For now, defaulting to unknowns or checking properties if needed.
        // If NotificationPushData doesn't have a type field directly compatible with our Enum string, we need to map it.
        // Let's assume passed data has type info or we rely on what constructed it.
        // Ideally pass the type explicitly to this function.
        return "unknown" // Placeholder, logic to be refined based on PaylisherAndroid SDK internals
    }
    
    // Explicit method to forward from FcmMessagingService or similar
    fun forwardNotification(data: NotificationPushData, type: String) {
         val eventMap = mapOf(
            "event" to "notificationReceived",
            "data" to mapOf(
                "title" to data.title,
                "message" to data.message,
                "imageUrl" to data.imageUrl,
                "iconUrl" to data.iconUrl,
                "action" to data.action,
                "silent" to data.silent,
                "type" to type,
                "buttons" to data.buttons?.map { mapOf("label" to it.label, "action" to it.action) }
            )
        )
        eventSink?.success(eventMap)
    }

    fun createNotificationChannel(id: String, name: String, description: String) {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            val importance = android.app.NotificationManager.IMPORTANCE_DEFAULT
            val channel = android.app.NotificationChannel(id, name, importance).apply {
                this.description = description
            }
            val notificationManager: android.app.NotificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    fun sendEvent(eventMap: Map<String, Any>) {
        eventSink?.success(eventMap) ?: Log.w(TAG, "EventSink is null, cannot send event to Flutter")
    }
}
