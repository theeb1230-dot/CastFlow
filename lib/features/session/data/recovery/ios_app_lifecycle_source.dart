import 'dart:async';

import 'package:flutter/widgets.dart';

class IosAppLifecycleSource with WidgetsBindingObserver {
  IosAppLifecycleSource() {
    WidgetsBinding.instance.addObserver(this);
    final AppLifecycleState? current = WidgetsBinding.instance.lifecycleState;
    if (current != null) {
      _controller.add(current);
    }
  }

  final StreamController<AppLifecycleState> _controller =
      StreamController<AppLifecycleState>.broadcast();

  Stream<AppLifecycleState> get states => _controller.stream;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.isClosed) {
      _controller.add(state);
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _controller.close();
  }
}
