abstract interface class RtcSignalingPort {
  Stream<Map<String, Object?>> get localIceCandidates;

  Future<Map<String, Object?>> createOffer();

  Future<Map<String, Object?>> acceptOffer(Map<String, Object?> payload);

  Future<void> acceptAnswer(Map<String, Object?> payload);

  Future<void> addRemoteCandidate(Map<String, Object?> payload);
}
