import Paylisher
#if os(iOS)
    import Flutter
    import UIKit
#elseif os(macOS)
    import AppKit
    import FlutterMacOS
#endif

public class PaylisherFlutterPlugin: NSObject, FlutterPlugin {
    private static var instance: PaylisherFlutterPlugin?

    public static func getInstance() -> PaylisherFlutterPlugin? {
        instance
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        #if os(iOS)
            let channel = FlutterMethodChannel(name: "paylisher_flutter", binaryMessenger: registrar.messenger())
            let eventChannel = FlutterEventChannel(name: "paylisher_flutter_events", binaryMessenger: registrar.messenger())
            eventChannel.setStreamHandler(PaylisherFlutterNotificationManager.shared)
        #elseif os(macOS)
            let channel = FlutterMethodChannel(name: "paylisher_flutter", binaryMessenger: registrar.messenger)
        #endif
        let instance = PaylisherFlutterPlugin()
        instance.channel = channel
        PaylisherFlutterPlugin.instance = instance
        initPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }

    private let dispatchQueue = DispatchQueue(label: "com.paylisher.PaylisherFlutterPlugin",
                                              target: .global(qos: .utility))

    private var channel: FlutterMethodChannel?

    public static func initPlugin() {
        let autoInit = Bundle.main.object(forInfoDictionaryKey: "com.paylisher.paylisher.AUTO_INIT") as? Bool ?? true
        if !autoInit {
            print("[Paylisher] com.paylisher.paylisher.AUTO_INIT is disabled!")
            return
        }

        let apiKey = Bundle.main.object(forInfoDictionaryKey: "com.paylisher.paylisher.API_KEY") as? String ?? ""

        let host = Bundle.main.object(forInfoDictionaryKey: "com.paylisher.paylisher.PAYLISHER_HOST") as? String ?? PaylisherConfig.defaultHost
        let captureApplicationLifecycleEvents = Bundle.main.object(forInfoDictionaryKey: "com.paylisher.paylisher.CAPTURE_APPLICATION_LIFECYCLE_EVENTS") as? Bool ?? false
        let debug = Bundle.main.object(forInfoDictionaryKey: "com.paylisher.paylisher.DEBUG") as? Bool ?? false

        setupPaylisher([
            "apiKey": apiKey,
            "host": host,
            "captureApplicationLifecycleEvents": captureApplicationLifecycleEvents,
            "debug": debug,
        ])
    }

    private static func setupPaylisher(_ paylisherConfig: [String: Any]) {
        guard let instance = PaylisherFlutterPlugin.instance else {
            print("[Paylisher] Plugin instance not found!")
            return
        }
        let apiKey = paylisherConfig["apiKey"] as? String ?? ""
        if apiKey.isEmpty {
            print("[Paylisher] apiKey is missing!")
            return
        }

        let host = paylisherConfig["host"] as? String ?? PaylisherConfig.defaultHost

        let config = PaylisherConfig(
            apiKey: apiKey,
            host: host
        )
        config.captureScreenViews = false

        if let captureApplicationLifecycleEvents = paylisherConfig["captureApplicationLifecycleEvents"] as? Bool {
            config.captureApplicationLifecycleEvents = captureApplicationLifecycleEvents
        }
        if let debug = paylisherConfig["debug"] as? Bool {
            config.debug = debug
        }
        if let flushAt = paylisherConfig["flushAt"] as? Int {
            config.flushAt = flushAt
        }
        if let maxQueueSize = paylisherConfig["maxQueueSize"] as? Int {
            config.maxQueueSize = maxQueueSize
        }
        if let maxBatchSize = paylisherConfig["maxBatchSize"] as? Int {
            config.maxBatchSize = maxBatchSize
        }
        if let flushInterval = paylisherConfig["flushInterval"] as? Int {
            config.flushIntervalSeconds = Double(flushInterval)
        }
        if let sendFeatureFlagEvents = paylisherConfig["sendFeatureFlagEvents"] as? Bool {
            config.sendFeatureFlagEvent = sendFeatureFlagEvents
        }
        if let preloadFeatureFlags = paylisherConfig["preloadFeatureFlags"] as? Bool {
            config.preloadFeatureFlags = preloadFeatureFlags
        }
        if let optOut = paylisherConfig["optOut"] as? Bool {
            config.optOut = optOut
        }

        if let personProfiles = paylisherConfig["personProfiles"] as? String {
            switch personProfiles {
            case "never":
                config.personProfiles = .never
            case "always":
                config.personProfiles = .always
            case "identifiedOnly":
                config.personProfiles = .identifiedOnly
            default:
                break
            }
        }
        if let dataMode = paylisherConfig["dataMode"] as? String {
            switch dataMode {
            case "wifi":
                config.dataMode = .wifi
            case "cellular":
                config.dataMode = .cellular
            case "any":
                config.dataMode = .any
            default:
                break
            }
        }
        #if os(iOS)
            // configure session replay
            if let sessionReplay = paylisherConfig["sessionReplay"] as? Bool {
                config.sessionReplay = sessionReplay
            }
            // disabled since Dart has native libs such as http/dio and dont use the ios URLSession
            config.sessionReplayConfig.captureNetworkTelemetry = false
        #endif

        // Update SDK name and version
        paylisherSdkName = "paylisher-flutter"
        paylisherVersion = paylisherFlutterVersion

        PaylisherSDK.shared.setup(config)
        
        #if os(iOS)
        if let instance = PaylisherFlutterPlugin.instance {
            PaylisherSDK.shared.setDeepLinkHandler(instance)
        }
        #endif
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setup":
            setup(call, result: result)
        case "getFeatureFlag":
            getFeatureFlag(call, result: result)
        case "isFeatureEnabled":
            isFeatureEnabled(call, result: result)
        case "getFeatureFlagPayload":
            getFeatureFlagPayload(call, result: result)
        case "identify":
            identify(call, result: result)
        case "capture":
            capture(call, result: result)
        case "screen":
            screen(call, result: result)
        case "alias":
            alias(call, result: result)
        case "distinctId":
            distinctId(result)
        case "reset":
            reset(result)
        case "enable":
            enable(result)
        case "disable":
            disable(result)
        case "isOptOut":
            isOptOut(result)
        case "debug":
            debug(call, result: result)
        case "reloadFeatureFlags":
            reloadFeatureFlags(result)
        case "group":
            group(call, result: result)
        case "register":
            register(call, result: result)
        case "unregister":
            unregister(call, result: result)
        case "flush":
            flush(result)
        case "captureException":
            captureException(call, result: result)
        case "close":
            close(result)
        case "sendMetaEvent":
            sendMetaEvent(call, result: result)
        case "sendFullSnapshot":
            sendFullSnapshot(call, result: result)
        case "isSessionReplayActive":
            isSessionReplayActive(result: result)
        case "getSessionId":
            getSessionId(result: result)
        case "openUrl":
            openUrl(call, result: result)
        case "requestNotificationPermission":
            requestNotificationPermission(result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

extension PaylisherFlutterPlugin {
    private func sendMetaEvent(_ call: FlutterMethodCall,
                               result: @escaping FlutterResult)
    {
        #if os(iOS)
            let date = Date()
            let timestamp = dateToMillis(date)
            if let args = call.arguments as? [String: Any] {
                let width = args["width"] as? Int ?? 0
                let height = args["height"] as? Int ?? 0
                let screen = args["screen"] as? String ?? ""

                if width == 0 || height == 0 {
                    _badArgumentError(result)
                    return
                }

                dispatchQueue.async {
                    var snapshotsData: [Any] = []
                    let data: [String: Any] = ["width": width, "height": height, "href": screen]

                    let snapshotData: [String: Any] = ["type": 4, "data": data, "timestamp": timestamp]
                    snapshotsData.append(snapshotData)

                    PaylisherSDK.shared.capture("$snapshot", properties: ["$snapshot_source": "mobile", "$snapshot_data": snapshotsData])
                }

                result(nil)
            } else {
                _badArgumentError(result)
            }
        #else
            result(nil)
        #endif
    }

    private func sendFullSnapshot(_ call: FlutterMethodCall,
                                  result: @escaping FlutterResult)
    {
        #if os(iOS)
            let date = Date()
            let timestamp = dateToMillis(date)
            if let args = call.arguments as? [String: Any] {
                let id = args["id"] as? Int ?? 1
                let x = args["x"] as? Int ?? 0
                let y = args["y"] as? Int ?? 0

                guard let imageBytes = args["imageBytes"] as? FlutterStandardTypedData else {
                    _badArgumentError(result)
                    return
                }

                dispatchQueue.async {
                    guard let image = UIImage(data: imageBytes.data) else {
                        return
                    }

                    guard let base64 = imageToBase64(image) else {
                        return
                    }

                    var snapshotsData: [Any] = []
                    var wireframes: [Any] = []

                    let wireframe: [String: Any] = [
                        "id": id,
                        "x": x,
                        "y": y,
                        "width": Int(image.size.width),
                        "height": Int(image.size.height),
                        "type": "screenshot",
                        "base64": base64,
                        "style": [:],
                    ]

                    wireframes.append(wireframe)
                    let initialOffset = ["top": 0, "left": 0]
                    let data: [String: Any] = ["initialOffset": initialOffset, "wireframes": wireframes]
                    let snapshotData: [String: Any] = ["type": 2, "data": data, "timestamp": timestamp]
                    snapshotsData.append(snapshotData)

                    PaylisherSDK.shared.capture("$snapshot", properties: ["$snapshot_source": "mobile", "$snapshot_data": snapshotsData])
                }

                result(nil)
            } else {
                _badArgumentError(result)
            }
        #else
            result(nil)
        #endif
    }

    private func isSessionReplayActive(result: @escaping FlutterResult) {
        #if os(iOS)
            result(PaylisherSDK.shared.isSessionReplayActive())
        #else
            result(false)
        #endif
    }

    private func openUrl(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        if let url = call.arguments as? String,
           let urlObject = URL(string: url)
        {
            #if os(iOS)
                if UIApplication.shared.canOpenURL(urlObject) {
                    UIApplication.shared.open(urlObject)
                }
            #else
                NSWorkspace.shared.open(urlObject)
            #endif
            result(nil)
        } else {
            result(FlutterError(code: "InvalidArguments",
                                message: "Invalid URL",
                                details: "The URL provided is invalid"))
        }
    }

    private func setup(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        if let args = call.arguments as? [String: Any] {
            PaylisherFlutterPlugin.setupPaylisher(args)
            result(nil)
        } else {
            _badArgumentError(result)
        }
    }

    private func getFeatureFlag(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        if let args = call.arguments as? [String: Any],
           let featureFlagKey = args["key"] as? String
        {
            let value = PaylisherSDK.shared.getFeatureFlag(featureFlagKey)
            result(value)
        } else {
            _badArgumentError(result)
        }
    }

    private func isFeatureEnabled(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        if let args = call.arguments as? [String: Any],
           let featureFlagKey = args["key"] as? String
        {
            let value = PaylisherSDK.shared.isFeatureEnabled(featureFlagKey)
            result(value)
        } else {
            _badArgumentError(result)
        }
    }

    private func getFeatureFlagPayload(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        if let args = call.arguments as? [String: Any],
           let featureFlagKey = args["key"] as? String
        {
            let value = PaylisherSDK.shared.getFeatureFlagPayload(featureFlagKey)
            result(value)
        } else {
            _badArgumentError(result)
        }
    }

    private func identify(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        if let args = call.arguments as? [String: Any],
           let userId = args["userId"] as? String
        {
            let userProperties = args["userProperties"] as? [String: Any]
            let userPropertiesSetOnce = args["userPropertiesSetOnce"] as? [String: Any]

            PaylisherSDK.shared.identify(
                userId,
                userProperties: userProperties,
                userPropertiesSetOnce: userPropertiesSetOnce
            )
            result(nil)
        } else {
            _badArgumentError(result)
        }
    }

    private func capture(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        if let args = call.arguments as? [String: Any],
           let eventName = args["eventName"] as? String
        {
            let properties = args["properties"] as? [String: Any]
            PaylisherSDK.shared.capture(
                eventName,
                properties: properties
            )
            result(nil)
        } else {
            _badArgumentError(result)
        }
    }

    private func screen(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        if let args = call.arguments as? [String: Any],
           let screenName = args["screenName"] as? String
        {
            let properties = args["properties"] as? [String: Any]
            PaylisherSDK.shared.screen(
                screenName,
                properties: properties
            )
            result(nil)
        } else {
            _badArgumentError(result)
        }
    }

    private func alias(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        if let args = call.arguments as? [String: Any],
           let alias = args["alias"] as? String
        {
            PaylisherSDK.shared.alias(alias)
            result(nil)
        } else {
            _badArgumentError(result)
        }
    }

    private func distinctId(_ result: @escaping FlutterResult) {
        let val = PaylisherSDK.shared.getDistinctId()
        result(val)
    }

    private func reset(_ result: @escaping FlutterResult) {
        PaylisherSDK.shared.reset()
        result(nil)
    }

    private func enable(_ result: @escaping FlutterResult) {
        PaylisherSDK.shared.optIn()
        result(nil)
    }

    private func disable(_ result: @escaping FlutterResult) {
        PaylisherSDK.shared.optOut()
        result(nil)
    }

    private func isOptOut(_ result: @escaping FlutterResult) {
        let isOptedOut = PaylisherSDK.shared.isOptOut()
        result(isOptedOut)
    }

    private func debug(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        if let args = call.arguments as? [String: Any],
           let debug = args["debug"] as? Bool
        {
            PaylisherSDK.shared.debug(debug)
            result(nil)
        } else {
            _badArgumentError(result)
        }
    }

    private func reloadFeatureFlags(_ result: @escaping FlutterResult
    ) {
        PaylisherSDK.shared.reloadFeatureFlags()
        result(nil)
    }

    private func group(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        if let args = call.arguments as? [String: Any],
           let groupType = args["groupType"] as? String,
           let groupKey = args["groupKey"] as? String
        {
            let groupProperties = args["groupProperties"] as? [String: Any]
            PaylisherSDK.shared.group(type: groupType, key: groupKey, groupProperties: groupProperties)
            result(nil)
        } else {
            _badArgumentError(result)
        }
    }

    private func register(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        if let args = call.arguments as? [String: Any],
           let key = args["key"] as? String,
           let value = args["value"]
        {
            PaylisherSDK.shared.register([key: value])
            result(nil)
        } else {
            _badArgumentError(result)
        }
    }

    private func unregister(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        if let args = call.arguments as? [String: Any],
           let key = args["key"] as? String
        {
            PaylisherSDK.shared.unregister(key)
            result(nil)
        } else {
            _badArgumentError(result)
        }
    }

    private func flush(_ result: @escaping FlutterResult) {
        PaylisherSDK.shared.flush()
        result(nil)
    }

    private func captureException(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for captureException", details: nil))
            return
        }

        let properties = arguments["properties"] as? [String: Any]

        PaylisherSDK.shared.capture("$exception", properties: properties)
        result(nil)
    }

    private func close(_ result: @escaping FlutterResult) {
        PaylisherSDK.shared.close()
        result(nil)
    }

    private func getSessionId(result: @escaping FlutterResult) {
        result(PaylisherSDK.shared.getSessionId())
    }

    // Return bad Arguments error
    private func _badArgumentError(_ result: @escaping FlutterResult) {
        result(FlutterError(
            code: "PaylisherFlutterException", message: "Missing arguments!", details: nil
        ))
    }

    private func invokeFlutterMethod(_ method: String, arguments: Any? = nil) {
        DispatchQueue.main.async { [weak self] in
            self?.channel?.invokeMethod(method, arguments: arguments)
        }
    }

    private func requestNotificationPermission(_ result: @escaping FlutterResult) {
        #if os(iOS)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    result(FlutterError(code: "PERMISSION_ERROR", message: error.localizedDescription, details: nil))
                } else {
                    result(nil) // success implies request completed, granted status not returned in existing interface? 
                    // Wait, existing interface Future<void> requestNotificationPermission().
                    // So returning nil is correct for success/completion.
                }
            }
        }
        #else
        result(nil)
        #endif
    }
}

// MARK: - PaylisherDeepLinkHandler & Application Life Cycle

extension PaylisherFlutterPlugin: PaylisherDeepLinkHandler {
    
    public func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return PaylisherSDK.shared.handleDeepLink(url)
    }
    
    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]) -> Void) -> Bool {
        return PaylisherSDK.shared.handleUserActivity(userActivity)
    }
    
    public func paylisherDidReceiveDeepLink(_ deepLink: PaylisherDeepLink, requiresAuth: Bool) {
        let event: [String: Any] = [
            "event": "deepLinkReceived",
            "data": [
                "url": deepLink.url.absoluteString,
                "scheme": deepLink.scheme ?? "",
                "destination": deepLink.destination,
                "parameters": deepLink.parameters ?? [:],
                "campaignId": deepLink.campaignId ?? ""
            ]
        ]
        
        PaylisherFlutterNotificationManager.shared.sendEvent(event)
    }
    
    public func paylisherDeepLinkRequiresAuth(_ deepLink: PaylisherDeepLink, completion: @escaping (Bool) -> Void) {
        // Auto-complete for now as no Dart callback mechanism is defined for auth flow
        completion(true)
    }
    
    public func paylisherDeepLinkDidFail(_ url: URL, error: Error?) {
        print("[PaylisherFlutter] Deep link failed: \(url), error: \(String(describing: error))")
    }
}

// MARK: - Helper Functions

func dateToMillis(_ date: Date) -> Int64 {
    return Int64(date.timeIntervalSince1970 * 1000)
}

func imageToBase64(_ image: UIImage) -> String? {
    return image.jpegData(compressionQuality: 0.8)?.base64EncodedString()
}