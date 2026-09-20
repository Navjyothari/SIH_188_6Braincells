# ML Kit discovers these registrars from AndroidManifest metadata and invokes
# their public zero-argument constructors via reflection. The bundled consumer
# rule keeps class names but AGP 9/R8 removed the constructors in our release.
# Keep this narrow: do not disable shrinking or keep the entire OCR library.
-keep class com.google.mlkit.** implements com.google.firebase.components.ComponentRegistrar {
    public <init>();
}
