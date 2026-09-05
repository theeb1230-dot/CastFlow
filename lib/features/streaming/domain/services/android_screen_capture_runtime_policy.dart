class AndroidScreenCaptureRuntimePolicy {
  const AndroidScreenCaptureRuntimePolicy();

  bool supportsLegacyGetDisplayMediaFlow(int sdkInt) {
    return sdkInt < 34;
  }
}
