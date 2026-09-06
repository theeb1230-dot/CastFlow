import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/dashboard/presentation/pages/dashboard_screen.dart';
import 'features/session/presentation/bloc/receiver_pairing_cubit.dart';
import 'features/session/presentation/bloc/sender_pairing_cubit.dart';

class CastFlowApp extends StatelessWidget {
  const CastFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<SenderPairingCubit>(create: (_) => SenderPairingCubit()),
        BlocProvider<ReceiverPairingCubit>(
          create: (_) => ReceiverPairingCubit(),
        ),
      ],
      child: MaterialApp(
        title: 'CastFlow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const DashboardScreen(),
      ),
    );
  }
}
