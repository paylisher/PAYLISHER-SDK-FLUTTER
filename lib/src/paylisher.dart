import 'package:meta/meta.dart';

import 'package:paylisher_flutter/src/error_tracking/paylisher_error_tracking_autocapture_integration.dart';
import 'paylisher_config.dart';
import 'paylisher_deeplink.dart';
import 'paylisher_flutter_platform_interface.dart';
import 'paylisher_notification.dart';
import 'paylisher_observer.dart';

class Paylisher {
  static PaylisherFlutterPlatformInterface get _paylisher =>
      PaylisherFlutterPlatformInterface.instance;

  static final _instance = Paylisher._internal();

  PaylisherConfig? _config;

  factory Paylisher() {
    return _instance;
  }

  String? _currentScreen;

  /// Android and iOS only
  /// Only used for the manual setup
  /// Requires disabling the automatic init on Android and iOS:
  /// com.paylisher.paylisher.AUTO_INIT: false
  Future<void> setup(PaylisherConfig config) {
    _config = config; // Store the config

    _installFlutterIntegrations(config);

    return _paylisher.setup(config);
  }

  void _installFlutterIntegrations(PaylisherConfig config) {
    // Install exception autocapture if enabled
    if (config.errorTrackingConfig.captureFlutterErrors ||
        config.errorTrackingConfig.capturePlatformDispatcherErrors) {
      PaylisherErrorTrackingAutoCaptureIntegration.install(
        config: config.errorTrackingConfig,
        paylisher: _paylisher,
      );
    }
  }

  void _uninstallFlutterIntegrations() {
    // Uninstall exception autocapture integration
    PaylisherErrorTrackingAutoCaptureIntegration.uninstall();
  }

  @internal
  PaylisherConfig? get config => _config;

  /// Returns the current screen name (or route name)
  /// Only returns a value if [PaylisherObserver] is used
  @internal
  String? get currentScreen => _currentScreen;

  Future<void> identify({
    required String userId,
    Map<String, Object>? userProperties,
    Map<String, Object>? userPropertiesSetOnce,
  }) =>
      _paylisher.identify(
          userId: userId,
          userProperties: userProperties,
          userPropertiesSetOnce: userPropertiesSetOnce);

  Future<void> capture({
    required String eventName,
    Map<String, Object>? properties,
  }) {
    final propertiesCopy = properties == null ? null : {...properties};

    final currentScreen = _currentScreen;
    if (propertiesCopy != null &&
        !propertiesCopy.containsKey('\$screen_name') &&
        currentScreen != null) {
      propertiesCopy['\$screen_name'] = currentScreen;
    }
    return _paylisher.capture(
      eventName: eventName,
      properties: propertiesCopy,
    );
  }

  Future<void> screen({
    required String screenName,
    Map<String, Object>? properties,
  }) {
    _currentScreen = screenName;
    return _paylisher.screen(
      screenName: screenName,
      properties: properties,
    );
  }

  Future<void> alias({
    required String alias,
  }) =>
      _paylisher.alias(
        alias: alias,
      );

  Future<String> getDistinctId() => _paylisher.getDistinctId();

  Future<void> reset() => _paylisher.reset();

  Future<void> disable() {
    // Uninstall Flutter-specific integrations when disabling
    _uninstallFlutterIntegrations();

    return _paylisher.disable();
  }

  Future<void> enable() => _paylisher.enable();

  Future<bool> isOptOut() => _paylisher.isOptOut();

  Future<void> debug(bool enabled) => _paylisher.debug(enabled);

  Future<void> register(String key, Object value) =>
      _paylisher.register(key, value);

  Future<void> unregister(String key) => _paylisher.unregister(key);

  Future<bool> isFeatureEnabled(String key) => _paylisher.isFeatureEnabled(key);

  Future<void> reloadFeatureFlags() => _paylisher.reloadFeatureFlags();

  Future<void> group({
    required String groupType,
    required String groupKey,
    Map<String, Object>? groupProperties,
  }) =>
      _paylisher.group(
        groupType: groupType,
        groupKey: groupKey,
        groupProperties: groupProperties,
      );

  Future<Object?> getFeatureFlag(String key) =>
      _paylisher.getFeatureFlag(key: key);

  Future<Object?> getFeatureFlagPayload(String key) =>
      _paylisher.getFeatureFlagPayload(key: key);

  Future<void> flush() => _paylisher.flush();

  /// Captures exceptions with optional custom properties
  ///
  /// [error] - The error/exception to capture
  /// [stackTrace] - Optional stack trace (if not provided, current stack trace will be used)
  /// [properties] - Optional custom properties to attach to the exception event
  Future<void> captureException(
          {required Object error,
          StackTrace? stackTrace,
          Map<String, Object>? properties}) =>
      _paylisher.captureException(
          error: error, stackTrace: stackTrace, properties: properties);

  /// Closes the Paylisher SDK and cleans up resources.
  ///
  /// Note: Please note that after calling close(), surveys will not be rendered until the SDK is re-initialized and the next navigation event occurs.
  Future<void> close() {
    _config = null;
    _currentScreen = null;
    PaylisherObserver.clearCurrentContext();

    // Uninstall Flutter integrations
    _uninstallFlutterIntegrations();

    return _paylisher.close();
  }

  Future<String?> getSessionId() => _paylisher.getSessionId();

  Future<String?> getSessionId() => _paylisher.getSessionId();

  /// Notification & Deeplink
  Future<void> requestNotificationPermission() =>
      _paylisher.requestNotificationPermission();

  Stream<PaylisherNotification> get onNotificationReceived =>
      _paylisher.onNotificationReceived;

  Stream<PaylisherDeeplink> get onDeepLinkReceived =>
      _paylisher.onDeepLinkReceived;

  Paylisher._internal();
}
