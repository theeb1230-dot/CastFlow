import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/sender_pairing_cubit.dart';

class SenderPairingScreen extends StatefulWidget {
  const SenderPairingScreen({super.key});

  @override
  State<SenderPairingScreen> createState() => _SenderPairingScreenState();
}

class _SenderPairingScreenState extends State<SenderPairingScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _handledBarcode = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SenderPairingCubit>(
      create: (_) => SenderPairingCubit(),
      child: BlocConsumer<SenderPairingCubit, SenderPairingState>(
        listener: (context, state) {
          if (state.status == SenderPairingStatus.failure) {
            _handledBarcode = false;
            _scannerController.start();
          }
          if (state.status == SenderPairingStatus.paired) {
            _scannerController.stop();
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: const Text('إرسال الشاشة')),
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: MobileScanner(
                        controller: _scannerController,
                        onDetect: (BarcodeCapture capture) {
                          if (_handledBarcode) {
                            return;
                          }

                          final String? value = capture.barcodes
                              .map((Barcode barcode) => barcode.rawValue)
                              .whereType<String>()
                              .cast<String?>()
                              .firstWhere(
                                (String? item) => item != null && item.isNotEmpty,
                                orElse: () => null,
                              );

                          if (value == null) {
                            return;
                          }

                          _handledBarcode = true;
                          _scannerController.stop();
                          context.read<SenderPairingCubit>().pair(value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (state.status == SenderPairingStatus.connecting)
                    const LinearProgressIndicator(),
                  if (state.status == SenderPairingStatus.paired)
                    ListTile(
                      leading: const Icon(
                        Icons.check_circle,
                        color: AppTheme.successGreen,
                      ),
                      title: const Text('تم الاقتران محليًا'),
                      subtitle: Text(state.peerName ?? 'CastFlow Receiver'),
                    ),
                  if (state.status == SenderPairingStatus.failure)
                    Column(
                      children: <Widget>[
                        Text(
                          state.errorMessage ?? 'تعذر الاقتران',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: () async {
                            await context.read<SenderPairingCubit>().reset();
                            _handledBarcode = false;
                            await _scannerController.start();
                          },
                          child: const Text('المحاولة مجددًا'),
                        ),
                      ],
                    ),
                  if (state.status == SenderPairingStatus.idle)
                    const Text(
                      'وجّه الكاميرا إلى رمز QR الظاهر على جهاز الاستقبال',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.primaryCyan),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
