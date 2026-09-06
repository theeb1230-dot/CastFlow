# Keep Flutter embedding entry points referenced from Android manifests.
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

# WebRTC contains JNI entry points and classes reached from native code.
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# Preserve native method names used through JNI.
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}
