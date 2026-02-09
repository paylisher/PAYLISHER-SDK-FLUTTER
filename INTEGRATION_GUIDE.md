# Paylisher Flutter SDK Integration Guide

This guide details the platform-specific configuration required to enable Notifications and Deep Linking in your Flutter application using the `paylisher_flutter` SDK.

## Android Setup

### 1. Deeplink Configuration

Add the intent filters to your `AndroidManifest.xml` within the `<activity>` tag (usually `.MainActivity`):

```xml
<activity android:name=".MainActivity" ...>
    <!-- Custom Scheme Deep Links -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="YOUR_CUSTOM_SCHEME" />
    </intent-filter>

    <!-- App Links (HTTPS) -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="https" android:host="YOUR_DOMAIN.com" />
    </intent-filter>
</activity>
```

**Note:** The SDK automatically handles the deep link intent.

### 2. Notification Permissions

The SDK provides a method to request notification permissions on Android 13+ (Tiramisu). Call `Paylisher.requestNotificationPermission()` from your Flutter code.

### 3. Setup Firebase Messaging (Optional but Recommended)

If you are using Firebase Cloud Messaging (FCM) alongside Paylisher, ensure you forward the messages or let Paylisher handle its own notifications if configured via the Paylisher Dashboard.

If you need to manually forward a notification to the Paylisher Flutter SDK (e.g., if you are implementing a custom `FirebaseMessagingService`), use the native `PaylisherFlutterNotificationManager`:

**Kotlin:**
```kotlin
import com.paylisher.flutter.PaylisherFlutterNotificationManager
// ...
// Inside onMessageReceived
PaylisherFlutterNotificationManager.getInstance(context).forwardNotification(data, type)
```

## iOS Setup

### 1. Deeplink Configuration

Add your URL scheme to `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.yourapp</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_CUSTOM_SCHEME</string>
        </array>
    </dict>
</array>
```

For Universal Links, configure Associated Domains in your Xcode project (Signing & Capabilities -> Associated Domains):
`applinks:YOUR_DOMAIN.com`

### 2. AppDelegate Setup

The plugin automatically registers itself as the Deep Link Handler. No additional code is required in `AppDelegate` to forward deep links if you are using the standard Flutter `AppDelegate`.

### 3. Notification Permissions

Call `Paylisher.requestNotificationPermission()` from your Flutter code.

### 4. Custom Notification Handling (Advanced)

If you need to manually forward notifications (e.g. from `userNotificationCenter(_:willPresent:...)`), you can use the `PaylisherFlutterNotificationManager`.

**Swift:**
```swift
import paylisher_flutter

// ...
PaylisherFlutterNotificationManager.shared.handleNotification(userInfo)
```

## Flutter Usage

```dart
import 'package:paylisher_flutter/paylisher_flutter.dart';

// ...

// Request Permission
await Paylisher.requestNotificationPermission();

// Listen for Notifications
Paylisher.onNotificationReceived.listen((notification) {
  print("Notification received: ${notification.title}");
});

// Listen for Deep Links
Paylisher.onDeepLinkReceived.listen((deeplink) {
  print("Deep link received: ${deeplink.url}");
  // Paylisher SDK automatically tracks the journey and resolves campaigns.
  // You can use the data here to navigate within your Flutter app.
});
```
