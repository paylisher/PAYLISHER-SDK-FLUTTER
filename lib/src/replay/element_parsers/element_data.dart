import 'package:flutter/material.dart';
import 'package:paylisher_flutter/src/replay/mask/paylisher_mask_widget.dart';

class ElementData {
  Rect rect;
  String type;
  List<ElementData>? children;
  Widget? widget;

  ElementData({
    required this.rect,
    required this.type,
    this.children,
    this.widget,
  });

  void addChildren(ElementData elementData) {
    children ??= [];
    children?.add(elementData);
  }

  List<Rect> extractMaskWidgetRects() {
    final rects = <Rect>[];
    _collectMaskWidgetRects(this, rects);
    return rects;
  }

  List<ElementData> extractRects({bool isRoot = true}) {
    List<ElementData> rects = [];

    if (children != null) {
      for (var child in children ?? []) {
        if (child.children == null) {
          rects.add(child);
          continue;
        } else if ((child.children?.length ?? 0) > 1) {
          for (var grandChild in child.children ?? []) {
            rects.add(grandChild);
          }
        } else {
          rects.add(child);
        }
      }
    }
    return rects;
  }

  void _collectMaskWidgetRects(ElementData element, List<Rect> rectList) {
    if (!rectList.contains(element.rect)) {
      if (element.widget is PaylisherMaskWidget) {
        rectList.add(element.rect);
      } else if (element.widget is TextField) {
        final textField = element.widget as TextField;
        if (textField.obscureText) {
          rectList.add(element.rect);
        }
      }
    }

    final children = element.children;
    if (children != null && children.isNotEmpty) {
      for (var child in children) {
        _collectMaskWidgetRects(child, rectList);
      }
    }
  }
}
