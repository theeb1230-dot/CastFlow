import 'package:flutter_bloc/flutter_bloc.dart';

enum DiscoveryStatus { idle, scanning }

class DiscoveryCubit extends Cubit<DiscoveryStatus> {
  DiscoveryCubit() : super(DiscoveryStatus.idle);

  void toggle() => emit(
    state == DiscoveryStatus.idle
        ? DiscoveryStatus.scanning
        : DiscoveryStatus.idle,
  );
}
