class MatchHistoryItem {
  final int matchNumber;
  final int court;
  final String partner;
  final List<String> opponents;
  final String score;
  final String result; // 'W' or 'L'

  MatchHistoryItem({
    required this.matchNumber,
    required this.court,
    required this.partner,
    required this.opponents,
    required this.score,
    required this.result,
  });

  Map<String, dynamic> toJson() => {
        'matchNumber': matchNumber,
        'court': court,
        'partner': partner,
        'opponents': opponents,
        'score': score,
        'result': result,
      };

  factory MatchHistoryItem.fromJson(Map<String, dynamic> json) =>
      MatchHistoryItem(
        matchNumber: json['matchNumber'] as int? ?? 0,
        court: json['court'] as int? ?? 1,
        partner: json['partner'] as String? ?? '',
        opponents: (json['opponents'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        score: json['score'] as String? ?? '',
        result: json['result'] as String? ?? 'W',
      );
}

class Player {
  final String id;
  String name;
  int played;
  int wins;
  int losses;
  int scoreFor;
  int scoreAgainst;
  String status; // 'ready' | 'playing'
  bool checkedIn;
  List<MatchHistoryItem> history;

  Player({
    required this.id,
    required this.name,
    this.played = 0,
    this.wins = 0,
    this.losses = 0,
    this.scoreFor = 0,
    this.scoreAgainst = 0,
    this.status = 'ready',
    this.checkedIn = true,
    List<MatchHistoryItem>? history,
  }) : history = history ?? [];

  int get points => (wins * 3) + (scoreFor - scoreAgainst);
  int get diff => scoreFor - scoreAgainst;
  int get winRate => played > 0 ? ((wins / played) * 100).round() : 0;

  Player copyWith({
    String? name,
    int? played,
    int? wins,
    int? losses,
    int? scoreFor,
    int? scoreAgainst,
    String? status,
    bool? checkedIn,
    List<MatchHistoryItem>? history,
  }) {
    return Player(
      id: id,
      name: name ?? this.name,
      played: played ?? this.played,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      scoreFor: scoreFor ?? this.scoreFor,
      scoreAgainst: scoreAgainst ?? this.scoreAgainst,
      status: status ?? this.status,
      checkedIn: checkedIn ?? this.checkedIn,
      history: history ?? List.from(this.history),
    );
  }

  static Player create(String name) {
    return Player(
      id: 'p${DateTime.now().millisecondsSinceEpoch}-${(DateTime.now().microsecondsSinceEpoch % 100000)}',
      name: name,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'played': played,
        'wins': wins,
        'losses': losses,
        'scoreFor': scoreFor,
        'scoreAgainst': scoreAgainst,
        'status': status,
        'checkedIn': checkedIn,
        'history': history.map((h) => h.toJson()).toList(),
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        played: json['played'] as int? ?? 0,
        wins: json['wins'] as int? ?? 0,
        losses: json['losses'] as int? ?? 0,
        scoreFor: json['scoreFor'] as int? ?? 0,
        scoreAgainst: json['scoreAgainst'] as int? ?? 0,
        status: json['status'] as String? ?? 'ready',
        checkedIn: json['checkedIn'] as bool? ?? true,
        history: (json['history'] as List<dynamic>?)
            ?.map((e) => MatchHistoryItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PadelMatch {
  final String id;
  final int matchNumber;
  final int court;
  final List<String> teamA;
  final List<String> teamB;
  int? scoreA;
  int? scoreB;
  String status; // 'playing' | 'finished'

  PadelMatch({
    required this.id,
    required this.matchNumber,
    required this.court,
    required this.teamA,
    required this.teamB,
    this.scoreA,
    this.scoreB,
    this.status = 'playing',
  });

  PadelMatch copyWith({
    int? scoreA,
    int? scoreB,
    String? status,
  }) {
    return PadelMatch(
      id: id,
      matchNumber: matchNumber,
      court: court,
      teamA: List.from(teamA),
      teamB: List.from(teamB),
      scoreA: scoreA ?? this.scoreA,
      scoreB: scoreB ?? this.scoreB,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'matchNumber': matchNumber,
        'court': court,
        'teamA': teamA,
        'teamB': teamB,
        'scoreA': scoreA,
        'scoreB': scoreB,
        'status': status,
      };

  factory PadelMatch.fromJson(Map<String, dynamic> json) => PadelMatch(
        id: json['id'] as String? ?? '',
        matchNumber: json['matchNumber'] as int? ?? 0,
        court: json['court'] as int? ?? 1,
        teamA: (json['teamA'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        teamB: (json['teamB'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        scoreA: json['scoreA'] as int?,
        scoreB: json['scoreB'] as int?,
        status: json['status'] as String? ?? 'playing',
      );
}

class PadelSession {
  String name;
  String date;
  String timeStart;
  String timeEnd;
  int courtsTotal;
  String passcode;

  PadelSession({
    this.name = '',
    this.date = '',
    this.timeStart = '',
    this.timeEnd = '',
    this.courtsTotal = 2,
    this.passcode = '',
  });

  PadelSession copyWith({
    String? name,
    String? date,
    String? timeStart,
    String? timeEnd,
    int? courtsTotal,
    String? passcode,
  }) {
    return PadelSession(
      name: name ?? this.name,
      date: date ?? this.date,
      timeStart: timeStart ?? this.timeStart,
      timeEnd: timeEnd ?? this.timeEnd,
      courtsTotal: courtsTotal ?? this.courtsTotal,
      passcode: passcode ?? this.passcode,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'date': date,
        'timeStart': timeStart,
        'timeEnd': timeEnd,
        'courtsTotal': courtsTotal,
        'passcode': passcode,
      };

  factory PadelSession.fromJson(Map<String, dynamic> json) => PadelSession(
        name: json['name'] as String? ?? '',
        date: json['date'] as String? ?? '',
        timeStart: json['timeStart'] as String? ?? '',
        timeEnd: json['timeEnd'] as String? ?? '',
        courtsTotal: json['courtsTotal'] as int? ?? 2,
        passcode: json['passcode'] as String? ?? '',
      );
}
