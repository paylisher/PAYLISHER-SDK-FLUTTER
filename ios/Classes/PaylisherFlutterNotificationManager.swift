import Flutter
import UIKit
import Paylisher

public class PaylisherFlutterNotificationManager: NSObject, FlutterStreamHandler {
    
    static let shared = PaylisherFlutterNotificationManager()
    private var eventSink: FlutterEventSink?
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        print("[PaylisherFlutter] Notification EventChannel attached")
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        print("[PaylisherFlutter] Notification EventChannel detached")
        return nil
    }
    
    // Method to handle notification received from Paylisher SDK or AppDelegate
    public func handleNotification(_ notification: [AnyHashable: Any]) {
        // Need to parse notification payload to match Dart expected format
        // This depends on how Paylisher SDK returns notification data
        // For now, mapping generic dictionary
        
        // Example mapping - needs refinement based on Paylisher iOS SDK
        var data: [String: Any] = [:]
        
        if let aps = notification["aps"] as? [String: Any], let alert = aps["alert"] as? [String: Any] {
            data["title"] = alert["title"]
            data["message"] = alert["body"]
        } else if let aps = notification["aps"] as? [String: Any], let alert = aps["alert"] as? String {
             data["message"] = alert
        }
        
        // Add other fields from payload
        if let imageUrl = notification["imageUrl"] as? String {
            data["imageUrl"] = imageUrl
        }
        
        // ... map other fields
        
        let event: [String: Any] = [
            "event": "notificationReceived",
            "data": data // or full notification if we want to parse deeply in Dart? No, we have a model.
            // Better to parse here to match PaylisherNotification cleanly or pass raw map and let Dart try.
            // Dart expects: title, message, imageUrl, iconUrl, action, silent, type, buttons
        ]
        
        sendEvent(event)
    }
    
    public func sendEvent(_ event: [String: Any]) {
        DispatchQueue.main.async {
            self.eventSink?(event)
        }
    }
}
