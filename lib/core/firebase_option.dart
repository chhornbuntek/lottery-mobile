import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCzMWix93Mf6Lj2Lp1ryERwqpIBJpKIspU',
    appId: '1:149613939533:android:162cce2b7212c19a324504',
    messagingSenderId: '149613939533',
    projectId: 'lottery-3f88c',
    storageBucket: 'lottery-3f88c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCzMWix93Mf6Lj2Lp1ryERwqpIBJpKIspU',
    appId: '1:149613939533:ios:162cce2b7212c19a324504',
    messagingSenderId: '149613939533',
    projectId: 'lottery-3f88c',
    storageBucket: 'lottery-3f88c.firebasestorage.app',
    iosBundleId: 'com.lottery.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCzMWix93Mf6Lj2Lp1ryERwqpIBJpKIspU',
    appId: '1:149613939533:ios:162cce2b7212c19a324504',
    messagingSenderId: '149613939533',
    projectId: 'lottery-3f88c',
    storageBucket: 'lottery-3f88c.firebasestorage.app',
    iosBundleId: 'com.lottery.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCzMWix93Mf6Lj2Lp1ryERwqpIBJpKIspU',
    appId: '1:149613939533:web:162cce2b7212c19a324504',
    messagingSenderId: '149613939533',
    projectId: 'lottery-3f88c',
    authDomain: 'lottery-3f88c.firebaseapp.com',
    storageBucket: 'lottery-3f88c.firebasestorage.app',
  );
}
