package com.paylisher.flutter

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import com.paylisher.Paylisher
import com.paylisher.PersonProfiles
import com.paylisher.android.PaylisherAndroid
import com.paylisher.android.PaylisherAndroidConfig
import com.paylisher.android.internal.getApplicationInfo
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.Date

class PaylisherFlutterPlugin :
    FlutterPlugin,
    MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var applicationContext: Context

    private val snapshotSender = SnapshotSender()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "paylisher_flutter")
        applicationContext = binding.applicationContext
        Log.d("Paylisher", "[FlutterPlugin] onAttachedToEngine() çağırıldı")

        initPlugin()

        channel.setMethodCallHandler(this)
    }

    private fun initPlugin() {
        try {
            val ai = getApplicationInfo(applicationContext)
            val bundle = ai.metaData ?: Bundle()
            val autoInit = bundle.getBoolean("com.paylisher.paylisher.AUTO_INIT", true)

            if (!autoInit) {
                Log.i("Paylisher", "[initPlugin] AUTO_INIT disabled")
                return
            }

            val apiKey = bundle.getString("com.paylisher.paylisher.API_KEY")
            if (apiKey.isNullOrEmpty()) {
                Log.e("Paylisher", "[initPlugin] API_KEY missing")
                return
            }

            val host = bundle.getString("com.paylisher.paylisher.PAYLISHER_HOST")
                ?: "https://datastudio.paylisher.com"

            val captureLifecycle = bundle.getBoolean(
                "com.paylisher.paylisher.TRACK_APPLICATION_LIFECYCLE_EVENTS",
                false
            )
            val debug = bundle.getBoolean("com.paylisher.paylisher.DEBUG", false)

            val cfg = mutableMapOf<String, Any>()
            cfg["apiKey"] = apiKey
            cfg["host"] = host
            cfg["captureApplicationLifecycleEvents"] = captureLifecycle
            cfg["debug"] = debug

            Log.d("Paylisher", "[initPlugin] Auto setup başlatılıyor…")

            setupPaylisher(cfg)

        } catch (e: Throwable) {
            Log.e("Paylisher", "[initPlugin] Hata: $e")
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        Log.d("Paylisher", "[FlutterPlugin] Method call: ${call.method}")

        when (call.method) {
            "setup" -> setup(call, result)
            "identify" -> identify(call, result)
            "capture" -> capture(call, result)
            "screen" -> screen(call, result)
            "alias" -> alias(call, result)
            "distinctId" -> distinctId(result)
            "reset" -> reset(result)
            "disable" -> disable(result)
            "enable" -> enable(result)
            "isOptOut" -> isOptOut(result)
            "isFeatureEnabled" -> isFeatureEnabled(call, result)
            "reloadFeatureFlags" -> reloadFeatureFlags(result)
            "group" -> group(call, result)
            "getFeatureFlag" -> getFeatureFlag(call, result)
            "getFeatureFlagPayload" -> getFeatureFlagPayload(call, result)
            "register" -> register(call, result)
            "unregister" -> unregister(call, result)
            "debug" -> debug(call, result)
            "flush" -> flush(result)
            "captureException" -> captureException(call, result)
            "close" -> close(result)
            "sendMetaEvent" -> handleMetaEvent(call, result)
            "sendFullSnapshot" -> handleSendFullSnapshot(call, result)
            "isSessionReplayActive" -> result.success(Paylisher.isSessionReplayActive())
            "getSessionId" -> getSessionId(result)
            "openUrl" -> openUrl(call, result)

            "surveyAction" -> {
                Log.w("Paylisher", "[Survey] Android SDK survey desteklemiyor → yok sayılıyor")
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun setup(call: MethodCall, result: Result) {
        try {
            val args = call.arguments as? Map<String, Any> ?: emptyMap()
            if (args.isEmpty()) {
                result.error("PaylisherFlutterException", "Arguments null", null)
                return
            }

            Log.d("Paylisher", "[setup] Flutter'dan config alındı → $args")

            setupPaylisher(args)
            result.success(null)

        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.message, null)
        }
    }

    private fun setupPaylisher(cfg: Map<String, Any>) {
        val apiKey = cfg["apiKey"] as? String
        if (apiKey.isNullOrEmpty()) {
            Log.e("Paylisher", "[setupPaylisher] API Key missing!")
            return
        }

        val host = cfg["host"] as? String ?: "https://datastudio.paylisher.com"
        val config = PaylisherAndroidConfig(apiKey, host).apply {

            cfg.getIfNotNull<Boolean>("captureApplicationLifecycleEvents") {
                captureApplicationLifecycleEvents = it
            }
            cfg.getIfNotNull<Boolean>("debug") {
                debug = it
            }

            // Session Replay
            cfg.getIfNotNull<Boolean>("sessionReplay") {
                sessionReplay = it
            }
            this.sessionReplayConfig.captureLogcat = false

            // Person profiles
            cfg.getIfNotNull<String>("personProfiles") {
                personProfiles = when (it) {
                    "never" -> PersonProfiles.NEVER
                    "always" -> PersonProfiles.ALWAYS
                    "identifiedOnly" -> PersonProfiles.IDENTIFIED_ONLY
                    else -> PersonProfiles.IDENTIFIED_ONLY
                }
            }

            // Surveys — Android desteklemez
            cfg.getIfNotNull<Boolean>("surveys") { enabled ->
                Log.w("Paylisher", "[setupPaylisher] Surveys = $enabled ancak Android SDK desteklemiyor.")
            }

            sdkName = "paylisher-flutter"
            sdkVersion = cfg["sdkVersion"] as? String ?: "1.0.0"
        }

        Log.d("Paylisher", "[setupPaylisher] PaylisherAndroid.setup() çağırılıyor")
        PaylisherAndroid.setup(applicationContext, config)
    }

    private fun handleMetaEvent(call: MethodCall, result: Result) {
        try {
            val width = call.argument<Int>("width") ?: 0
            val height = call.argument<Int>("height") ?: 0
            val screen = call.argument<String>("screen") ?: ""

            snapshotSender.sendMetaEvent(width, height, screen)
            result.success(null)

        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.message, null)
        }
    }

    private fun handleSendFullSnapshot(call: MethodCall, result: Result) {
        try {
            val bytes = call.argument<ByteArray>("imageBytes")
            val id = call.argument<Int>("id") ?: 1
            val x = call.argument<Int>("x") ?: 0
            val y = call.argument<Int>("y") ?: 0

            if (bytes != null) {
                snapshotSender.sendFullSnapshot(bytes, id, x, y)
            }

            result.success(null)

        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.message, null)
        }
    }

    private fun identify(call: MethodCall, result: Result) {
        try {
            val userId = call.argument<String>("userId")!!
            val props = call.argument<Map<String, Any>>("userProperties")
            val once = call.argument<Map<String, Any>>("userPropertiesSetOnce")

            Paylisher.identify(userId, props, once)
            result.success(null)

        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.message, null)
        }
    }

    private fun capture(call: MethodCall, result: Result) {
        try {
            val event = call.argument<String>("eventName")!!
            val props = call.argument<Map<String, Any>>("properties")
            Paylisher.capture(event, properties = props)
            result.success(null)

        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.message, null)
        }
    }

    private fun screen(call: MethodCall, result: Result) {
        try {
            val name = call.argument<String>("screenName")!!
            val props = call.argument<Map<String, Any>>("properties")
            Paylisher.screen(name, props)
            result.success(null)

        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.message, null)
        }
    }

    private fun alias(call: MethodCall, result: Result) {
        try {
            val a = call.argument<String>("alias")!!
            Paylisher.alias(a)
            result.success(null)

        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.message, null)
        }
    }

    private fun distinctId(result: Result) {
        try {
            result.success(Paylisher.distinctId())
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.message, null)
        }
    }

    private fun reset(result: Result) {
        try {
            Paylisher.reset()
            result.success(null)
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.message, null)
        }
    }

    private fun enable(result: Result) {
        try {
            Paylisher.optIn()
            result.success(null)
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.message, null)
        }
    }

    private fun disable(result: Result) {
        try {
            Paylisher.optOut()
            result.success(null)
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.message, null)
        }
    }

    private fun isOptOut(result: Result) {
        try {
            result.success(Paylisher.isOptOut())
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.message, null)
        }
    }

    private fun isFeatureEnabled(call: MethodCall, result: Result) {
        try {
            val key = call.argument<String>("key")!!
            result.success(Paylisher.isFeatureEnabled(key))
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.message, null)
        }
    }

    private fun reloadFeatureFlags(result: Result) {
        try {
            Paylisher.reloadFeatureFlags()
            result.success(null)
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.message, null)
        }
    }

    private fun group(call: MethodCall, result: Result) {
        try {
            val type = call.argument<String>("groupType")!!
            val key = call.argument<String>("groupKey")!!
            val props = call.argument<Map<String, Any>>("groupProperties")

            Paylisher.group(type, key, props)
            result.success(null)

        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.message, null)
        }
    }

    private fun getFeatureFlag(call: MethodCall, result: Result) {
        try {
            val key = call.argument<String>("key")!!
            result.success(Paylisher.getFeatureFlag(key))
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.message, null)
        }
    }

    private fun getFeatureFlagPayload(call: MethodCall, result: Result) {
        try {
            val key = call.argument<String>("key")!!
            result.success(Paylisher.getFeatureFlagPayload(key))
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.message, null)
        }
    }

    private fun register(call: MethodCall, result: Result) {
        try {
            val key = call.argument<String>("key")!!
            val value = call.argument<Any>("value")!!
            Paylisher.register(key, value)
            result.success(null)

        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.message, null)
        }
    }

    private fun unregister(call: MethodCall, result: Result) {
        try {
            val key = call.argument<String>("key")!!
            Paylisher.unregister(key)
            result.success(null)

        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.message, null)
        }
    }

    private fun debug(call: MethodCall, result: Result) {
        try {
            val enabled = call.argument<Boolean>("debug") ?: false
            Paylisher.debug(enabled)
            result.success(null)
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.message, null)
        }
    }

    private fun flush(result: Result) {
        try {
            Paylisher.flush()
            result.success(null)
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.message, null)
        }
    }

    private fun captureException(call: MethodCall, result: Result) {
        try {
            val args = call.arguments as? Map<String, Any> ?: emptyMap()
            val props = args["properties"] as? Map<String, Any>

            Paylisher.capture("\$exception", properties = props)
            result.success(null)

        } catch (e: Throwable) {
            result.error("CAPTURE_EXCEPTION_ERROR", e.message, null)
        }
    }

    private fun close(result: Result) {
        try {
            Paylisher.close()
            result.success(null)
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.message, null)
        }
    }

    private fun getSessionId(result: Result) {
        try {
            val id = Paylisher.getSessionId()
            result.success(id?.toString())
        } catch (e: Throwable) {
            result.error("PaylisherFlutterException", e.message, null)
        }
    }

    private fun openUrl(call: MethodCall, result: Result) {
        try {
            val raw = call.arguments as? String ?: ""
            if (raw.isBlank()) {
                result.error("InvalidArguments", "URL is empty", null)
                return
            }

            val uri = Uri.parse(
                if (raw.startsWith("http")) raw else "https://$raw"
            )

            val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addCategory(Intent.CATEGORY_BROWSABLE)
            }

            applicationContext.startActivity(intent)
            result.success(null)

        } catch (e: ActivityNotFoundException) {
            result.error("ActivityNotFound", e.message, null)
        }
    }

    @Suppress("UNCHECKED_CAST")
    private fun <T> Map<String, Any>.getIfNotNull(
        key: String,
        block: (T) -> Unit,
    ) {
        (this[key] as? T)?.let(block)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d("Paylisher", "[FlutterPlugin] Detached")
        channel.setMethodCallHandler(null)
    }
}