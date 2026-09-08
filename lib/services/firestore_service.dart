import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../firebase_options.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  bool _initialized = false;
  bool get isConnected => _initialized;

  FirebaseFirestore? _firestore;

  String? lastError;
  DateTime? lastSavedSuccess;
  bool isSyncing = false;

  Function(String error)? onErrorOccurred;
  Function()? onSaveSuccess;

  static const String collectionName = "padel_sessions";
  String get projectId => DefaultFirebaseOptions.web.projectId;

  Future<void> initialize() async {
    try {
      debugPrint("🔥 [Firestore] Menginisialisasi Firebase untuk project: $projectId ...");
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _firestore = FirebaseFirestore.instance;
      _initialized = true;
      lastError = null;
      debugPrint("✅ [Firestore] Firebase Firestore SDK berhasil diinisialisasi!");
    } catch (e) {
      _initialized = false;
      lastError = e.toString();
      debugPrint("⚠️ [Firestore] Inisialisasi Firebase SDK gagal atau offline ($e). REST API fallback aktif.");
    }
  }

  String sanitizeDocId(String date, String passcode) {
    final cleanDate = date.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final cleanPass = passcode.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return "${cleanDate}_$cleanPass";
  }

  Future<bool> saveSessionData({
    required Map<String, dynamic> sessionData,
    required String date,
    required String passcode,
  }) async {
    isSyncing = true;
    final docId = sanitizeDocId(date, passcode);
    bool savedViaSdk = false;
    bool savedViaRest = false;

    // 1. Save via Cloud Firestore SDK if initialized
    if (_initialized && _firestore != null) {
      try {
        debugPrint("🔥 [Firestore SDK] Mengirim data sesi ke doc: '$docId'...");
        final payload = Map<String, dynamic>.from(sessionData);
        payload['searchDate'] = date.trim().toLowerCase();
        payload['searchPasscode'] = passcode.trim();
        payload['lastUpdated'] = FieldValue.serverTimestamp();

        await _firestore!.collection(collectionName).doc(docId).set(
          payload,
          SetOptions(merge: true),
        );
        savedViaSdk = true;
        debugPrint("✅ [Firestore SDK] Sukses menyimpan ke doc '$docId'!");
      } catch (e) {
        debugPrint("⚠️ [Firestore SDK] Gagal simpan via SDK: $e");
      }
    }

    // 2. Direct REST API write (Guaranteed reliable sync to Cloud Firestore)
    try {
      debugPrint("🌐 [Firestore REST] Mengirim data sesi ke Firestore REST API...");
      final restUrl = Uri.parse(
        "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$collectionName/$docId",
      );

      final sessionInfo = sessionData['session'] as Map<String, dynamic>? ?? {};
      final jsonPayloadString = jsonEncode(sessionData);

      final restBody = {
        'fields': {
          'name': {'stringValue': sessionInfo['name']?.toString() ?? 'Padel Session'},
          'date': {'stringValue': date},
          'passcode': {'stringValue': passcode},
          'searchDate': {'stringValue': date.trim().toLowerCase()},
          'searchPasscode': {'stringValue': passcode.trim()},
          'rawJson': {'stringValue': jsonPayloadString},
          'updatedAt': {'stringValue': DateTime.now().toIso8601String()},
        }
      };

      final response = await http.patch(
        restUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(restBody),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        savedViaRest = true;
        debugPrint("✅ [Firestore REST] Sukses menyimpan ke Cloud Firestore! Status: ${response.statusCode}");
      } else {
        debugPrint("⚠️ [Firestore REST] Respon error: ${response.statusCode} - ${response.body}");
        if (response.body.contains("PERMISSION_DENIED")) {
          lastError = "Izin Firestore ditolak (PERMISSION_DENIED). Periksa Security Rules di Firebase Console.";
          onErrorOccurred?.call(lastError!);
        }
      }
    } catch (e) {
      debugPrint("⚠️ [Firestore REST] Error HTTP: $e");
    }

    isSyncing = false;

    if (savedViaSdk || savedViaRest) {
      lastError = null;
      lastSavedSuccess = DateTime.now();
      onSaveSuccess?.call();
      return true;
    } else {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getSessionByDateAndPasscode(String date, String passcode) async {
    final docId = sanitizeDocId(date, passcode);

    // 1. Try SDK query first
    if (_initialized && _firestore != null) {
      try {
        debugPrint("🔍 [Firestore SDK] Mencari sesi di doc: '$docId'...");
        final docSnap = await _firestore!.collection(collectionName).doc(docId).get();

        if (docSnap.exists && docSnap.data() != null) {
          debugPrint("✅ [Firestore SDK] Sesi ditemukan di doc '$docId'!");
          return docSnap.data();
        }
      } catch (e) {
        debugPrint("⚠️ [Firestore SDK] Error get doc: $e");
      }
    }

    // 2. Try REST API query directly
    try {
      debugPrint("🌐 [Firestore REST] Mengambil data sesi dari REST API...");
      final restUrl = Uri.parse(
        "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$collectionName/$docId",
      );

      final response = await http.get(restUrl);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final fields = decoded['fields'] as Map<String, dynamic>?;
        if (fields != null) {
          final rawJson = fields['rawJson']?['stringValue'];
          if (rawJson != null) {
            final parsedSession = jsonDecode(rawJson as String) as Map<String, dynamic>;
            debugPrint("✅ [Firestore REST] Berhasil mengambil sesi via REST!");
            return parsedSession;
          }
        }
      }
    } catch (e) {
      debugPrint("⚠️ [Firestore REST] Error get doc: $e");
    }

    return null;
  }

  Stream<Map<String, dynamic>?> subscribeToSession(String date, String passcode) {
    if (!_initialized || _firestore == null) {
      return const Stream.empty();
    }
    final docId = sanitizeDocId(date, passcode);
    return _firestore!.collection(collectionName).doc(docId).snapshots().map((snap) {
      if (snap.exists && snap.data() != null) {
        return snap.data();
      }
      return null;
    });
  }
}
