import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../session/data/discovery/local_discovery_service.dart';
import '../../../session/presentation/pages/receiver_pairing_screen.dart';
import '../../../session/presentation/pages/sender_pairing_screen.dart';
import '../bloc/discovery_cubit.dart';
import '../bloc/discovery_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DiscoveryCubit>(
      create: (_) => DiscoveryCubit(LocalDiscoveryService()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  void _syncAnimation(DiscoveryState state) {
    if (state.status == DiscoveryStatus.scanning) {
      _radarController.repeat();
    } else {
      _radarController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DiscoveryCubit, DiscoveryState>(
      listener: (_, state) => _syncAnimation(state),
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: <Widget>[
              Icon(Icons.cast_connected, color: AppTheme.primaryCyan),
              SizedBox(width: 8),
              Text(
                'CastFlow',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            IconButton(
              tooltip: 'QR pairing',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SenderPairingScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.qr_code_scanner,
                color: AppTheme.primaryCyan,
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'بث لاسلكي مباشر',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'بدون إنترنت • جودة عالية • تأخير منخفض جدًا',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
              const SizedBox(height: 36),
              Expanded(
                child: Center(
                  child: BlocBuilder<DiscoveryCubit, DiscoveryState>(
                    builder: (context, state) {
                      final bool scanning =
                          state.status == DiscoveryStatus.scanning;
                      return GestureDetector(
                        onTap: context.read<DiscoveryCubit>().toggle,
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            if (scanning)
                              AnimatedBuilder(
                                animation: _radarController,
                                builder: (_, _) {
                                  final double value = _radarController.value;
                                  return Container(
                                    width: 80 + (200 * value),
                                    height: 80 + (200 * value),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.primaryCyan.withValues(
                                        alpha: 1 - value,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            Container(
                              width: 130,
                              height: 130,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppTheme.primaryGradient,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: AppTheme.primaryCyan,
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                scanning
                                    ? Icons.wifi_tethering
                                    : Icons.play_arrow_rounded,
                                size: 60,
                                color: AppTheme.bgDark,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              BlocBuilder<DiscoveryCubit, DiscoveryState>(
                buildWhen: (previous, current) =>
                    previous.peers != current.peers ||
                    previous.status != current.status,
                builder: (context, state) {
                  final int count = state.peers.length;
                  final String label = state.status == DiscoveryStatus.failure
                      ? 'تعذر البحث عن الأجهزة'
                      : count == 0
                      ? 'لا توجد أجهزة مكتشفة بعد'
                      : 'الأجهزة المكتشفة: $count';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: state.status == DiscoveryStatus.failure
                            ? Colors.redAccent
                            : Colors.grey.shade400,
                      ),
                    ),
                  );
                },
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _ActionCard(
                      title: 'إرسال الشاشة',
                      subtitle: 'Sender Mode',
                      icon: Icons.screen_share_rounded,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SenderPairingScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ActionCard(
                      title: 'استقبال العرض',
                      subtitle: 'Receiver Mode',
                      icon: Icons.tv_rounded,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ReceiverPairingScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: AppTheme.primaryCyan, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
