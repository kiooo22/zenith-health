// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyA3QquoX8F-Ln7ReRh1wHGTBHSjnO6WFJc",
    appId: "1:465014837018:android:ce62a02e04e511bbc6a6a3",
    messagingSenderId: "465014837018",
    projectId: "mental-health-app-c96cb",
    storageBucket: "mental-health-app-c96cb.firebasestorage.app",
  );
}
