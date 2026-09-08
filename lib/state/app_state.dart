import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';

class AppState extends ChangeNotifier {
  // Setup state
  String setupStep = "create"; // "create" | "roster" | "app"
  PadelSession session = PadelSession();
  String rosterDraft = "";
  List<Player> rosterPlayers = [];

  // Main app state
  List<Player> players = [];
  List<PadelMatch> matches = [];
  final Map<String, Map<String, int>> pairHistory = {};
  int matchCounter = 1;

  String activeTab = "home"; // "home" | "ranking" | "players"
  bool shuffleOpen = false;
  String shuffleError = "";
  final Map<String, Map<String, String>> scoreDrafts = {}; // matchId -> {a: '', b: ''}
  String? selectedPlayerId;
  String newPlayerName = "";
  String rankFilter = "points"; // "points" | "wins" | "winRate"

  // Join session state
  String joinError = "";
  bool isJoining = false;
  String firestoreBanner = "";

  static const String _storageKey = "padel_saved_sessions_v1";

  AppState() {
    _initStorage();
    FirestoreService().onErrorOccurred = (msg) {
      firestoreBanner = msg;
      notifyListeners();
    };
    FirestoreService().onSaveSuccess = () {
      if (firestoreBanner.isNotEmpty) {
        firestoreBanner = "";
        notifyListeners();
      }
    };
  }

  void clearFirestoreBanner() {
    firestoreBanner = "";
    notifyListeners();
  }

  Future<void> _initStorage() async {
    // Warm up SharedPreferences
    await SharedPreferences.getInstance();
  }

  // Lookups & Getters
  int get courtsTotal => session.courtsTotal;

  Map<String, Player> get byId {
    final map = <String, Player>{};
    for (final p in players) {
      map[p.id] = p;
    }
    return map;
  }

  List<PadelMatch> get activeMatches {
    final list = matches.where((m) => m.status == "playing").toList();
    list.sort((a, b) => a.court.compareTo(b.court));
    return list;
  }

  List<PadelMatch> get finishedMatches {
    final list = matches.where((m) => m.status == "finished").toList();
    list.sort((a, b) => b.matchNumber.compareTo(a.matchNumber));
    return list;
  }

  List<Player> get eligiblePlayers {
    return players.where((p) => p.checkedIn && p.status == "ready").toList();
  }

  List<Player> get waitingPlayers {
    final list = List<Player>.from(eligiblePlayers);
    list.sort((a, b) => a.played.compareTo(b.played));
    return list;
  }

  List<Player> get notCheckedInPlayers {
    return players.where((p) => !p.checkedIn).toList();
  }

  List<int> get occupiedCourts => activeMatches.map((m) => m.court).toList();

  int get freeCourts => session.courtsTotal - occupiedCourts.length;

  int get checkedInCount => players.where((p) => p.checkedIn).length;

  List<Player> get ranked {
    final list = List<Player>.from(players);
    list.sort((a, b) {
      if (rankFilter == "wins") {
        final cmp = b.wins.compareTo(a.wins);
        if (cmp != 0) return cmp;
      } else if (rankFilter == "winRate") {
        final cmp = b.winRate.compareTo(a.winRate);
        if (cmp != 0) return cmp;
      } else {
        // points
        final cmp = b.points.compareTo(a.points);
        if (cmp != 0) return cmp;
      }
      return b.played.compareTo(a.played);
    });
    return list;
  }

  Player? get selectedPlayer => selectedPlayerId != null ? byId[selectedPlayerId] : null;

  int? get selectedRank {
    if (selectedPlayerId == null) return null;
    final r = ranked;
    final idx = r.indexWhere((p) => p.id == selectedPlayerId);
    return idx != -1 ? idx + 1 : null;
  }

  // Pair history helpers
  String _pairKey(String a, String b) {
    final sorted = [a, b]..sort();
    return sorted.join("|");
  }

  int getCount(String id1, String id2, String type) {
    final key = _pairKey(id1, id2);
    return pairHistory[key]?[type] ?? 0;
  }

  // Shuffle algorithm
  void tryShuffle(int numMatches) {
    final needed = numMatches * 4;
    if (eligiblePlayers.length < needed) {
      shuffleError = "Not enough players for $numMatches match${numMatches > 1 ? 'es' : ''}. Need $needed, available: ${eligiblePlayers.length}.";
      notifyListeners();
      return;
    }

    if (freeCourts < numMatches) {
      shuffleError = "Not enough courts available. Only $freeCourts empty court${freeCourts == 1 ? '' : 's'}.";
      notifyListeners();
      return;
    }

    shuffleError = "";

    // Priority: fewest matches played first, random tiebreak
    final random = Random();
    final pool = List<Player>.from(eligiblePlayers);
    pool.sort((a, b) {
      final playedDiff = a.played.compareTo(b.played);
      if (playedDiff != 0) return playedDiff;
      return random.nextBool() ? 1 : -1;
    });

    final selectedPool = pool.take(needed).toList();

    // 250 evaluation loops for low-penalty grouping
    List<_MatchSplit>? bestAssignment;
    int bestScore = 999999;

    for (int attempt = 0; attempt < 250; attempt++) {
      final shuffled = List<Player>.from(selectedPool)..shuffle(random);
      final groups = <List<Player>>[];
      for (int i = 0; i < shuffled.length; i += 4) {
        groups.add(shuffled.sublist(i, i + 4));
      }

      int score = 0;
      final assignment = <_MatchSplit>[];

      for (final g in groups) {
        final p1 = g[0];
        final p2 = g[1];
        final p3 = g[2];
        final p4 = g[3];

        final splits = [
          _MatchSplit(teamA: [p1, p2], teamB: [p3, p4]),
          _MatchSplit(teamA: [p1, p3], teamB: [p2, p4]),
          _MatchSplit(teamA: [p1, p4], teamB: [p2, p3]),
        ];

        _MatchSplit? bestSplit;
        int bestSplitScore = 999999;

        for (final s in splits) {
          final partnerPenalty = (getCount(s.teamA[0].id, s.teamA[1].id, "partner") * 3) +
              (getCount(s.teamB[0].id, s.teamB[1].id, "partner") * 3);

          int oppPenalty = 0;
          for (final a in s.teamA) {
            for (final b in s.teamB) {
              oppPenalty += getCount(a.id, b.id, "opponent");
            }
          }

          final total = partnerPenalty + oppPenalty;
          if (total < bestSplitScore) {
            bestSplitScore = total;
            bestSplit = s;
          }
        }

        score += bestSplitScore;
        if (bestSplit != null) assignment.add(bestSplit);
      }

      if (score < bestScore) {
        bestScore = score;
        bestAssignment = assignment;
      }
      if (bestScore == 0) break;
    }

    if (bestAssignment == null) return;

    // Assign to free courts
    final availableCourts = <int>[];
    for (int c = 1; c <= session.courtsTotal; c++) {
      if (!occupiedCourts.contains(c)) availableCourts.add(c);
    }

    final newMatches = <PadelMatch>[];
    for (int idx = 0; idx < bestAssignment.length; idx++) {
      final g = bestAssignment[idx];
      newMatches.add(PadelMatch(
        id: "m${matchCounter + idx}",
        matchNumber: matchCounter + idx,
        court: availableCourts[idx],
        teamA: g.teamA.map((p) => p.id).toList(),
        teamB: g.teamB.map((p) => p.id).toList(),
        status: "playing",
      ));
    }

    // Update pair history
    for (final m in newMatches) {
      final a1 = m.teamA[0];
      final a2 = m.teamA[1];
      final b1 = m.teamB[0];
      final b2 = m.teamB[1];

      void bump(String k1, String k2, String type) {
        final key = _pairKey(k1, k2);
        pairHistory.putIfAbsent(key, () => {});
        pairHistory[key]![type] = (pairHistory[key]![type] ?? 0) + 1;
      }

      bump(a1, a2, "partner");
      bump(b1, b2, "partner");
      bump(a1, b1, "opponent");
      bump(a1, b2, "opponent");
      bump(a2, b1, "opponent");
      bump(a2, b2, "opponent");
    }

    // Mark players as playing
    final playingIds = newMatches.expand((m) => [...m.teamA, ...m.teamB]).toSet();
    players = players.map((p) {
      if (playingIds.contains(p.id)) {
        return p.copyWith(status: "playing");
      }
      return p;
    }).toList();

    matches.addAll(newMatches);
    matchCounter += newMatches.length;
    shuffleOpen = false;
    saveCurrentSessionToStorage();
    notifyListeners();
  }

  // Score submission
  void setDraftScore(String matchId, String team, String score) {
    scoreDrafts.putIfAbsent(matchId, () => {'a': '', 'b': ''});
    scoreDrafts[matchId]![team] = score.replaceAll(RegExp(r'[^0-9]'), '');
    notifyListeners();
  }

  void submitScore(String matchId) {
    final draft = scoreDrafts[matchId];
    if (draft == null || draft['a'] == null || draft['b'] == null) return;
    if (draft['a']!.isEmpty || draft['b']!.isEmpty) return;

    final a = int.tryParse(draft['a']!);
    final b = int.tryParse(draft['b']!);
    if (a == null || b == null) return;

    final matchIndex = matches.indexWhere((m) => m.id == matchId);
    if (matchIndex == -1) return;

    final match = matches[matchIndex];
    final aWins = a > b;

    matches[matchIndex] = match.copyWith(
      scoreA: a,
      scoreB: b,
      status: "finished",
    );

    final playerMap = byId;
    players = players.map((p) {
      if (match.teamA.contains(p.id)) {
        final partnerId = match.teamA.firstWhere((id) => id != p.id, orElse: () => '');
        final partner = playerMap[partnerId];
        final opponents = match.teamB.map((id) => playerMap[id]?.name ?? '').toList();

        final updatedHistory = List<MatchHistoryItem>.from(p.history)
          ..add(MatchHistoryItem(
            matchNumber: match.matchNumber,
            court: match.court,
            partner: partner?.name ?? '',
            opponents: opponents,
            score: "$a–$b",
            result: aWins ? "W" : "L",
          ));

        return p.copyWith(
          status: "ready",
          played: p.played + 1,
          wins: p.wins + (aWins ? 1 : 0),
          losses: p.losses + (aWins ? 0 : 1),
          scoreFor: p.scoreFor + a,
          scoreAgainst: p.scoreAgainst + b,
          history: updatedHistory,
        );
      }

      if (match.teamB.contains(p.id)) {
        final partnerId = match.teamB.firstWhere((id) => id != p.id, orElse: () => '');
        final partner = playerMap[partnerId];
        final opponents = match.teamA.map((id) => playerMap[id]?.name ?? '').toList();

        final updatedHistory = List<MatchHistoryItem>.from(p.history)
          ..add(MatchHistoryItem(
            matchNumber: match.matchNumber,
            court: match.court,
            partner: partner?.name ?? '',
            opponents: opponents,
            score: "$b–$a",
            result: aWins ? "L" : "W",
          ));

        return p.copyWith(
          status: "ready",
          played: p.played + 1,
          wins: p.wins + (aWins ? 0 : 1),
          losses: p.losses + (aWins ? 1 : 0),
          scoreFor: p.scoreFor + b,
          scoreAgainst: p.scoreAgainst + a,
          history: updatedHistory,
        );
      }

      return p;
    }).toList();

    scoreDrafts.remove(matchId);
    saveCurrentSessionToStorage();
    notifyListeners();
  }

  // Player management
  void toggleCheckIn(String id) {
    players = players.map((p) {
      if (p.id == id && p.status != "playing") {
        return p.copyWith(checkedIn: !p.checkedIn);
      }
      return p;
    }).toList();
    saveCurrentSessionToStorage();
    notifyListeners();
  }

  void addPlayer(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    players.add(Player(
      id: "p${DateTime.now().millisecondsSinceEpoch}",
      name: trimmed,
      played: 0,
      wins: 0,
      losses: 0,
      scoreFor: 0,
      scoreAgainst: 0,
      status: "ready",
      checkedIn: true,
      history: [],
    ));
    newPlayerName = "";
    saveCurrentSessionToStorage();
    notifyListeners();
  }

  // Tournament setup flow
  void startTournament() {
    session.name = session.name.trim().isEmpty ? "Padel Session" : session.name.trim();
    setupStep = "roster";
    saveCurrentSessionToStorage();
    notifyListeners();
  }

  void addRosterPlayer(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    rosterPlayers.add(Player.create(trimmed));
    rosterDraft = "";
    saveCurrentSessionToStorage();
    notifyListeners();
  }

  void removeRosterPlayer(String id) {
    rosterPlayers.removeWhere((p) => p.id == id);
    saveCurrentSessionToStorage();
    notifyListeners();
  }

  void beginSession() {
    players = List.from(rosterPlayers);
    setupStep = "app";
    saveCurrentSessionToStorage();
    notifyListeners();
  }

  void backToCreate() {
    setupStep = "create";
    notifyListeners();
  }

  void exitSession() {
    saveCurrentSessionToStorage();
    setupStep = "create";
    session = PadelSession();
    rosterPlayers = [];
    players = [];
    matches = [];
    matchCounter = 1;
    pairHistory.clear();
    scoreDrafts.clear();
    selectedPlayerId = null;
    activeTab = "home";
    notifyListeners();
  }

  void setActiveTab(String tab) {
    activeTab = tab;
    notifyListeners();
  }

  void setShuffleOpen(bool open) {
    shuffleOpen = open;
    if (open) shuffleError = "";
    notifyListeners();
  }

  void setSelectedPlayerId(String? id) {
    selectedPlayerId = id;
    notifyListeners();
  }

  void setRankFilter(String filter) {
    rankFilter = filter;
    notifyListeners();
  }

  // Storage and Join Session Logic
  Future<void> saveCurrentSessionToStorage() async {
    try {
      if (session.name.isEmpty && session.date.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_storageKey) ?? [];

      final effectivePlayers = players.isNotEmpty ? players : rosterPlayers;
      final currentData = {
        'id': '${session.date}_${session.passcode}_${session.name}',
        'session': session.toJson(),
        'players': effectivePlayers.map((p) => p.toJson()).toList(),
        'rosterPlayers': rosterPlayers.map((p) => p.toJson()).toList(),
        'matches': matches.map((m) => m.toJson()).toList(),
        'matchCounter': matchCounter,
        'pairHistory': pairHistory.map((k, v) => MapEntry(k, v)),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final encoded = jsonEncode(currentData);

      // Remove any existing entry matching same date and passcode
      final updatedList = <String>[];
      for (final item in rawList) {
        try {
          final decoded = jsonDecode(item) as Map<String, dynamic>;
          final s = decoded['session'] as Map<String, dynamic>?;
          if (s != null) {
            final sDate = (s['date'] as String? ?? '').trim().toLowerCase();
            final sPass = (s['passcode'] as String? ?? '').trim();
            if (sDate == session.date.trim().toLowerCase() && sPass == session.passcode.trim()) {
              continue; // replace with current
            }
          }
          updatedList.add(item);
        } catch (_) {}
      }

      updatedList.insert(0, encoded);
      // Keep up to 20 recent sessions
      if (updatedList.length > 20) {
        updatedList.removeRange(20, updatedList.length);
      }

      await prefs.setStringList(_storageKey, updatedList);

      // Also sync to Cloud Firestore
      await FirestoreService().saveSessionData(
        sessionData: currentData,
        date: session.date,
        passcode: session.passcode,
      );
    } catch (e) {
      if (kDebugMode) print("Error saving session: $e");
    }
  }

  Future<List<Map<String, dynamic>>> loadSavedSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_storageKey) ?? [];
      final list = <Map<String, dynamic>>[];
      for (final item in rawList) {
        try {
          final decoded = jsonDecode(item) as Map<String, dynamic>;
          list.add(decoded);
        } catch (_) {}
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<bool> joinSessionByDateAndPasscode(String date, String passcode) async {
    isJoining = true;
    joinError = "";
    notifyListeners();

    try {
      final cleanDate = date.trim().toLowerCase();
      final cleanPasscode = passcode.trim();

      if (cleanDate.isEmpty || cleanPasscode.isEmpty) {
        joinError = "Please enter the session date and passcode.";
        isJoining = false;
        notifyListeners();
        return false;
      }

      Map<String, dynamic>? matched;

      // 1. First attempt: Query Cloud Firestore
      try {
        final remoteData = await FirestoreService().getSessionByDateAndPasscode(cleanDate, cleanPasscode);
        if (remoteData != null) {
          matched = remoteData;
        }
      } catch (e) {
        if (kDebugMode) print("Firestore lookup error: $e");
      }

      // 2. Second attempt: Check local storage
      if (matched == null) {
        final prefs = await SharedPreferences.getInstance();
        final rawList = prefs.getStringList(_storageKey) ?? [];

        for (final item in rawList) {
          try {
            final decoded = jsonDecode(item) as Map<String, dynamic>;
            final s = decoded['session'] as Map<String, dynamic>?;
            if (s != null) {
              final sDate = (s['date'] as String? ?? '').trim().toLowerCase();
              final sPass = (s['passcode'] as String? ?? '').trim();
              if (sDate == cleanDate && sPass == cleanPasscode) {
                matched = decoded;
                break;
              }
            }
          } catch (_) {}
        }
      }

      if (matched == null) {
        joinError = "Session not found for that date and passcode. Please check your inputs.";
        isJoining = false;
        notifyListeners();
        return false;
      }

      // Restore session data
      final sMap = matched['session'] as Map<String, dynamic>;
      session = PadelSession.fromJson(sMap);

      final pList = (matched['players'] as List<dynamic>?) ?? [];
      players = pList.map((e) => Player.fromJson(e as Map<String, dynamic>)).toList();

      final mList = (matched['matches'] as List<dynamic>?) ?? [];
      matches = mList.map((e) => PadelMatch.fromJson(e as Map<String, dynamic>)).toList();

      matchCounter = matched['matchCounter'] as int? ?? (matches.length + 1);

      pairHistory.clear();
      final phMap = matched['pairHistory'] as Map<String, dynamic>?;
      if (phMap != null) {
        phMap.forEach((k, v) {
          if (v is Map) {
            pairHistory[k] = v.map((vk, vv) => MapEntry(vk.toString(), (vv as num).toInt()));
          }
        });
      }

      setupStep = "app";
      activeTab = "home";
      isJoining = false;
      joinError = "";
      notifyListeners();
      return true;
    } catch (e) {
      joinError = "Failed to load session: $e";
      isJoining = false;
      notifyListeners();
      return false;
    }
  }
}

class _MatchSplit {
  final List<Player> teamA;
  final List<Player> teamB;
  _MatchSplit({required this.teamA, required this.teamB});
}
