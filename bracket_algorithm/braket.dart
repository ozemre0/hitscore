import 'dart:io';
import 'dart:math';

class Mac {
  int macNo;
  int tur;
  String turAdi;
  String yarisimaci1;
  String yarisimaci2;
  Mac(this.macNo, this.tur, this.turAdi, this.yarisimaci1, this.yarisimaci2);
}

class BraketOlusturucu {
  int toplamKatilimci;
  int elemeyeGirecek;
  int baySayisi;
  int bayTurSayisi;
  List<Mac> maclar = [];
  int macSayaci = 1;

  BraketOlusturucu(this.toplamKatilimci, this.elemeyeGirecek, this.baySayisi, this.bayTurSayisi);

  Tuple2<bool, String> kontrolEt() {
    if ([toplamKatilimci, elemeyeGirecek, baySayisi, bayTurSayisi].any((x) => x < 0)) {
      return Tuple2(false, 'Hiçbir değer negatif olamaz!');
    }
    if (toplamKatilimci == 0) return Tuple2(false, 'Toplam katılımcı sayısı 0 olamaz!');
    if (elemeyeGirecek == 0) return Tuple2(false, 'Elemeye girecek kişi sayısı 0 olamaz!');
    if (elemeyeGirecek > toplamKatilimci) return Tuple2(false, 'Elemeye girecek kişi sayısı toplam katılımcıdan fazla olamaz!');
    if (baySayisi > elemeyeGirecek) return Tuple2(false, 'Bay geçecek yarışmacı sayısı elemeye girecek kişi sayısından fazla olamaz!');
    if (baySayisi % 2 != 0) return Tuple2(false, 'Bay geçecek yarışmacı sayısı çift sayı olmalıdır!');
    int anaBraketBoyutu = _anaBraketBoyutuHesapla();
    int toplamTur = (log(anaBraketBoyutu) / log(2)).toInt();
    if (bayTurSayisi > toplamTur) return Tuple2(false, 'Bay tur sayısı toplam tur sayısından fazla olamaz!');
    int baySonrasiKalan = anaBraketBoyutu;
    for (int i = 0; i < bayTurSayisi; i++) baySonrasiKalan ~/= 2;
    if (baySayisi > baySonrasiKalan) return Tuple2(false, 'Bay geçecek $baySayisi yarışmacı $bayTurSayisi tur bay geçemez!');
    return Tuple2(true, 'Kontroller başarılı!');
  }

  int _anaBraketBoyutuHesapla() {
    if (_ikininKuvvetiMi(elemeyeGirecek)) return elemeyeGirecek;
    return pow(2, (log(elemeyeGirecek) / log(2)).ceil()).toInt();
  }

  bool _ikininKuvvetiMi(int n) {
    if (n <= 0) return false;
    return (n & (n - 1)) == 0;
  }

  List<Mac> braketOlustur() {
    var kontrol = kontrolEt();
    if (!kontrol.item1) throw Exception('Hata: ${kontrol.item2}');
    int anaBraketBoyutu = _anaBraketBoyutuHesapla();
    bool onElemeGerekli = elemeyeGirecek > anaBraketBoyutu || !_ikininKuvvetiMi(elemeyeGirecek);
    maclar = [];
    macSayaci = 1;
    List<String> aktifYarismacilar;
    if (onElemeGerekli) {
      aktifYarismacilar = _onElemeTuruOlustur(anaBraketBoyutu);
    } else {
      aktifYarismacilar = _ilkTuruOlustur(elemeyeGirecek);
    }
    int toplamTur = onElemeGerekli ? (log(anaBraketBoyutu) / log(2)).toInt() + 1 : (log(elemeyeGirecek) / log(2)).toInt();
    for (int tur = 2; tur <= toplamTur; tur++) {
      aktifYarismacilar = _sonrakiTuruOlustur(tur, aktifYarismacilar, anaBraketBoyutu);
    }
    _ucunculukMaciEkle(toplamTur + 1);
    return maclar;
  }

  List<String> _onElemeTuruOlustur(int anaBraketBoyutu) {
    int fazlaYarismaci = elemeyeGirecek - anaBraketBoyutu;
    int onElemeBaslangic = anaBraketBoyutu - fazlaYarismaci + 1;
    for (int i = 0; i < fazlaYarismaci; i++) {
      int y1 = onElemeBaslangic + i;
      int y2 = anaBraketBoyutu + fazlaYarismaci - i;
      maclar.add(Mac(macSayaci, 0, 'Ön Eleme', 'Y$y1', 'Y$y2'));
      macSayaci++;
    }
    return _ilkTuruOlusturOnElemeSonrasi(anaBraketBoyutu, fazlaYarismaci);
  }

  List<String> _ilkTuruOlusturOnElemeSonrasi(int anaBraketBoyutu, int onElemeGalipSayisi) {
    var bayGecirenler = Set.from(List.generate(baySayisi, (i) => i + 1));
    var braketPozisyonlari = _braketPozisyonlariOlustur(anaBraketBoyutu);
    List<String> sonrakiTuraGidenler = [];
    int onElemeMacSayaci = 1;
    var onElemePozisyonlari = Set.from(List.generate(onElemeGalipSayisi, (i) => anaBraketBoyutu - onElemeGalipSayisi + 1 + i));
    for (int i = 0; i < braketPozisyonlari.length; i += 2) {
      int y1 = braketPozisyonlari[i];
      int y2 = braketPozisyonlari[i + 1];
      String y1Str = onElemePozisyonlari.contains(y1) ? 'M${onElemeMacSayaci++} Galibi' : 'Y$y1';
      String y2Str = onElemePozisyonlari.contains(y2) ? 'M${onElemeMacSayaci++} Galibi' : 'Y$y2';
      bool y1Bay = bayGecirenler.contains(y1) && !onElemePozisyonlari.contains(y1);
      bool y2Bay = bayGecirenler.contains(y2) && !onElemePozisyonlari.contains(y2);
      if (y1Bay) y2Str = 'BAY';
      else if (y2Bay) y1Str = 'BAY';
      maclar.add(Mac(macSayaci, 1, _turAdiAl(1, anaBraketBoyutu), y1Str, y2Str));
      String galip;
      if (y1Bay) galip = 'Y$y1';
      else if (y2Bay) galip = 'Y$y2';
      else galip = 'M${macSayaci} Galibi';
      sonrakiTuraGidenler.add(galip);
      macSayaci++;
    }
    return sonrakiTuraGidenler;
  }

  List<String> _ilkTuruOlustur(int braketBoyutu) {
    var bayGecirenler = Set.from(List.generate(baySayisi, (i) => i + 1));
    var braketPozisyonlari = _braketPozisyonlariOlustur(braketBoyutu);
    List<String> sonrakiTuraGidenler = [];
    for (int i = 0; i < braketPozisyonlari.length; i += 2) {
      int y1 = braketPozisyonlari[i];
      int y2 = braketPozisyonlari[i + 1];
      bool y1Bay = bayGecirenler.contains(y1);
      bool y2Bay = bayGecirenler.contains(y2);
      String y1Str, y2Str;
      if (y1Bay) {
        y1Str = 'Y$y1';
        y2Str = 'BAY';
      } else if (y2Bay) {
        y1Str = 'BAY';
        y2Str = 'Y$y2';
      } else {
        y1Str = 'Y$y1';
        y2Str = 'Y$y2';
      }
      maclar.add(Mac(macSayaci, 1, _turAdiAl(1, braketBoyutu), y1Str, y2Str));
      String galip;
      if (y1Bay) galip = 'Y$y1';
      else if (y2Bay) galip = 'Y$y2';
      else galip = 'M${macSayaci} Galibi';
      sonrakiTuraGidenler.add(galip);
      macSayaci++;
    }
    return sonrakiTuraGidenler;
  }

  List<int> _braketPozisyonlariOlustur(int n) {
    if (n == 2) return [1, 2];
    var prev = _braketPozisyonlariOlustur(n ~/ 2);
    List<int> result = [];
    for (var pos in prev) {
      result.add(pos);
      result.add(n + 1 - pos);
    }
    return result;
  }

  List<String> _sonrakiTuruOlustur(int tur, List<String> oncekiTurGalipler, int braketBoyutu) {
    var bayGecirenler = Set.from(List.generate(baySayisi, (i) => i + 1));
    List<String> sonrakiTuraGidenler = [];
    for (int i = 0; i < oncekiTurGalipler.length; i += 2) {
      if (i + 1 < oncekiTurGalipler.length) {
        String y1 = oncekiTurGalipler[i];
        String y2 = oncekiTurGalipler[i + 1];
        bool y1Bay = false, y2Bay = false;
        if (y1.startsWith('Y') && !y1.contains('Galibi') && !y1.contains('Mağlubu')) {
          int y1Num = int.parse(y1.substring(1));
          if (bayGecirenler.contains(y1Num) && tur <= bayTurSayisi) y1Bay = true;
        }
        if (y2.startsWith('Y') && !y2.contains('Galibi') && !y2.contains('Mağlubu')) {
          int y2Num = int.parse(y2.substring(1));
          if (bayGecirenler.contains(y2Num) && tur <= bayTurSayisi) y2Bay = true;
        }
        String y1Str, y2Str;
        if (y1Bay) {
          y1Str = y1;
          y2Str = 'BAY';
        } else if (y2Bay) {
          y1Str = 'BAY';
          y2Str = y2;
        } else {
          y1Str = y1;
          y2Str = y2;
        }
        maclar.add(Mac(macSayaci, tur, _turAdiAl(tur, braketBoyutu), y1Str, y2Str));
        String galip;
        if (y1Bay) galip = y1;
        else if (y2Bay) galip = y2;
        else galip = 'M${macSayaci} Galibi';
        sonrakiTuraGidenler.add(galip);
        macSayaci++;
      }
    }
    return sonrakiTuraGidenler;
  }

  void _ucunculukMaciEkle(int tur) {
    if (maclar.length >= 2) {
      int semifinal1 = maclar[maclar.length - 2].macNo;
      int semifinal2 = maclar[maclar.length - 1].macNo;
      maclar.add(Mac(macSayaci, tur, '3.lük Maçı', 'M$semifinal1 Mağlubu', 'M$semifinal2 Mağlubu'));
      macSayaci++;
    }
  }

  String _turAdiAl(int tur, int braketBoyutu) {
    if (tur == 0) return 'Ön Eleme';
    int toplamTur = (log(braketBoyutu) / log(2)).toInt();
    if (tur == toplamTur) return 'Final';
    if (tur == toplamTur - 1) return 'Yarı Final';
    if (tur == toplamTur - 2) return 'Çeyrek Final';
    int oTurdakiYarismaci = pow(2, toplamTur - tur + 1).toInt();
    return '1/$oTurdakiYarismaci Final';
  }

  void braketYazdir() {
    if (maclar.isEmpty) {
      print('Henüz braket oluşturulmadı!');
      return;
    }
    print('\n' + '=' * 80);
    print('BRAKET EŞLEŞMELERİ');
    print('=' * 80 + '\n');
    int mevcutTur = 0;
    for (var mac in maclar) {
      if (mac.tur != mevcutTur) {
        mevcutTur = mac.tur;
        print('\n' + '-' * 80);
        print('TUR $mevcutTur: ${mac.turAdi}');
        print('-' * 80);
      }
      print('Maç ${mac.macNo.toString().padRight(3)} | ${mac.yarisimaci1.padRight(20)} vs ${mac.yarisimaci2.padRight(20)}');
    }
    print('\n' + '=' * 80 + '\n');
  }
}

class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;
  Tuple2(this.item1, this.item2);
}

void main() {
  print('=' * 60);
  print('OKÇULUK YARIŞMASI - TEK ELEMELİ BRAKET OLUŞTURUCU');
  print('=' * 60);
  try {
    stdout.write('Toplam katılımcı sayısı: ');
    int toplamKatilimci = int.parse(stdin.readLineSync()!);
    stdout.write('Elemeye girecek kişi sayısı: ');
    int elemeyeGirecek = int.parse(stdin.readLineSync()!);
    stdout.write('Bay geçecek yarışmacı sayısı (çift sayı olmalı): ');
    int baySayisi = int.parse(stdin.readLineSync()!);
    stdout.write('Bay geçecek yarışmacılar kaç tur bay geçecek: ');
    int bayTurSayisi = int.parse(stdin.readLineSync()!);
    var braket = BraketOlusturucu(toplamKatilimci, elemeyeGirecek, baySayisi, bayTurSayisi);
    braket.braketOlustur();
    braket.braketYazdir();
  } catch (e) {
    print('\nHATA: $e');
  }
}
