import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../streaming/domain/entities/streaming_profile.dart';
import '../../../streaming/presentation/widgets/android_tv_receiver_surface.dart';
import '../bloc/receiver_pairing_cubit.dart';

class ReceiverPairingScreen extends StatefulWidget {
  const ReceiverPairingScreen({super.key});

  @override
  State<ReceiverPairingScreen> createState() => _ReceiverPairingScreenState();
}

class _ReceiverPairingScreenState extends State<ReceiverPairingScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      context.read<ReceiverPairingCubit>().start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const _ReceiverPairingView();
  }
}

class _ReceiverPairingView extends StatelessWidget {
  const _ReceiverPairingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('استقبال العرض')),
      body: BlocBuilder<ReceiverPairingCubit, ReceiverPairingState>(
        builder: (context, state) {
          if (state.status == ReceiverPairingStatus.connected) {
            return AndroidTvReceiverSurface(
              packets: context.read<ReceiverPairingCubit>().remoteVideoPackets,
              width: StreamingProfile.balanced.width,
              height: StreamingProfile.balanced.height,
              onExit: () {
                context.read<ReceiverPairingCubit>().stop();
              },
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _buildPairingBody(context, state),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPairingBody(BuildContext context, ReceiverPairingState state) {
    if (state.status == ReceiverPairingStatus.starting) {
      return const CircularProgressIndicator();
    }

    if (state.status == ReceiverPairingStatus.failure) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(
            state.errorMessage ?? 'تعذر بدء الاستقبال',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: context.read<ReceiverPairingCubit>().start,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      );
    }

    final String? qrData = state.qrData;
    if (qrData == null) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Text(
          'امسح الرمز من جهاز الإرسال',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: QrImageView(data: qrData, version: QrVersions.auto, size: 260),
        ),
        const SizedBox(height: 16),
        const Text(
          'الرمز محلي ومؤقت ولا يحتاج إلى الإنترنت',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.primaryCyan),
        ),
      ],
    );
  }
}
