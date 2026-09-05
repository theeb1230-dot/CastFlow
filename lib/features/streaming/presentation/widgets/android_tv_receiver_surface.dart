import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/decoder/android_tv_h264_renderer.dart';
import '../../data/decoder/android_tv_receiver_pipeline.dart';
import '../../domain/entities/encoded_video_packet.dart';

class AndroidTvReceiverSurface extends StatefulWidget {
  const AndroidTvReceiverSurface({
    required this.packets,
    required this.width,
    required this.height,
    this.onExit,
    super.key,
  });

  final Stream<EncodedVideoPacket> packets;
  final int width;
  final int height;
  final VoidCallback? onExit;

  @override
  State<AndroidTvReceiverSurface> createState() =>
      _AndroidTvReceiverSurfaceState();
}

class _AndroidTvReceiverSurfaceState extends State<AndroidTvReceiverSurface> {
  late final AndroidTvReceiverPipeline _pipeline;
  late final FocusNode _exitFocusNode;
  int? _textureId;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _exitFocusNode = FocusNode(debugLabel: 'tv-receiver-exit');
    _pipeline = AndroidTvReceiverPipeline(renderer: AndroidTvH264Renderer());
    unawaited(_start());
  }

  Future<void> _start() async {
    try {
      final int textureId = await _pipeline.start(
        packets: widget.packets,
        width: widget.width,
        height: widget.height,
      );
      if (mounted) {
        setState(() => _textureId = textureId);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    }
  }

  @override
  void dispose() {
    _exitFocusNode.dispose();
    unawaited(_pipeline.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.escape): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.goBack): ActivateIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onExit?.call();
                return null;
              },
            ),
          },
          child: ColoredBox(
            color: AppTheme.bgDark,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (_textureId != null)
                  Texture(textureId: _textureId!)
                else
                  Center(
                    child: _error == null
                        ? const CircularProgressIndicator(
                            color: AppTheme.primaryCyan,
                          )
                        : Text(
                            'تعذر تشغيل مستقبل العرض',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                  ),
                Positioned(
                  top: 24,
                  right: 24,
                  child: FocusTraversalOrder(
                    order: const NumericFocusOrder(1),
                    child: Focus(
                      focusNode: _exitFocusNode,
                      autofocus: true,
                      child: Builder(
                        builder: (context) {
                          final bool focused = Focus.of(context).hasFocus;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: focused
                                    ? AppTheme.primaryCyan
                                    : Colors.white24,
                                width: focused ? 2 : 1,
                              ),
                              color: AppTheme.surfaceDark,
                            ),
                            child: IconButton(
                              tooltip: 'خروج',
                              onPressed: widget.onExit,
                              icon: const Icon(Icons.close),
                              color: AppTheme.primaryCyan,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
