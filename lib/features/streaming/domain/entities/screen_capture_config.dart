import 'package:equatable/equatable.dart';

import 'streaming_profile.dart';

class ScreenCaptureConfig extends Equatable {
  const ScreenCaptureConfig({required this.profile, this.includeAudio = false});

  final StreamingProfile profile;
  final bool includeAudio;

  Map<String, dynamic> toMediaConstraints() {
    return <String, dynamic>{
      'audio': includeAudio,
      'video': <String, dynamic>{
        'width': <String, int>{'ideal': profile.width},
        'height': <String, int>{'ideal': profile.height},
        'frameRate': <String, int>{'ideal': profile.framesPerSecond},
      },
    };
  }

  @override
  List<Object> get props => <Object>[profile, includeAudio];
}
