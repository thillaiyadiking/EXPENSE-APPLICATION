import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Disposes [TextEditingController]s after the current frame so dialog
/// exit animations cannot use a disposed controller.
void disposeAfterFrame(List<TextEditingController> controllers) {
  SchedulerBinding.instance.addPostFrameCallback((_) {
    for (final c in controllers) {
      c.dispose();
    }
  });
}
