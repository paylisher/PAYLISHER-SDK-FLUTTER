// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'src/paylisher_flutter_platform_interface.dart';
import 'src/paylisher_flutter_web_handler.dart';

/// A web implementation of the PaylisherFlutterPlatform of the PaylisherFlutter plugin.
class PaylisherFlutterWeb extends PaylisherFlutterPlatformInterface {
  /// Constructs a PaylisherFlutterWeb
  PaylisherFlutterWeb();

  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
      'paylisher_flutter',
      const StandardMethodCodec(),
      registrar,
    );
    final PaylisherFlutterWeb instance = PaylisherFlutterWeb();
    channel.setMethodCallHandler(instance.handleMethodCall);
  }

  Future<dynamic> handleMethodCall(MethodCall call) =>
      handleWebMethodCall(call);
}
