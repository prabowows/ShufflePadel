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
    final cleanDate = date.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final cleanPass = passcode.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return "${cleanDate}_$cleanPass";
  }

  // Legacy case-preserved sanitizer for backward compatibility with old sessions
  String legacyDocId(String date, String passcode) {
    final cleanDate = date.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final cleanPass = passcode.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return "${cleanDate}_$cleanPass";
  }

  Map<String, dynamic> buildNativePayload({
    required Map<String, dynamic> sessionData,
    required String date,
    required String passcode,
  }) {
    final sessionInfo = sessionData['session'] as Map<String, dynamic>? ?? {};
    final payload = Map<String, dynamic>.from(sessionData);
    payload['name'] = sessionInfo['name']?.toString() ?? 'Padel Session';
    payload['date'] = date;
    payload['passcode'] = passcode;
    payload['searchDate'] = date.trim().toLowerCase();
    payload['searchPasscode'] = passcode.trim().toLowerCase();
    payload['updatedAt'] = DateTime.now().toIso8601String();
    return payload;
  }

  Future<bool> saveSessionData({
    required Map<String, dynamic> sessionData,
    required String date,
    required String passcode,
  }) async {
    isSyncing = true;
    final docId = sanitizeDocId(date, passcode);
    final cleanCode = passcode.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final nativePayload = buildNativePayload(
      sessionData: sessionData,
      date: date,
      passcode: passcode,
    );
    bool savedViaSdk = false;
    bool savedViaRest = false;

    // 1. Save via Cloud Firestore SDK if initialized (Native Firestore document)
    if (_initialized && _firestore != null) {
      try {
        debugPrint("🔥 [Firestore SDK] Menyimpan dokumen sesi native ke: '$docId'...");
        final sdkPayload = Map<String, dynamic>.from(nativePayload);
        sdkPayload['lastUpdated'] = FieldValue.serverTimestamp();

        // Save by date_passcode
        await _firestore!.collection(collectionName).doc(docId).set(
          sdkPayload,
          SetOptions(merge: true),
        );

        // Also save directly by cleanCode for direct room-code lookup
        if (cleanCode.isNotEmpty && cleanCode != docId) {
          await _firestore!.collection(collectionName).doc(cleanCode).set(
            sdkPayload,
            SetOptions(merge: true),
          );
        }

        savedViaSdk = true;
        debugPrint("✅ [Firestore SDK] Sukses menyimpan ke doc '$docId'!");
      } catch (e) {
        debugPrint("⚠️ [Firestore SDK] Gagal simpan via SDK: $e");
      }
    }

    // 2. Direct REST API write (Native Firestore format fallback for web/offline)
    try {
      debugPrint("🌐 [Firestore REST] Menyimpan dokumen sesi native via REST API ke '$docId'...");
      final restUrl = Uri.parse(
        "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$collectionName/$docId",
      );

      final restFields = _toFirestoreFields(nativePayload);
      final restBody = {'fields': restFields};

      final response = await http.patch(
        restUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(restBody),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        savedViaRest = true;
        debugPrint("✅ [Firestore REST] Sukses menyimpan native document! Status: ${response.statusCode}");
      } else {
        debugPrint("⚠️ [Firestore REST] Respon error: ${response.statusCode} - ${response.body}");
        if (response.body.contains("PERMISSION_DENIED")) {
          lastError = "Izin Firestore ditolak (PERMISSION_DENIED). Periksa Security Rules di Firebase Console.";
          onErrorOccurred?.call(lastError!);
        } else {
          lastError = "Gagal menyimpan ke Firestore (Status ${response.statusCode})";
        }
      }

      // Also save by cleanCode via REST
      if (cleanCode.isNotEmpty && cleanCode != docId) {
        final codeUrl = Uri.parse(
          "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$collectionName/$cleanCode",
        );
        await http.patch(
          codeUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(restBody),
        );
      }
    } catch (e) {
      debugPrint("⚠️ [Firestore REST] Error HTTP: $e");
      lastError = e.toString();
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
    return getSessionByCode(passcode, date: date);
  }

  Future<Map<String, dynamic>?> getSessionByCode(String code, {String? date}) async {
    final cleanCode = code.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    if (cleanCode.isEmpty) return null;

    debugPrint("🔍 [Firestore] Mencari sesi dengan kode: '$code' (clean: '$cleanCode')...");

    // 1. Direct doc lookup by cleanCode
    final directDoc = await _getDocById(cleanCode);
    if (directDoc != null) {
      debugPrint("✅ [Firestore] Sesi ditemukan via direct doc code '$cleanCode'!");
      return directDoc;
    }

    // 2. If date is provided, try date_code combinations
    if (date != null && date.trim().isNotEmpty) {
      final docId = sanitizeDocId(date, code);
      final legacyId = legacyDocId(date, code);
      final dateDoc = await _getDocById(docId);
      if (dateDoc != null) {
        debugPrint("✅ [Firestore] Sesi ditemukan via docId '$docId'!");
        return dateDoc;
      }
      if (docId != legacyId) {
        final legacyDoc = await _getDocById(legacyId);
        if (legacyDoc != null) {
          debugPrint("✅ [Firestore] Sesi ditemukan via legacyId '$legacyId'!");
          return legacyDoc;
        }
      }
    }

    // 3. Fallback: Query collection by searchPasscode
    final queryDoc = await _queryByPasscode(cleanCode);
    if (queryDoc != null) {
      debugPrint("✅ [Firestore] Sesi ditemukan via query searchPasscode '$cleanCode'!");
      return queryDoc;
    }

    return null;
  }

  Future<Map<String, dynamic>?> _getDocById(String id) async {
    // 1. Try SDK
    if (_initialized && _firestore != null) {
      try {
        final snap = await _firestore!.collection(collectionName).doc(id).get();
        if (snap.exists && snap.data() != null) {
          return _normalizeSessionData(snap.data()!);
        }
      } catch (e) {
        debugPrint("⚠️ [Firestore SDK] Error get doc $id: $e");
      }
    }

    // 2. Try REST
    try {
      final restUrl = Uri.parse(
        "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$collectionName/$id",
      );
      final response = await http.get(restUrl);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final fields = decoded['fields'] as Map<String, dynamic>?;
        if (fields != null) {
          return _normalizeSessionData(_fromFirestoreFields(fields));
        }
      }
    } catch (e) {
      debugPrint("⚠️ [Firestore REST] Error get doc $id: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> _queryByPasscode(String cleanPasscode) async {
    // 1. Try SDK query
    if (_initialized && _firestore != null) {
      try {
        final querySnap = await _firestore!
            .collection(collectionName)
            .where('searchPasscode', isEqualTo: cleanPasscode)
            .limit(1)
            .get();
        if (querySnap.docs.isNotEmpty) {
          return _normalizeSessionData(querySnap.docs.first.data());
        }
      } catch (e) {
        debugPrint("⚠️ [Firestore SDK] Error query by passcode: $e");
      }
    }

    // 2. Try REST structuredQuery
    try {
      final queryUrl = Uri.parse(
        "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents:runQuery",
      );
      final queryBody = {
        'structuredQuery': {
          'from': [
            {'collectionId': collectionName}
          ],
          'where': {
            'fieldFilter': {
              'field': {'fieldPath': 'searchPasscode'},
              'op': 'EQUAL',
              'value': {'stringValue': cleanPasscode}
            }
          },
          'limit': 1
        }
      };

      final response = await http.post(
        queryUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(queryBody),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List<dynamic>;
        for (final item in decoded) {
          final doc = (item as Map<String, dynamic>)['document'] as Map<String, dynamic>?;
          if (doc != null) {
            final fields = doc['fields'] as Map<String, dynamic>?;
            if (fields != null) {
              return _normalizeSessionData(_fromFirestoreFields(fields));
            }
          }
        }
      }
    } catch (e) {
      debugPrint("⚠️ [Firestore REST] Error runQuery: $e");
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
        return _normalizeSessionData(snap.data()!);
      }
      return null;
    });
  }

  /// Normalizes session map. Handles both native Firestore structures and legacy rawJson format.
  Map<String, dynamic> _normalizeSessionData(Map<String, dynamic> data) {
    if (data.containsKey('rawJson') && data['rawJson'] is String) {
      try {
        final parsed = jsonDecode(data['rawJson'] as String) as Map<String, dynamic>;
        return parsed;
      } catch (_) {}
    }
    return data;
  }

  static Map<String, dynamic> _toFirestoreFields(Map<String, dynamic> map) {
    final fields = <String, dynamic>{};
    map.forEach((key, value) {
      final converted = _toFirestoreValue(value);
      if (converted != null) {
        fields[key] = converted;
      }
    });
    return fields;
  }

  static dynamic _toFirestoreValue(dynamic val) {
    if (val == null) return {'nullValue': null};
    if (val is bool) return {'booleanValue': val};
    if (val is int) return {'integerValue': val.toString()};
    if (val is double) return {'doubleValue': val};
    if (val is String) return {'stringValue': val};
    if (val is List) {
      return {
        'arrayValue': {
          'values': val.map((item) => _toFirestoreValue(item) ?? {'nullValue': null}).toList()
        }
      };
    }
    if (val is Map) {
      final fMap = <String, dynamic>{};
      val.forEach((k, v) {
        final conv = _toFirestoreValue(v);
        if (conv != null) fMap[k.toString()] = conv;
      });
      return {'mapValue': {'fields': fMap}};
    }
    return {'stringValue': val.toString()};
  }

  static Map<String, dynamic> _fromFirestoreFields(Map<String, dynamic> fields) {
    final result = <String, dynamic>{};
    fields.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        result[key] = _fromFirestoreValue(value);
      }
    });
    return result;
  }

  static dynamic _fromFirestoreValue(Map<String, dynamic> fValue) {
    if (fValue.containsKey('stringValue')) return fValue['stringValue'];
    if (fValue.containsKey('integerValue')) {
      return int.tryParse(fValue['integerValue'].toString()) ?? 0;
    }
    if (fValue.containsKey('doubleValue')) return (fValue['doubleValue'] as num).toDouble();
    if (fValue.containsKey('booleanValue')) return fValue['booleanValue'] as bool;
    if (fValue.containsKey('nullValue')) return null;
    if (fValue.containsKey('arrayValue')) {
      final values = fValue['arrayValue']['values'] as List? ?? [];
      return values.map((v) => _fromFirestoreValue(v as Map<String, dynamic>)).toList();
    }
    if (fValue.containsKey('mapValue')) {
      final fields = fValue['mapValue']['fields'] as Map<String, dynamic>? ?? {};
      return _fromFirestoreFields(fields);
    }
    return null;
  }
}
