-keepattributes SourceFile,LineNumberTable
-keep class me.carda.** { *; }

#Keep all public and protected class
-keep public class * {
      public protected *;
}
#Keep class members
-keepclassmembernames class * {
    java.lang.Class class$(java.lang.String);
    java.lang.Class class$(java.lang.String, boolean);
}

#Keep class members and native method
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

#Keep ENUM
-keepclassmembers,allowoptimization enum * {
    public static **[] values(); public static ** valueOf(java.lang.String);
}

#Keep Serializable classes and members
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}


##---------------Begin: proguard configuration for Gson  ----------
#Gson uses generic type information stored in a class file when working with fields. Proguard
#removes such information by default, so configure it to keep all of it.
-keepattributes Signature
-keepattributes InnerClasses

#For using GSON @Expose annotation
-keepattributes *Annotation*

#Gson specific classes
-dontwarn sun.misc.**
#-keep class com.google.gson.stream.** { *; }

#Application classes that will be serialized/deserialized over Gson
-keep class com.google.gson.examples.android.model.** { <fields>; }

#Prevent proguard from stripping interface information from TypeAdapter, TypeAdapterFactory,
#JsonSerializer, JsonDeserializer instances (so they can be used in @JsonAdapter)
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

#Prevent R8 from leaving Data object members always null
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

#Retain generic signatures of TypeToken and its subclasses with R8 version 3.0 and higher.
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken