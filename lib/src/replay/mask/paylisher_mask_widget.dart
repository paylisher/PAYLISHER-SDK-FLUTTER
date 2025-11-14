import 'package:flutter/material.dart';

class PaylisherMaskWidget extends StatefulWidget {
  final Widget child;

  const PaylisherMaskWidget({
    super.key,
    required this.child,
  });

  @override
  PaylisherMaskWidgetState createState() => PaylisherMaskWidgetState();
}

class PaylisherMaskWidgetState extends State<PaylisherMaskWidget> {
  final GlobalKey _widgetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _widgetKey,
      child: widget.child,
    );
  }
}
