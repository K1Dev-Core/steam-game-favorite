import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS || TargetPlatform.macOS => ios,
      _ => throw UnsupportedError('Firebase รองรับ Web, Android และ iOS'),
    };
  }

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyC3ltuQl7An4BGW_7APNcWeLHfgcfGrPLU',
    appId: '1:167945642488:web:464bd88335f143811cb60d',
    messagingSenderId: '167945642488',
    projectId: 'test1-f60aa',
    authDomain: 'test1-f60aa.firebaseapp.com',
    storageBucket: 'test1-f60aa.firebasestorage.app',
    measurementId: 'G-H0403KW9YE',
  );

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyA-FNLtadq8FhAWXyiZnSK4tTLPP7oyFes',
    appId: '1:167945642488:android:928419e19ea7df451cb60d',
    messagingSenderId: '167945642488',
    projectId: 'test1-f60aa',
    storageBucket: 'test1-f60aa.firebasestorage.app',
  );

  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyDVwgklMLa9J1-9LQ3h2deQJWPGge2h6ZE',
    appId: '1:167945642488:ios:aa019fed7207dad41cb60d',
    messagingSenderId: '167945642488',
    projectId: 'test1-f60aa',
    storageBucket: 'test1-f60aa.firebasestorage.app',
    iosBundleId: 'com.example.mydiaryApp',
  );
}
