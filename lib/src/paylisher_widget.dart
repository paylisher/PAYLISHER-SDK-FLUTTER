import 'dart:async';

import 'package:flutter/material.dart';
import 'package:paylisher_flutter/paylisher_flutter.dart';
import 'package:paylisher_flutter/src/replay/mask/paylisher_mask_controller.dart';

import 'replay/change_detector.dart';
import 'replay/native_communicator.dart';
import 'replay/screenshot/screenshot_capturer.dart';

class PaylisherWidget extends StatefulWidget {
  final Widget child;

  const PaylisherWidget({super.key, required this.child});

  @override
  PaylisherWidgetState createState() => PaylisherWidgetState();
}

class PaylisherWidgetState extends State<PaylisherWidget> {
  ChangeDetector? _changeDetector;
  ScreenshotCapturer? _screenshotCapturer;
  NativeCommunicator? _nativeCommunicator;

  Timer? _throttleTimer;
  bool _isThrottling = false;
  Duration _throttleDuration = const Duration(milliseconds: 1000);

  @override
  void initState() {
    super.initState();

    final config = Paylisher().config;
    if (config == null || !config.sessionReplay) {
      return;
    }

    _throttleDuration = config.sessionReplayConfig.throttleDelay;

    _screenshotCapturer = ScreenshotCapturer(config);
    _nativeCommunicator = NativeCommunicator();

    _changeDetector = ChangeDetector(_onChangeDetected);
    _changeDetector?.start();
  }

  // This works as onRootViewsChangedListeners
  void _onChangeDetected() {
    if (_isThrottling) {
      // If throttling is active, ignore this call
      return;
    }

    // Start throttling
    _isThrottling = true;

    // Execute the snapshot generation
    _generateSnapshot();

    _throttleTimer?.cancel();
    // Reset throttling after the duration
    _throttleTimer = Timer(_throttleDuration, () {
      _isThrottling = false;
    });
  }

  Future<void> _generateSnapshot() async {
    // Ensure no asynchronous calls occur before this function,
    // as it relies on a consistent state.
    final imageInfo = await _screenshotCapturer?.captureScreenshot();
    if (imageInfo == null) {
      return;
    }

    if (imageInfo.shouldSendMetaEvent) {
      await _nativeCommunicator?.sendMetaEvent(
          width: imageInfo.width,
          height: imageInfo.height,
          screen: Paylisher().currentScreen);
    }

    await _nativeCommunicator?.sendFullSnapshot(imageInfo.imageBytes,
        id: imageInfo.id, x: imageInfo.x, y: imageInfo.y);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: PaylisherMaskController.instance.containerKey,
      child: Column(
        children: [
          Expanded(child: Container(child: widget.child)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _throttleTimer?.cancel();
    _throttleTimer = null;
    _changeDetector?.stop();
    _changeDetector = null;
    _screenshotCapturer = null;
    _nativeCommunicator = null;

    super.dispose();
  }
}
