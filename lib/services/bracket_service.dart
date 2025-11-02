import 'dart:math';

class Match {
  int matchNo;
  int round;
  String roundName;
  String participant1;
  String participant2;
  bool isBye;
  int? byeParticipant;

  Match({
    required this.matchNo,
    required this.round,
    required this.roundName,
    required this.participant1,
    required this.participant2,
    this.isBye = false,
    this.byeParticipant,
  });
}

class BracketService {
  int totalParticipants;
  int eliminationParticipants;
  int byeCount;
  int byeRounds;
  List<Match> matches = [];
  int matchCounter = 1;

  BracketService({
    required this.totalParticipants,
    required this.eliminationParticipants,
    required this.byeCount,
    required this.byeRounds,
  });

  /// Kontrol fonksiyonu - geçerli parametreleri kontrol eder
  Tuple2<bool, String> validate() {
    if ([totalParticipants, eliminationParticipants, byeCount, byeRounds].any((x) => x < 0)) {
      return Tuple2(false, 'Hiçbir değer negatif olamaz!');
    }
    if (totalParticipants == 0) return Tuple2(false, 'Toplam katılımcı sayısı 0 olamaz!');
    if (eliminationParticipants == 0) return Tuple2(false, 'Elemeye girecek kişi sayısı 0 olamaz!');
    if (eliminationParticipants > totalParticipants) {
      return Tuple2(false, 'Elemeye girecek kişi sayısı toplam katılımcıdan fazla olamaz!');
    }
    if (byeCount > eliminationParticipants) {
      return Tuple2(false, 'Bay geçecek yarışmacı sayısı elemeye girecek kişi sayısından fazla olamaz!');
    }
    if (byeCount % 2 != 0) return Tuple2(false, 'Bay geçecek yarışmacı sayısı çift sayı olmalıdır!');
    
    int mainBracketSize = _calculateMainBracketSize();
    int totalRounds = (log(mainBracketSize) / log(2)).toInt();
    if (byeRounds > totalRounds) {
      return Tuple2(false, 'Bay tur sayısı toplam tur sayısından fazla olamaz!');
    }
    
    int remainingAfterBye = mainBracketSize;
    for (int i = 0; i < byeRounds; i++) remainingAfterBye ~/= 2;
    if (byeCount > remainingAfterBye) {
      return Tuple2(false, 'Bay geçecek $byeCount yarışmacı $byeRounds tur bay geçemez!');
    }
    
    return Tuple2(true, 'Kontroller başarılı!');
  }

  /// Ana bracket boyutunu hesaplar
  int _calculateMainBracketSize() {
    if (_isPowerOfTwo(eliminationParticipants)) return eliminationParticipants;
    return pow(2, (log(eliminationParticipants) / log(2)).ceil()).toInt();
  }

  /// 2'nin kuvveti kontrolü
  bool _isPowerOfTwo(int n) {
    if (n <= 0) return false;
    return (n & (n - 1)) == 0;
  }

  /// Bracket oluşturma ana fonksiyonu
  List<Match> createBracket() {
    var validation = validate();
    if (!validation.item1) throw Exception('Hata: ${validation.item2}');
    
    int mainBracketSize = _calculateMainBracketSize();
    bool needsPreliminaryElimination = eliminationParticipants > mainBracketSize || !_isPowerOfTwo(eliminationParticipants);
    
    matches = [];
    matchCounter = 1;
    List<String> activeParticipants;
    
    if (needsPreliminaryElimination) {
      activeParticipants = _createPreliminaryElimination(mainBracketSize);
    } else {
      activeParticipants = _createFirstRound(eliminationParticipants);
    }
    
    int totalRounds = needsPreliminaryElimination 
        ? (log(mainBracketSize) / log(2)).toInt() + 1 
        : (log(eliminationParticipants) / log(2)).toInt();
    
    for (int round = 2; round <= totalRounds; round++) {
      activeParticipants = _createNextRound(round, activeParticipants, mainBracketSize);
    }
    
    _addThirdPlaceMatch(totalRounds + 1);
    return matches;
  }

  /// Ön eleme turu oluşturma
  List<String> _createPreliminaryElimination(int mainBracketSize) {
    int excessParticipants = eliminationParticipants - mainBracketSize;
    int preliminaryStart = mainBracketSize - excessParticipants + 1;
    
    for (int i = 0; i < excessParticipants; i++) {
      int p1 = preliminaryStart + i;
      int p2 = mainBracketSize + excessParticipants - i;
      matches.add(Match(
        matchNo: matchCounter,
        round: 0,
        roundName: 'Ön Eleme',
        participant1: 'Y$p1',
        participant2: 'Y$p2',
      ));
      matchCounter++;
    }
    
    return _createFirstRoundAfterPreliminary(mainBracketSize, excessParticipants);
  }

  /// Ön eleme sonrası ilk tur oluşturma
  List<String> _createFirstRoundAfterPreliminary(int mainBracketSize, int preliminaryWinners) {
    var byeParticipants = Set.from(List.generate(byeCount, (i) => i + 1));
    var bracketPositions = _createBracketPositions(mainBracketSize);
    List<String> nextRoundParticipants = [];
    int preliminaryMatchCounter = 1;
    var preliminaryPositions = Set.from(List.generate(preliminaryWinners, (i) => mainBracketSize - preliminaryWinners + 1 + i));
    
    for (int i = 0; i < bracketPositions.length; i += 2) {
      int p1 = bracketPositions[i];
      int p2 = bracketPositions[i + 1];
      String p1Str = preliminaryPositions.contains(p1) ? 'M${preliminaryMatchCounter++} Galibi' : 'Y$p1';
      String p2Str = preliminaryPositions.contains(p2) ? 'M${preliminaryMatchCounter++} Galibi' : 'Y$p2';
      bool p1Bye = byeParticipants.contains(p1) && !preliminaryPositions.contains(p1);
      bool p2Bye = byeParticipants.contains(p2) && !preliminaryPositions.contains(p2);
      
      if (p1Bye) p2Str = 'BAY';
      else if (p2Bye) p1Str = 'BAY';
      
      matches.add(Match(
        matchNo: matchCounter,
        round: 1,
        roundName: _getRoundName(1, mainBracketSize),
        participant1: p1Str,
        participant2: p2Str,
        isBye: p1Bye || p2Bye,
        byeParticipant: p1Bye ? p1 : (p2Bye ? p2 : null),
      ));
      
      String winner;
      if (p1Bye) winner = 'Y$p1';
      else if (p2Bye) winner = 'Y$p2';
      else winner = 'M${matchCounter} Galibi';
      nextRoundParticipants.add(winner);
      matchCounter++;
    }
    
    return nextRoundParticipants;
  }

  /// Normal ilk tur oluşturma
  List<String> _createFirstRound(int bracketSize) {
    var byeParticipants = Set.from(List.generate(byeCount, (i) => i + 1));
    var bracketPositions = _createBracketPositions(bracketSize);
    List<String> nextRoundParticipants = [];
    
    for (int i = 0; i < bracketPositions.length; i += 2) {
      int p1 = bracketPositions[i];
      int p2 = bracketPositions[i + 1];
      bool p1Bye = byeParticipants.contains(p1);
      bool p2Bye = byeParticipants.contains(p2);
      
      String p1Str, p2Str;
      if (p1Bye) {
        p1Str = 'Y$p1';
        p2Str = 'BAY';
      } else if (p2Bye) {
        p1Str = 'BAY';
        p2Str = 'Y$p2';
      } else {
        p1Str = 'Y$p1';
        p2Str = 'Y$p2';
      }
      
      matches.add(Match(
        matchNo: matchCounter,
        round: 1,
        roundName: _getRoundName(1, bracketSize),
        participant1: p1Str,
        participant2: p2Str,
        isBye: p1Bye || p2Bye,
        byeParticipant: p1Bye ? p1 : (p2Bye ? p2 : null),
      ));
      
      String winner;
      if (p1Bye) winner = 'Y$p1';
      else if (p2Bye) winner = 'Y$p2';
      else winner = 'M${matchCounter} Galibi';
      nextRoundParticipants.add(winner);
      matchCounter++;
    }
    
    return nextRoundParticipants;
  }

  /// Bracket pozisyonlarını oluşturur (rekürsif algoritma)
  List<int> _createBracketPositions(int n) {
    if (n == 2) return [1, 2];
    var prev = _createBracketPositions(n ~/ 2);
    List<int> result = [];
    for (var pos in prev) {
      result.add(pos);
      result.add(n + 1 - pos);
    }
    return result;
  }

  /// Sonraki tur oluşturma
  List<String> _createNextRound(int round, List<String> previousWinners, int bracketSize) {
    var byeParticipants = Set.from(List.generate(byeCount, (i) => i + 1));
    List<String> nextRoundParticipants = [];
    
    for (int i = 0; i < previousWinners.length; i += 2) {
      if (i + 1 < previousWinners.length) {
        String p1 = previousWinners[i];
        String p2 = previousWinners[i + 1];
        bool p1Bye = false, p2Bye = false;
        
        if (p1.startsWith('Y') && !p1.contains('Galibi') && !p1.contains('Mağlubu')) {
          int p1Num = int.parse(p1.substring(1));
          if (byeParticipants.contains(p1Num) && round <= byeRounds) p1Bye = true;
        }
        if (p2.startsWith('Y') && !p2.contains('Galibi') && !p2.contains('Mağlubu')) {
          int p2Num = int.parse(p2.substring(1));
          if (byeParticipants.contains(p2Num) && round <= byeRounds) p2Bye = true;
        }
        
        String p1Str, p2Str;
        if (p1Bye) {
          p1Str = p1;
          p2Str = 'BAY';
        } else if (p2Bye) {
          p1Str = 'BAY';
          p2Str = p2;
        } else {
          p1Str = p1;
          p2Str = p2;
        }
        
        matches.add(Match(
          matchNo: matchCounter,
          round: round,
          roundName: _getRoundName(round, bracketSize),
          participant1: p1Str,
          participant2: p2Str,
          isBye: p1Bye || p2Bye,
          byeParticipant: p1Bye ? int.parse(p1.substring(1)) : (p2Bye ? int.parse(p2.substring(1)) : null),
        ));
        
        String winner;
        if (p1Bye) winner = p1;
        else if (p2Bye) winner = p2;
        else winner = 'M${matchCounter} Galibi';
        nextRoundParticipants.add(winner);
        matchCounter++;
      }
    }
    
    return nextRoundParticipants;
  }

  /// 3.lük maçı ekleme
  void _addThirdPlaceMatch(int round) {
    if (matches.length >= 2) {
      int semifinal1 = matches[matches.length - 2].matchNo;
      int semifinal2 = matches[matches.length - 1].matchNo;
      matches.add(Match(
        matchNo: matchCounter,
        round: round,
        roundName: '3.lük Maçı',
        participant1: 'M$semifinal1 Mağlubu',
        participant2: 'M$semifinal2 Mağlubu',
      ));
      matchCounter++;
    }
  }

  /// Tur adı alma
  String _getRoundName(int round, int bracketSize) {
    if (round == 0) return 'Ön Eleme';
    int totalRounds = (log(bracketSize) / log(2)).toInt();
    if (round == totalRounds) return 'Final';
    if (round == totalRounds - 1) return 'Yarı Final';
    if (round == totalRounds - 2) return 'Çeyrek Final';
    int participantsInRound = pow(2, totalRounds - round + 1).toInt();
    return '1/$participantsInRound Final';
  }

  /// Bracket yazdırma (debug için)
  void printBracket() {
    if (matches.isEmpty) {
      print('Henüz bracket oluşturulmadı!');
      return;
    }
    
    print('\n' + '=' * 80);
    print('BRAKET EŞLEŞMELERİ');
    print('=' * 80 + '\n');
    
    int currentRound = -1;
    for (var match in matches) {
      if (match.round != currentRound) {
        currentRound = match.round;
        print('\n' + '-' * 80);
        print('TUR $currentRound: ${match.roundName}');
        print('-' * 80);
      }
      
      String byeIndicator = match.isBye ? ' (BAY)' : '';
      print('Maç ${match.matchNo.toString().padRight(3)} | ${match.participant1.padRight(20)} vs ${match.participant2.padRight(20)}$byeIndicator');
    }
    
    print('\n' + '=' * 80 + '\n');
  }
}

class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;
  Tuple2(this.item1, this.item2);
}
