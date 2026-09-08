// File generated for Firebase configuration.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Firebase Web configuration
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBZDq8qF_ng6IsgdrLfdmd4T1rk7irlDYI',
    appId: '1:806950490539:web:5002c4d174e4ac0ecb82ee',
    messagingSenderId: '806950490539',
    projectId: 'padel-shuffle',
    authDomain: 'padel-shuffle.firebaseapp.com',
    storageBucket: 'padel-shuffle.firebasestorage.app',
    measurementId: 'G-HQSHVZZ2V2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBZDq8qF_ng6IsgdrLfdmd4T1rk7irlDYI',
    appId: '1:806950490539:web:5002c4d174e4ac0ecb82ee',
    messagingSenderId: '806950490539',
    projectId: 'padel-shuffle',
    storageBucket: 'padel-shuffle.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBZDq8qF_ng6IsgdrLfdmd4T1rk7irlDYI',
    appId: '1:806950490539:web:5002c4d174e4ac0ecb82ee',
    messagingSenderId: '806950490539',
    projectId: 'padel-shuffle',
    storageBucket: 'padel-shuffle.firebasestorage.app',
    iosBundleId: 'com.example.padelShuffle',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBZDq8qF_ng6IsgdrLfdmd4T1rk7irlDYI',
    appId: '1:806950490539:web:5002c4d174e4ac0ecb82ee',
    messagingSenderId: '806950490539',
    projectId: 'padel-shuffle',
    storageBucket: 'padel-shuffle.firebasestorage.app',
    iosBundleId: 'com.example.padelShuffle',
  );
}
