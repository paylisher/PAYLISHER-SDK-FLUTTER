package com.paylisher.flutter

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.paylisher.PersonProfiles
import com.paylisher.Paylisher
import com.paylisher.PaylisherConfig
import com.paylisher.android.PaylisherAndroid
import com.paylisher.android.PaylisherAndroidConfig
import com.paylisher.android.internal.getApplicationInfo
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.Date

/** PaylisherFlutterPlugin */
class PaylisherFlutterPlugin :
    FlutterPlugin,
    MethodCallHandler {
    // / The MethodChannel that will be the communication between Flutter and native Android
    // /
    // / This local reference serves to register the plugin with the Flutter Engine and unregister it
    // / when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel

    private lateinit var applicationContext: Context

    private val snapshotSender = SnapshotSender()

    // The surveys delegate
    private var flutterSurveysDelegate: PaylisherFlutterSurveysDelegate? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "paylisher_flutter")

        this.applicationContext = flutterPluginBinding.applicationContext
        initPlugin()

        channel.setMethodCallHandler(this)
    }

    private fun initPlugin() {
        try {
            val ai = getApplicationInfo(applicationContext)
            val bundle = ai.metaData ?: Bundle()
            val autoInit = bundle.getBoolean("com.paylisher.paylisher.AUTO_INIT", true)

            if (!autoInit) {
                Log.i("Paylisher", "com.paylisher.paylisher.AUTO_INIT is disabled!")
                return
            }

            val apiKey = bundle.getString("com.paylisher.paylisher.API_KEY")

            if (apiKey.isNullOrEmpty()) {
                Log.e("Paylisher", "com.paylisher.paylisher.API_KEY is missing!")
                return
            }

            val host = bundle.getString("com.paylisher.paylisher.PAYLİSHER_HOST", PaylisherConfig.DEFAULT_HOST)
            val captureApplicationLifecycleEvents = bundle.getBoolean("com.paylisher.paylisher.TRACK_APPLICATION_LIFECYCLE_EVENTS", false)
            val debug = bundle.getBoolean("com.paylisher.paylisher.DEBUG", false)

            val paylisherConfig = mutableMapOf<String, Any>()
            paylisherConfig["apiKey"] = apiKey
            paylisherConfig["host"] = host
            paylisherConfig["captureApplicationLifecycleEvents"] = captureApplicationLifecycleEvents
            paylisherConfig["debug"] = debug

            setupPaylisher(paylisherConfig)
        } catch (e: Throwable) {
            Log.e("Paylisher", "initPlugin error: $e")
        }
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result,
    ) {
        when (call.method) {
            "setup" -> {
                setup(call, result)
            }
            "identify" -> {
                identify(call, result)
            }

            "capture" -> {
                capture(call, result)
            }

            "screen" -> {
                screen(call, result)
            }

            "alias" -> {
                alias(call, result)
            }

            "distinctId" -> {
                distinctId(result)
            }

            "reset" -> {
                reset(result)
            }

            "disable" -> {
                disable(result)
            }

            "enable" -> {
                enable(result)
            }

            "isOptOut" -> {
                isOptOut(result)
            }

            "isFeatureEnabled" -> {
                isFeatureEnabled(call, result)
            }

            "reloadFeatureFlags" -> {
                reloadFeatureFlags(result)
            }

            "group" -> {
                group(call, result)
            }

            "getFeatureFlag" -> {
                getFeatureFlag(call, result)
            }

            "getFeatureFlagPayload" -> {
                getFeatureFlagPayload(call, result)
            }

            "register" -> {
                register(call, result)
            }
            "unregister" -> {
                unregister(call, result)
            }
            "debug" -> {
                debug(call, result)
            }
            "flush" -> {
                flush(result)
            }
            "captureException" -> {
                captureException(call, result)
            }
            "close" -> {
                close(result)
            }
            "sendMetaEvent" -> {
                handleMetaEvent(call, result)
            }
            "sendFullSnapshot" -> {
                handleSendFullSnapshot(call, result)
            }
            "isSessionReplayActive" -> {
                result.success(isSessionReplayActive())
            }
            "getSessionId" -> {
                getSessionId(result)
            }
            "openUrl" -> {
                openUrl(call, result)
            }
            "surveyAction" -> {
                handleSurveyAction(call, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun isSessionReplayActive(): Boolean = Paylisher.isSessionReplayActive()

    private fun handleMetaEvent(
        call: MethodCall,
        result: Result,
    ) {
        try {
            val width = call.argument<Int>("width") ?: 0
            val height = call.argument<Int>("height") ?: 0
            val screen = call.argument<String>("screen") ?: ""

            if (width == 0 || height == 0) {
                result.error("INVALID_ARGUMENT", "Width or height is 0", null)
                return
            }

            snapshotSender.sendMetaEvent(width, height, screen)
            result.success(null)
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.localizedMessage, null)
        }
    }

    private fun setup(
        call: MethodCall,
        result: Result,
    ) {
        try {
            val args = call.arguments() as Map<String, Any>? ?: mapOf<String, Any>()
            if (args.isEmpty()) {
                result.error("PaylisherFlutterException", "Arguments is null or empty", null)
                return
            }

            setupPaylisher(args)

            result.success(null)
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.localizedMessage, null)
        }
    }

    private fun setupPaylisher(paylisherConfig: Map<String, Any>) {
        val apiKey = paylisherConfig["apiKey"] as String?
        if (apiKey.isNullOrEmpty()) {
            Log.e("Paylisher", "apiKey is missing!")
            return
        }

        val host = paylisherConfig["host"] as String? ?: PaylisherConfig.DEFAULT_HOST

        val config =
            PaylisherAndroidConfig(apiKey, host).apply {
                captureScreenViews = false
                captureDeepLinks = false
                paylisherConfig.getIfNotNull<Boolean>("captureApplicationLifecycleEvents") {
                    captureApplicationLifecycleEvents = it
                }
                paylisherConfig.getIfNotNull<Boolean>("debug") {
                    debug = it
                }
                paylisherConfig.getIfNotNull<Int>("flushAt") {
                    flushAt = it
                }
                paylisherConfig.getIfNotNull<Int>("maxQueueSize") {
                    maxQueueSize = it
                }
                paylisherConfig.getIfNotNull<Int>("maxBatchSize") {
                    maxBatchSize = it
                }
                paylisherConfig.getIfNotNull<Int>("flushInterval") {
                    flushIntervalSeconds = it
                }
                paylisherConfig.getIfNotNull<Boolean>("sendFeatureFlagEvents") {
                    sendFeatureFlagEvent = it
                }
                paylisherConfig.getIfNotNull<Boolean>("preloadFeatureFlags") {
                    preloadFeatureFlags = it
                }
                paylisherConfig.getIfNotNull<Boolean>("optOut") {
                    optOut = it
                }
                paylisherConfig.getIfNotNull<String>("personProfiles") {
                    when (it) {
                        "never" -> personProfiles = PersonProfiles.NEVER
                        "always" -> personProfiles = PersonProfiles.ALWAYS
                        "identifiedOnly" -> personProfiles = PersonProfiles.IDENTIFIED_ONLY
                    }
                }
                paylisherConfig.getIfNotNull<Boolean>("sessionReplay") {
                    sessionReplay = it
                }

                this.sessionReplayConfig.captureLogcat = false

                // Configure surveys
                paylisherConfig.getIfNotNull<Boolean>("surveys") {
                    surveys = it
                    if (surveys) {
                        // If surveys are enabled, create and assign the surveys delegate
                        val delegate = PaylisherFlutterSurveysDelegate(channel)
                        surveysConfig.surveysDelegate = delegate
                        flutterSurveysDelegate = delegate
                    }
                }

                // Configure error tracking autocapture
                paylisherConfig.getIfNotNull<Map<String, Any>>("errorTrackingConfig") { errorConfig ->
                    errorConfig.getIfNotNull<Boolean>("captureNativeExceptions") {
                        errorTrackingConfig.autoCapture = it
                    }
                    errorConfig.getIfNotNull<List<String>>("inAppIncludes") { includes ->
                        errorTrackingConfig.inAppIncludes.addAll(includes)
                    }
                }

                sdkName = "paylisher-flutter"
                sdkVersion = paylisherVersion
            }
        PaylisherAndroid.setup(applicationContext, config)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun handleSendFullSnapshot(
        call: MethodCall,
        result: Result,
    ) {
        try {
            val imageBytes = call.argument<ByteArray>("imageBytes")
            val id = call.argument<Int>("id") ?: 1
            val x = call.argument<Int>("x") ?: 0
            val y = call.argument<Int>("y") ?: 0
            if (imageBytes != null) {
                snapshotSender.sendFullSnapshot(imageBytes, id, x, y)
                result.success(null)
            } else {
                result.error("INVALID_ARGUMENT", "Image bytes are null", null)
            }
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.localizedMessage, null)
        }
    }

    private fun getFeatureFlag(
        call: MethodCall,
        result: Result,
    ) {
        try {
            val featureFlagKey: String = call.argument("key")!!
            val flag = Paylisher.getFeatureFlag(featureFlagKey)
            result.success(flag)
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.localizedMessage, null)
        }
    }

    private fun getFeatureFlagPayload(
        call: MethodCall,
        result: Result,
    ) {
        try {
            val featureFlagKey: String = call.argument("key")!!
            val flag = Paylisher.getFeatureFlagPayload(featureFlagKey)
            result.success(flag)
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.localizedMessage, null)
        }
    }

    private fun identify(
        call: MethodCall,
        result: Result,
    ) {
        try {
            val userId: String = call.argument("userId")!!
            val userProperties: Map<String, Any>? = call.argument("userProperties")
            val userPropertiesSetOnce: Map<String, Any>? = call.argument("userPropertiesSetOnce")
            Paylisher.identify(userId, userProperties, userPropertiesSetOnce)
            result.success(null)
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.localizedMessage, null)
        }
    }

    private fun capture(
        call: MethodCall,
        result: Result,
    ) {
        try {
            val eventName: String = call.argument("eventName")!!
            val properties: Map<String, Any>? = call.argument("properties")
            Paylisher.capture(eventName, properties = properties)
            result.success(null)
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.localizedMessage, null)
        }
    }

    private fun screen(
        call: MethodCall,
        result: Result,
    ) {
        try {
            val screenName: String = call.argument("screenName")!!
            val properties: Map<String, Any>? = call.argument("properties")
            Paylisher.screen(screenName, properties)
            result.success(null)
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.localizedMessage, null)
        }
    }

    private fun alias(
        call: MethodCall,
        result: Result,
    ) {
        try {
            val alias: String = call.argument("alias")!!
            Paylisher.alias(alias)
            result.success(null)
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.localizedMessage, null)
        }
    }

    private fun distinctId(result: Result) {
        try {
            val distinctId: String = Paylisher.distinctId()
            result.success(distinctId)
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.localizedMessage, null)
        }
    }

    private fun reset(result: Result) {
        try {
            Paylisher.reset()
            result.success(null)
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.localizedMessage, null)
        }
    }

    private fun enable(result: Result) {
        try {
            Paylisher.optIn()
            result.success(null)
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.localizedMessage, null)
        }
    }

    private fun debug(
        call: MethodCall,
        result: Result,
    ) {
        try {
            val debug: Boolean = call.argument("debug")!!
            Paylisher.debug(debug)
            result.success(null)
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.localizedMessage, null)
        }
    }

    private fun disable(result: Result) {
        try {
            Paylisher.optOut()
            result.success(null)
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.localizedMessage, null)
        }
    }

    private fun isOptOut(result: Result) {
        try {
            val isOptedOut = Paylisher.isOptOut()
            result.success(isOptedOut)
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.localizedMessage, null)
        }
    }

    private fun isFeatureEnabled(
        call: MethodCall,
        result: Result,
    ) {
        try {
            val key: String = call.argument("key")!!
            val isEnabled = Paylisher.isFeatureEnabled(key)
            result.success(isEnabled)
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.localizedMessage, null)
        }
    }

    private fun reloadFeatureFlags(result: Result) {
        try {
            Paylisher.reloadFeatureFlags()
            result.success(null)
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.localizedMessage, null)
        }
    }

    private fun group(
        call: MethodCall,
        result: Result,
    ) {
        try {
            val groupType: String = call.argument("groupType")!!
            val groupKey: String = call.argument("groupKey")!!
            val groupProperties: Map<String, Any>? = call.argument("groupProperties")
            Paylisher.group(groupType, groupKey, groupProperties)
            result.success(null)
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.localizedMessage, null)
        }
    }

    private fun register(
        call: MethodCall,
        result: Result,
    ) {
        try {
            val key: String = call.argument("key")!!
            val value: Any = call.argument("value")!!
            Paylisher.register(key, value)
            result.success(null)
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.localizedMessage, null)
        }
    }

    private fun unregister(
        call: MethodCall,
        result: Result,
    ) {
        try {
            val key: String = call.argument("key")!!
            Paylisher.unregister(key)
            result.success(null)
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.localizedMessage, null)
        }
    }

    private fun flush(result: Result) {
        try {
            Paylisher.flush()
            result.success(null)
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.localizedMessage, null)
        }
    }

    private fun captureException(
        call: MethodCall,
        result: Result,
    ) {
        try {
            val arguments =
                call.arguments as? Map<String, Any> ?: run {
                    result.error("INVALID_ARGUMENTS", "Invalid arguments for captureException", null)
                    return
                }

            val properties = arguments["properties"] as? Map<String, Any>
            val timestampMs = arguments["timestamp"] as? Long

            // Extract timestamp from Flutter
            val timestamp: Date? =
                timestampMs?.let {
                    // timestampMs already in UTC milliseconds epoch
                    Date(timestampMs)
                }

            Paylisher.capture("\$exception", properties = properties, timestamp = timestamp)
            result.success(null)
        } catch (e: Throwable) {
            result.error("CAPTURE_EXCEPTION_ERROR", "Failed to capture exception: ${e.message}", null)
        }
    }

    private fun close(result: Result) {
        try {
            Paylisher.close()
            result.success(null)
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.localizedMessage, null)
        }
    }

    private fun getSessionId(result: Result) {
        try {
            val sessionId = Paylisher.getSessionId()
            result.success(sessionId?.toString())
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.localizedMessage, null)
        }
    }

    // Call the `completion` closure if cast to map value with `key` and type `T` is successful.
    @Suppress("UNCHECKED_CAST")
    private fun <T> Map<String, Any>.getIfNotNull(
        key: String,
        callback: (T) -> Unit,
    ) {
        (get(key) as? T)?.let {
            callback(it)
        }
    }

    private fun openUrl(
        call: MethodCall,
        result: Result,
    ) {
        try {
            val raw = (call.arguments as? String)?.trim()
            if (raw.isNullOrEmpty()) {
                result.error("InvalidArguments", "URL is null or empty", null)
                return
            }

            var uri =
                try {
                    Uri.parse(raw)
                } catch (e: Throwable) {
                    result.error("InvalidArguments", "Malformed URL: $raw", null)
                    return
                }

            // If no scheme provided (e.g., "example.com"), default to https://
            if (uri.scheme.isNullOrEmpty()) {
                uri = Uri.parse("https://$raw")
            }

            val intent =
                Intent(Intent.ACTION_VIEW, uri).apply {
                    addCategory(Intent.CATEGORY_BROWSABLE)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }

            try {
                applicationContext.startActivity(intent)
                result.success(null)
            } catch (e: ActivityNotFoundException) {
                result.error("ActivityNotFound", "No application can handle ACTION_VIEW for the given URL", null)
            }
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.localizedMessage, null)
        }
    }

    private fun invokeFlutterMethod(
        method: String,
        arguments: Any? = null,
    ) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            channel.invokeMethod(method, arguments)
        } else {
            Handler(Looper.getMainLooper()).post {
                channel.invokeMethod(method, arguments)
            }
        }
    }

    // MARK: - Survey Action Handling

    private fun handleSurveyAction(
        call: MethodCall,
        result: Result,
    ) {
        val args = call.arguments as? Map<String, Any>
        val type = args?.get("type") as? String

        // Check for invalid arguments
        if (args == null || type == null) {
            result.error("InvalidArguments", "Invalid survey action arguments", null)
            return
        }

        if (flutterSurveysDelegate == null) {
            result.error("InvalidArguments", "Survey delegate not available", null)
            return
        }

        flutterSurveysDelegate?.handleSurveyAction(type, args, result)
    }
}
