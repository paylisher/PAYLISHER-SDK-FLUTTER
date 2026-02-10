import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:paylisher_flutter/paylisher_flutter.dart';

Future<void> main() async {
  // // init WidgetsFlutterBinding if not yet

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final config =
      PaylisherConfig('phc_3wZe1GW8GRdeUGQK0LqaS25PEDUNS9EBSxe7FiQFqQW');
  config.debug = true;
  config.captureApplicationLifecycleEvents = false;
  config.host = 'https://ds-tr.paylisher.com';
  config.surveys = true;
  config.sessionReplay = true;
  config.sessionReplayConfig.maskAllTexts = false;
  config.sessionReplayConfig.maskAllImages = false;
  config.sessionReplayConfig.throttleDelay = const Duration(milliseconds: 1000);
  config.flushAt = 1;

  // Configure error tracking and exception capture
  config.errorTrackingConfig.captureFlutterErrors =
      true; // Capture Flutter framework errors
  config.errorTrackingConfig.capturePlatformDispatcherErrors =
      true; // Capture Dart runtime errors
  config.errorTrackingConfig.captureIsolateErrors =
      true; // Capture isolate errors

  await Paylisher().setup(config);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PaylisherWidget(
      child: MaterialApp(
        navigatorObservers: [PaylisherObserver()],
        title: 'Flutter App',
        home: const InitialScreen(),
      ),
    );
  }
}

class InitialScreen extends StatefulWidget {
  const InitialScreen({Key? key}) : super(key: key);

  @override
  InitialScreenState createState() => InitialScreenState();
}

class InitialScreenState extends State<InitialScreen> {
  final _paylisherFlutterPlugin = Paylisher();
  dynamic _result = "";

  // New state variables
  Map<dynamic, dynamic>? _latestNotification;
  PaylisherDeeplink? _latestDeepLink;
  StreamSubscription? _notificationSubscription;
  StreamSubscription? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _setupListeners();
    _setupFirebaseMessaging();
  }

  void _setupListeners() {
    // Listen for notifications
    _notificationSubscription =
        _paylisherFlutterPlugin.onNotificationReceived.listen((notification) {
      print("Notification received in example app: ${notification.payload}");
      setState(() {
        _latestNotification = notification.payload;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Notification Received!")),
        );
      }
    });

    // Listen for deep links
    _deepLinkSubscription =
        _paylisherFlutterPlugin.onDeepLinkReceived.listen((deepLink) {
      print("Deep Link received in example app: ${deepLink.url}");
      setState(() {
        _latestDeepLink = deepLink;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Deep Link: ${deepLink.destination}")),
        );
      }
    });
  }

  Future<void> _setupFirebaseMessaging() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('User granted permission: ${settings.authorizationStatus}');

      // Get the token each time the application loads
      String? token = await messaging.getToken();
      if (token != null) {
        print("FCM Token: $token");
        // Register the token with Paylisher
        // Depending on Paylisher SDK, we might need a specific method or just identify/register
        // Here we use register as a generic way to pass the token if no specific method exists in Dart interface
        // But checking PaylisherAndroid.kt, it captures "FCM" event with "token" property.
        // We can replicate this behavior or rely on SDK auto-capture.
        // For example app, let's explicitly capture it to be sure.
        _paylisherFlutterPlugin
            .capture(eventName: "FCM", properties: {"token": token});
        // Also register it as a user property
        _paylisherFlutterPlugin.identify(
            userId: await _paylisherFlutterPlugin.getDistinctId(),
            userProperties: {"fcm_token": token});
      }

      // Any time the token refreshes, store this in the database too.
      FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
        print("FCM Token Refreshed: $fcmToken");
        _paylisherFlutterPlugin
            .capture(eventName: "FCM", properties: {"token": fcmToken});
        _paylisherFlutterPlugin.identify(userId: "myId", userProperties: {
          "fcm_token": fcmToken
        }); // Re-identify or update props if possible
        // Note: optimize userId retrieval in real app
      }).onError((err) {
        print("Error getting token refresh");
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print(
              'Message also contained a notification: ${message.notification}');
        }
      });
    } catch (e) {
      print("Error setting up Firebase Messaging: $e");
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paylisher Flutter App'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Notifications & Deep Links",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _paylisherFlutterPlugin
                        .requestNotificationPermission();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Permission requested")),
                      );
                    }
                  },
                  child: const Text("Request Notification Permission"),
                ),
                if (_latestNotification != null)
                  Card(
                    color: Colors.orange.shade100,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Latest Notification:",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(_latestNotification.toString()),
                        ],
                      ),
                    ),
                  ),
                if (_latestDeepLink != null)
                  Card(
                    color: Colors.blue.shade100,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Latest Deep Link:",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("URL: ${_latestDeepLink!.url}"),
                          Text("Destination: ${_latestDeepLink!.destination}"),
                          if (_latestDeepLink!.campaignId != null)
                            Text("Campaign: ${_latestDeepLink!.campaignId}"),
                          if (_latestDeepLink!.parameters?.isNotEmpty ?? false)
                            Text("Params: ${_latestDeepLink!.parameters}"),
                        ],
                      ),
                    ),
                  ),
                const Divider(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SecondRoute(),
                          settings: const RouteSettings(name: 'second_route')),
                    );
                  },
                  child: const PaylisherMaskWidget(
                    child: Text(
                      'Go to Second Route',
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Capture",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _paylisherFlutterPlugin
                            .screen(screenName: "my screen", properties: {
                          "foo": "bar",
                        });
                      },
                      child: const Text("Capture Screen manually"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _paylisherFlutterPlugin
                            .capture(eventName: "eventName", properties: {
                          "foo": "bar",
                        });
                      },
                      child: const Text("Capture Event"),
                    ),
                  ],
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Activity",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () {
                        _paylisherFlutterPlugin.disable();
                      },
                      child: const Text("Disable Capture"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () {
                        _paylisherFlutterPlugin.enable();
                      },
                      child: const Text("Enable Capture"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      onPressed: () async {
                        final isOptedOut =
                            await _paylisherFlutterPlugin.isOptOut();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Opted out: $isOptedOut'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: const Text("Check Opt-Out Status"),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _paylisherFlutterPlugin.register("foo", "bar");
                  },
                  child: const Text("Register"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _paylisherFlutterPlugin.unregister("foo");
                  },
                  child: const Text("Unregister"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _paylisherFlutterPlugin.group(
                        groupType: "theType",
                        groupKey: "theKey",
                        groupProperties: {
                          "foo": "bar",
                        });
                  },
                  child: const Text("Group"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _paylisherFlutterPlugin
                        .identify(userId: "myId", userProperties: {
                      "foo": "bar",
                    }, userPropertiesSetOnce: {
                      "foo1": "bar1",
                    });
                  },
                  child: const Text("Identify"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _paylisherFlutterPlugin.alias(alias: "myAlias");
                  },
                  child: const Text("Alias"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _paylisherFlutterPlugin.debug(true);
                  },
                  child: const Text("Debug"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _paylisherFlutterPlugin.reset();
                  },
                  child: const Text("Reset"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _paylisherFlutterPlugin.flush();
                  },
                  child: const Text("Flush"),
                ),
                ElevatedButton(
                    onPressed: () async {
                      final result =
                          await _paylisherFlutterPlugin.getDistinctId();
                      setState(() {
                        _result = result;
                      });
                    },
                    child: const PaylisherMaskWidget(
                      child: Text("distinctId"),
                    )),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Error Tracking - Manual",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      // Simulate an exception in main isolate
                      // throw 'a custom error string';
                      // throw 333;
                      throw CustomException(
                        'This is a custom exception with additional context',
                        code: 'DEMO_ERROR_001',
                        additionalData: {
                          'user_action': 'button_press',
                          'timestamp': DateTime.now().millisecondsSinceEpoch,
                          'feature_enabled': true,
                        },
                      );
                    } catch (e, stack) {
                      await Paylisher().captureException(
                        error: e,
                        stackTrace: stack,
                        properties: {
                          'test_type': 'main_isolate_exception',
                          'button_pressed': 'capture_exception_main',
                          'exception_category': 'custom',
                        },
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Main isolate exception captured successfully! Check Paylisher.'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text("Capture Exception"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  onPressed: () async {
                    await Paylisher().captureException(
                      error: 'No Stack Trace Error',
                      properties: {'test_type': 'no_stack_trace'},
                    );
                  },
                  child: const Text("Capture Exception (Missing Stack)"),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Error Tracking - Autocapture",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Flutter error triggered! Check Paylisher.'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }

                    // Test Flutter error handler by throwing in widget context
                    throw const CustomException(
                        'Test Flutter error for autocapture',
                        code: 'FlutterErrorTest',
                        additionalData: {'test_type': 'flutter_error'});
                  },
                  child: const Text("Test Flutter Error Handler"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    // Test PlatformDispatcher error handler with Future
                    Future.delayed(Duration.zero, () {
                      throw const CustomException(
                          'Test PlatformDispatcher error for autocapture',
                          code: 'PlatformDispatcherTest',
                          additionalData: {
                            'test_type': 'platform_dispatcher_error'
                          });
                    });

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Dart runtime error triggered! Check Paylisher.'),
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  child: const Text("Test Dart Error Handler"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    // Test isolate error listener by throwing in an async callback
                    Timer(Duration.zero, () {
                      throw const CustomException(
                        'Isolate error for testing',
                        code: 'IsolateHandlerTest',
                        additionalData: {
                          'test_type': 'isolate_error_listener_timer',
                        },
                      );
                    });

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Isolate error triggered! Check Paylisher.'),
                          backgroundColor: Colors.purple,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  child: const Text("Test Isolate Error Handler"),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Feature flags",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final result = await _paylisherFlutterPlugin
                        .getFeatureFlag("feature_name");
                    setState(() {
                      _result = result;
                    });
                  },
                  child: const Text("Get Feature Flag status"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final result = await _paylisherFlutterPlugin
                        .isFeatureEnabled("feature_name");
                    setState(() {
                      _result = result;
                    });
                  },
                  child: const Text("isFeatureEnabled"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final result = await _paylisherFlutterPlugin
                        .getFeatureFlagPayload("feature_name");
                    setState(() {
                      _result = result;
                    });
                  },
                  child: const Text("getFeatureFlagPayload"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _paylisherFlutterPlugin.reloadFeatureFlags();
                  },
                  child: const PaylisherMaskWidget(
                      child: Text("reloadFeatureFlags")),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Data result",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(_result.toString()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SecondRoute extends StatefulWidget {
  const SecondRoute({super.key});

  @override
  SecondRouteState createState() => SecondRouteState();
}

class SecondRouteState extends State<SecondRoute> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const PaylisherMaskWidget(child: Text('First Route')),
      ),
      body: Center(
        child: RepaintBoundary(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                child: const PaylisherMaskWidget(child: Text('Open route')),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ThirdRoute(),
                      settings: const RouteSettings(name: 'third_route'),
                    ),
                  ).then((_) {});
                },
              ),
              const SizedBox(height: 20),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Sensitive Text Input',
                  hintText: 'Enter sensitive data',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              PaylisherMaskWidget(
                  child: Image.asset(
                'assets/training_paylisher.png',
                height: 200,
              )),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class ThirdRoute extends StatelessWidget {
  const ThirdRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Third Route'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
          ),
          itemCount: 16,
          itemBuilder: (context, index) {
            return Image.asset(
              'assets/paylisher_logo.png',
              fit: BoxFit.cover,
            );
          },
        ),
      ),
    );
  }
}

/// Custom exception class for demonstration purposes
class CustomException implements Exception {
  final String message;
  final String? code;
  final Map<String, dynamic>? additionalData;

  const CustomException(
    this.message, {
    this.code,
    this.additionalData,
  });

  @override
  String toString() {
    if (code != null) {
      return 'CustomException($code): $message $additionalData';
    }
    return 'CustomException: $message $additionalData';
  }
}
