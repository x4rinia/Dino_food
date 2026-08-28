import 'package:flutter/material.dart';

/// A regular Material route without an interactive horizontal back gesture.
///
/// Back buttons and the platform back action keep working. Only the iOS-style
/// drag from the screen edge is disabled so it cannot compete with the app's
/// bottom-navigation model.
class NoSwipeMaterialPageRoute<T> extends MaterialPageRoute<T> {
  NoSwipeMaterialPageRoute({
    required super.builder,
    super.settings,
    super.requestFocus,
    super.maintainState,
    super.fullscreenDialog,
    super.allowSnapshotting,
    super.barrierDismissible,
    super.traversalEdgeBehavior,
    super.directionalTraversalEdgeBehavior,
  });

  @override
  bool get popGestureEnabled => false;
}
