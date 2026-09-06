import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/receiver_pairing_cubit.dart';

class ReceiverPairingScreen extends StatelessWidget {
  const ReceiverPairingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReceiverPairingCubit>(
      create: (_) => ReceiverPairingCubit()..start(),
      child: const _ReceiverPairingView(),
    );
  }
}

class _ReceiverPairingView extends StatelessWidget {
  const _ReceiverPairingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('استقبال العرض')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: BlocBuilder<ReceiverPairingCubit, ReceiverPairingState>(
            builder: (context, state) {
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

              if (state.status == ReceiverPairingStatus.connected) {
                return const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.check_circle,
                      size: 72,
                      color: AppTheme.successGreen,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'تم الاتصال بجهاز الإرسال',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'اتصال WebRTC المحلي جاهز. يمكنك الآن متابعة جلسة الإرسال.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.primaryCyan),
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
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 260,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'الرمز محلي ومؤقت ولا يحتاج إلى الإنترنت',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.primaryCyan),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
