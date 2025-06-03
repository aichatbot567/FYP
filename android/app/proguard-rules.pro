# TensorFlow Lite rules
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.**

# Additional rules that might be needed
-keep class com.google.protobuf.** { *; }
-keep class org.tensorflow.** { *; }
-keep class org.tensorflow.lite.support.** { *; }