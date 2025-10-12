# 🏹 Eleme Sistemi Logic Dokümantasyonu

## 📋 Genel Bakış

Bu dokümantasyon, Hit Score uygulamasındaki eleme sistemi için detaylı iş mantığını açıklar. Sistem, farklı yay türleri için farklı eleme formatları kullanır.

## 🎯 Yay Türü Bazlı Eleme Sistemleri

### 1. Klasik Yay (Recurve) ve Barebow Eleme Sistemi

#### Temel Kurallar
- **Seri Formatı**: Her seri 3 ok
- **Puanlama Sistemi**: 
  - Kazanan: 2 puan
  - Beraberlik: 1 puan (her iki sporcu)
  - Kaybeden: 0 puan
- **Kazanma Koşulu**: 6 puan
- **Maksimum Seri**: 5 seri
- **Beraberlik Atışı**: 5-5 durumunda tek ok atışı

#### Seri Hesaplama Logic
```
Her seri için:
  Eğer Sporcu1 > Sporcu2:
    Sporcu1 += 2 puan
    Sporcu2 += 0 puan
  Eğer Sporcu1 = Sporcu2:
    Sporcu1 += 1 puan
    Sporcu2 += 1 puan
  Eğer Sporcu1 < Sporcu2:
    Sporcu1 += 0 puan
    Sporcu2 += 2 puan

Kazanma kontrolü:
  Eğer herhangi bir sporcu >= 6 puan:
    Maç biter
  Eğer 5 seri tamamlandı ve 5-5:
    Beraberlik atışı yapılır
```

#### Beraberlik Atışı Logic
```
5-5 durumunda:
  1. Her sporcu 1 ok atar
  2. Merkeze en yakın ok kazanır
  3. Kazanan 6-5 ile maçı kazanır
  4. Eğer hala beraberlik:
     Tekrar 1 ok atışı yapılır
```

#### Örnek Maç Senaryoları

**Senaryo 1: Normal Kazanma**
```
Seri 1: Sporcu1: 28, Sporcu2: 26 → Sporcu1: 2, Sporcu2: 0
Seri 2: Sporcu1: 27, Sporcu2: 29 → Sporcu1: 2, Sporcu2: 2
Seri 3: Sporcu1: 30, Sporcu2: 28 → Sporcu1: 4, Sporcu2: 2
Seri 4: Sporcu1: 29, Sporcu2: 27 → Sporcu1: 6, Sporcu2: 2
Sonuç: Sporcu1 kazandı (6-2)
```

**Senaryo 2: Beraberlik Atışı**
```
Seri 1: Sporcu1: 28, Sporcu2: 28 → Sporcu1: 1, Sporcu2: 1
Seri 2: Sporcu1: 27, Sporcu2: 29 → Sporcu1: 1, Sporcu2: 3
Seri 3: Sporcu1: 30, Sporcu2: 28 → Sporcu1: 3, Sporcu2: 3
Seri 4: Sporcu1: 29, Sporcu2: 27 → Sporcu1: 5, Sporcu2: 3
Seri 5: Sporcu1: 28, Sporcu2: 30 → Sporcu1: 5, Sporcu2: 5
Beraberlik Atışı: Sporcu1: 9, Sporcu2: 10 → Sporcu2 kazandı (6-5)
```

### 2. Makaralı Yay (Compound) Eleme Sistemi

#### Temel Kurallar
- **Seri Formatı**: 5 seri, her seri 3 ok
- **Toplam Skor**: 150 üzerinden (5 × 30)
- **Kazanma Koşulu**: En yüksek toplam skor
- **Beraberlik Durumu**: Merkeze en yakın ok

#### Skor Hesaplama Logic
```
Her seri için:
  Sporcu1_SeriSkoru = 3 okun toplamı
  Sporcu2_SeriSkoru = 3 okun toplamı

Toplam skor hesaplama:
  Sporcu1_Toplam = Tüm serilerin toplamı
  Sporcu2_Toplam = Tüm serilerin toplamı

Kazanma kontrolü:
  Eğer Sporcu1_Toplam > Sporcu2_Toplam:
    Sporcu1 kazandı
  Eğer Sporcu1_Toplam < Sporcu2_Toplam:
    Sporcu2 kazandı
  Eğer Sporcu1_Toplam = Sporcu2_Toplam:
    Beraberlik atışı yapılır
```

#### Beraberlik Atışı Logic (Compound)
```
Eşit skor durumunda:
  1. Her sporcu 1 ok atar
  2. Merkeze en yakın ok kazanır
  3. Eğer hala beraberlik:
     Tekrar 1 ok atışı yapılır
```

#### Örnek Maç Senaryoları

**Senaryo 1: Normal Kazanma**
```
Seri 1: Sporcu1: 29, Sporcu2: 28 → Toplam: 29-28
Seri 2: Sporcu1: 30, Sporcu2: 29 → Toplam: 59-57
Seri 3: Sporcu1: 28, Sporcu2: 30 → Toplam: 87-87
Seri 4: Sporcu1: 30, Sporcu2: 29 → Toplam: 117-116
Seri 5: Sporcu1: 29, Sporcu2: 28 → Toplam: 146-144
Sonuç: Sporcu1 kazandı (146-144)
```

**Senaryo 2: Beraberlik Atışı**
```
Seri 1: Sporcu1: 30, Sporcu2: 30 → Toplam: 30-30
Seri 2: Sporcu1: 29, Sporcu2: 29 → Toplam: 59-59
Seri 3: Sporcu1: 30, Sporcu2: 30 → Toplam: 89-89
Seri 4: Sporcu1: 29, Sporcu2: 29 → Toplam: 118-118
Seri 5: Sporcu1: 30, Sporcu2: 30 → Toplam: 148-148
Beraberlik Atışı: Sporcu1: 10, Sporcu2: 9 → Sporcu1 kazandı
```

## 🏆 Eleme Sistemi Entegrasyonu

### 1. Yarışma Oluşturma Aşaması
```
1. Eleme sistemi etkinleştirilir
2. Yay türü seçilir (Recurve/Barebow/Compound)
3. Eleme formatı otomatik belirlenir
4. Bracket boyutu ayarlanır
5. Kesme sınırı belirlenir
```

### 2. Sıralama Turu Sonrası
```
1. Sıralama sonuçları hesaplanır
2. Kesme sınırı uygulanır
3. Bracket oluşturulur
4. Bay geçme hesaplanır
5. Eleme maçları planlanır
```

### 3. Eleme Maçları
```
1. Maç başlatılır
2. Yay türüne göre format seçilir
3. Skorlar girilir
4. Beraberlik durumu kontrol edilir
5. Kazanan belirlenir
6. Sonraki tur planlanır
```

## 🏃 Bay Geçme Sistemi Detayları

### 1. Bay Geçme Mantığı

#### Temel Kavramlar
- **Bay Geçme (Bye)**: Bracket'te eşleşme olmayan sporcuların otomatik olarak bir sonraki tura geçmesi
- **Bracket Boyutu**: 8, 16, 32, 64 gibi 2'nin kuvvetleri
- **Kesme Sınırı**: Eleme turuna katılacak maksimum katılımcı sayısı
- **Hibrit Sistem**: Kesme sınırı + bay geçme kombinasyonu

#### Bay Geçme Hesaplama Algoritması
```
1. Kesme sınırı uygulanır (en iyi N katılımcı seçilir)
2. Bracket boyutu belirlenir
3. Bay geçme hesaplanır:

Eğer Kesme Katılımcı Sayısı = Bracket Boyutu:
  Bay Geçme = 0
  Tüm katılımcılar eşleşir

Eğer Kesme Katılımcı Sayısı < Bracket Boyutu:
  Bay Geçme = Bracket Boyutu - Kesme Katılımcı Sayısı
  En yüksek sıralamalı N katılımcı bay geçer

Eğer Kesme Katılımcı Sayısı > Bracket Boyutu:
  Bay Geçme = 0
  En iyi Bracket Boyutu kadar katılımcı seçilir
  Fazla katılımcılar elenir
```

### 2. Bay Geçme Dağılım Stratejileri

#### Strateji 1: En Yüksek Sıralama Önceliği
```
Bay geçen katılımcılar = En yüksek sıralamalı N katılımcı
Eşleşen katılımcılar = Kalan katılımcılar

Örnek: 12 katılımcı, 16'lık bracket
- Bay geçen: 1, 2, 3, 4 (en yüksek sıralamalı 4 kişi)
- Eşleşen: 5-12 arası 8 kişi (4 eşleşme)
```

#### Strateji 2: Eşit Dağılım
```
Bay geçen katılımcılar = Bracket boyutuna göre eşit dağıtılan katılımcılar
Eşleşen katılımcılar = Kalan katılımcılar

Örnek: 20 katılımcı, 32'lik bracket
- Bay geçen: 1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23 (12 kişi)
- Eşleşen: 2, 4, 6, 8, 10, 12, 14, 16, 18, 20 (10 kişi, 5 eşleşme)
```

#### Strateji 3: Performans Bazlı
```
Bay geçen katılımcılar = En yüksek performans gösteren katılımcılar
Performans kriterleri:
- Toplam skor
- 10'luk sayısı
- X sayısı
- Son tur performansı

Örnek: 25 katılımcı, 16'lık bracket
- Bay geçen: En yüksek 9 performans gösteren katılımcı
- Eşleşen: Kalan 7 katılımcı (3.5 eşleşme → 4 eşleşme)
```

### 3. Bay Geçme Senaryoları

#### Senaryo 1: 50 Katılımcı, 16 Kesme, 32 Bracket
```
1. Kesme: En iyi 16 katılımcı seçilir
2. Bracket: 32 (16'dan büyük)
3. Bay Geçme: 32 - 16 = 16 bay
4. Dağılım:
   - Bay geçen: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
   - Eşleşen: 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32
   - Eşleşme: 8 maç
```

#### Senaryo 2: 30 Katılımcı, 20 Kesme, 16 Bracket
```
1. Kesme: En iyi 20 katılımcı seçilir
2. Bracket: 16 (20'den küçük)
3. Bay Geçme: 0 (bracket dolu)
4. Dağılım:
   - Bay geçen: Yok
   - Eşleşen: En iyi 16 katılımcı
   - Eşleşme: 8 maç
   - Elenen: 17, 18, 19, 20 (4 katılımcı)
```

#### Senaryo 3: 25 Katılımcı, 16 Kesme, 16 Bracket
```
1. Kesme: En iyi 16 katılımcı seçilir
2. Bracket: 16 (16'ya eşit)
3. Bay Geçme: 0 (tam dolu)
4. Dağılım:
   - Bay geçen: Yok
   - Eşleşen: Tüm 16 katılımcı
   - Eşleşme: 8 maç
   - Elenen: 17, 18, 19, 20, 21, 22, 23, 24, 25 (9 katılımcı)
```

#### Senaryo 4: 12 Katılımcı, 16 Kesme, 16 Bracket
```
1. Kesme: En iyi 12 katılımcı seçilir
2. Bracket: 16 (12'den büyük)
3. Bay Geçme: 16 - 12 = 4 bay
4. Dağılım:
   - Bay geçen: 1, 2, 3, 4 (en yüksek sıralamalı 4 kişi)
   - Eşleşen: 5, 6, 7, 8, 9, 10, 11, 12 (8 kişi)
   - Eşleşme: 4 maç
```

### 4. Bay Geçme Optimizasyonu

#### Bracket Boyutu Otomatik Ayarlama
```
Eğer Kesme Katılımcı Sayısı > 64:
  Bracket = 128
Eğer Kesme Katılımcı Sayısı > 32:
  Bracket = 64
Eğer Kesme Katılımcı Sayısı > 16:
  Bracket = 32
Eğer Kesme Katılımcı Sayısı > 8:
  Bracket = 16
Eğer Kesme Katılımcı Sayısı ≤ 8:
  Bracket = 8
```

#### Bay Geçme Oranı Optimizasyonu
```
Optimal Bay Geçme Oranı: %25-50 arası

Eğer Bay Geçme Oranı > %50:
  Bracket boyutunu küçült
Eğer Bay Geçme Oranı < %25:
  Bracket boyutunu büyült
Eğer Bay Geçme Oranı = %0:
  Bracket tam dolu, bay geçme yok
```

### 5. Bay Geçme UI/UX Gereksinimleri

#### Bay Geçme Gösterimi
```
- Bay geçen katılımcılar özel işaretleme ile gösterilir
- Bay geçme nedeni açıklanır (sıralama, performans, vb.)
- Bay geçme sayısı ve oranı gösterilir
- Bay geçen katılımcıların sonraki turda hangi pozisyonda olacağı belirtilir
```

#### Bay Geçme Yönetimi
```
- Bay geçme stratejisi seçimi
- Manuel bay geçme ayarlama
- Bay geçme önizleme
- Bay geçme geçmişi
```

### 6. Bay Geçme Veri Yapısı

#### Bay Geçme Tablosu
```
elimination_byes:
  - bye_id: UUID
  - competition_id: UUID
  - classification_id: UUID
  - round_id: UUID
  - participant_id: UUID
  - bye_reason: VARCHAR (ranking/performance/manual)
  - bye_position: INTEGER
  - next_round_position: INTEGER
  - created_at: TIMESTAMP
```

#### Bay Geçme JSON Yapısı
```json
{
  "byes": [
    {
      "participant_id": "uuid",
      "participant_name": "Sporcu Adı",
      "ranking": 1,
      "bye_reason": "ranking",
      "bye_position": 1,
      "next_round_position": 1
    }
  ],
  "bye_count": 4,
  "bye_percentage": 25.0,
  "strategy": "highest_ranking"
}
```

### 7. Bay Geçme Algoritması Pseudocode

```
FUNCTION calculateByes(participants, bracketSize, cutoffCount):
  IF cutoffCount <= bracketSize:
    byeCount = bracketSize - cutoffCount
    byeParticipants = participants.take(byeCount)
    competingParticipants = participants.skip(byeCount)
  ELSE:
    byeCount = 0
    byeParticipants = []
    competingParticipants = participants.take(bracketSize)
  
  RETURN {
    byeCount: byeCount,
    byeParticipants: byeParticipants,
    competingParticipants: competingParticipants,
    byePercentage: (byeCount / bracketSize) * 100
  }

FUNCTION distributeByes(participants, byeCount, strategy):
  SWITCH strategy:
    CASE "highest_ranking":
      RETURN participants.take(byeCount)
    CASE "even_distribution":
      RETURN participants.filter(index % 2 == 0).take(byeCount)
    CASE "performance_based":
      RETURN participants.sortByPerformance().take(byeCount)
    DEFAULT:
      RETURN participants.take(byeCount)
```
0## 🎯 Kullanıcı Kesme Sınırı + Kombinasyon Sistemi

### 1. Kullanıcı Kesme Sınırı Mantığı

#### Temel Kavram
- **Kullanıcı Kesme Sınırı**: Organizatörün manuel olarak belirlediği kesme noktası
- **Alt Taraf**: Kesme sınırının altında kalan katılımcılar (eleme turuna giremez)
- **Üst Taraf**: Kesme sınırının üstünde kalan katılımcılar (eleme turuna girer)
- **Kombinasyon Sistemi**: Üst taraf için olası tüm bracket kombinasyonlarını gösterme

#### Kullanıcı Kesme Sınırı Seçimi
```
1. Kullanıcı kesme sınırını belirler (örn: 20. sıra)
2. Alt taraf: 21, 22, 23, 24, 25... (eleme turuna giremez)
3. Üst taraf: 1, 2, 3, 4, 5... 20 (eleme turuna girer)
4. Sistem üst taraf için olası kombinasyonları hesaplar
```

### 2. Bay Geçme + Kombinasyon Sistemi

#### Adım 1: Bay Geçme Sorusu
```
Kullanıcıya sorulur:
"Üst taraf katılımcıları için bay geçme uygulanacak mı?"

Seçenekler:
- Evet, bay geçme uygula
- Hayır, bay geçme uygulama
```

#### Adım 2: Kombinasyon Hesaplama
```
Eğer Bay Geçme = Evet:
  Tüm olası bracket boyutları hesaplanır
  Her bracket boyutu için bay geçme kombinasyonları gösterilir

Eğer Bay Geçme = Hayır:
  Sadece tam dolu bracket kombinasyonları gösterilir
  Bay geçme olmayan senaryolar hesaplanır
```

### 3. Olası Kombinasyon Hesaplama

#### Bay Geçme Uygulanan Senaryolar
```
Üst Taraf Katılımcı Sayısı: N
Olası Bracket Boyutları: [8, 16, 32, 64, 128]

Her bracket boyutu için:
  Eğer N <= Bracket Boyutu:
    Bay Geçme = Bracket Boyutu - N
    Eşleşme = N
    Kombinasyon = "N katılımcı + (Bracket-N) bay"
  Eğer N > Bracket Boyutu:
    Bay Geçme = 0
    Eşleşme = Bracket Boyutu
    Elenen = N - Bracket Boyutu
    Kombinasyon = "Bracket Boyutu katılımcı + (N-Bracket) elenen"
```

#### Bay Geçme Uygulanmayan Senaryolar
```
Üst Taraf Katılımcı Sayısı: N
Olası Bracket Boyutları: [8, 16, 32, 64, 128]

Her bracket boyutu için:
  Eğer N = Bracket Boyutu:
    Bay Geçme = 0
    Eşleşme = N
    Kombinasyon = "N katılımcı (tam dolu)"
  Eğer N > Bracket Boyutu:
    Bay Geçme = 0
    Eşleşme = Bracket Boyutu
    Elenen = N - Bracket Boyutu
    Kombinasyon = "Bracket Boyutu katılımcı + (N-Bracket) elenen"
  Eğer N < Bracket Boyutu:
    Kombinasyon = "Mümkün değil (bay geçme gerekli)"
```

### 4. Kombinasyon Gösterim Örnekleri

#### Örnek: 25 Katılımcı, Kesme Sınırı 20
```
Üst Taraf: 20 katılımcı (1-20. sıra)
Alt Taraf: 5 katılımcı (21-25. sıra) - Eleme turuna giremez

Bay Geçme = Evet:
┌─────────────────┬─────────────┬─────────────┬─────────────┬─────────────┐
│ Bracket Boyutu  │ Bay Geçme   │ Eşleşme     │ Elenen      │ Açıklama    │
├─────────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│ 8               │ 0           │ 8           │ 12          │ 8 katılımcı │
│ 16              │ 0           │ 16          │ 4           │ 16 katılımcı│
│ 32              │ 12          │ 8           │ 0           │ 12 bay + 8  │
│ 64              │ 44          │ 8           │ 0           │ 44 bay + 8  │
│ 128             │ 108         │ 8           │ 0           │ 108 bay + 8 │
└─────────────────┴─────────────┴─────────────┴─────────────┴─────────────┘

Bay Geçme = Hayır:
┌─────────────────┬─────────────┬─────────────┬─────────────┬─────────────┐
│ Bracket Boyutu  │ Bay Geçme   │ Eşleşme     │ Elenen      │ Açıklama    │
├─────────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│ 8               │ 0           │ 8           │ 12          │ 8 katılımcı │
│ 16              │ 0           │ 16          │ 4           │ 16 katılımcı│
│ 32              │ Mümkün değil│ Mümkün değil│ Mümkün değil│ Bay geçme   │
│ 64              │ Mümkün değil│ Mümkün değil│ Mümkün değil│ Bay geçme   │
│ 128             │ Mümkün değil│ Mümkün değil│ Mümkün değil│ Bay geçme   │
└─────────────────┴─────────────┴─────────────┴─────────────┴─────────────┘
```

#### Örnek: 15 Katılımcı, Kesme Sınırı 12
```
Üst Taraf: 12 katılımcı (1-12. sıra)
Alt Taraf: 3 katılımcı (13-15. sıra) - Eleme turuna giremez

Bay Geçme = Evet:
┌─────────────────┬─────────────┬─────────────┬─────────────┬─────────────┐
│ Bracket Boyutu  │ Bay Geçme   │ Eşleşme     │ Elenen      │ Açıklama    │
├─────────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│ 8               │ 0           │ 8           │ 4           │ 8 katılımcı │
│ 16              │ 4           │ 8           │ 0           │ 4 bay + 8   │
│ 32              │ 20          │ 8           │ 0           │ 20 bay + 8  │
│ 64              │ 52          │ 8           │ 0           │ 52 bay + 8  │
│ 128             │ 116         │ 8           │ 0           │ 116 bay + 8 │
└─────────────────┴─────────────┴─────────────┴─────────────┴─────────────┘

Bay Geçme = Hayır:
┌─────────────────┬─────────────┬─────────────┬─────────────┬─────────────┐
│ Bracket Boyutu  │ Bay Geçme   │ Eşleşme     │ Elenen      │ Açıklama    │
├─────────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│ 8               │ 0           │ 8           │ 4           │ 8 katılımcı │
│ 16              │ Mümkün değil│ Mümkün değil│ Mümkün değil│ Bay geçme   │
│ 32              │ Mümkün değil│ Mümkün değil│ Mümkün değil│ Bay geçme   │
│ 64              │ Mümkün değil│ Mümkün değil│ Mümkün değil│ Bay geçme   │
│ 128             │ Mümkün değil│ Mümkün değil│ Mümkün değil│ Bay geçme   │
└─────────────────┴─────────────┴─────────────┴─────────────┴─────────────┘
```

### 5. Kombinasyon Seçim UI/UX

#### Adım 1: Kesme Sınırı Seçimi
```
Kullanıcı arayüzü:
┌─────────────────────────────────────────────────────────────┐
│ Kesme Sınırı Seçimi                                        │
├─────────────────────────────────────────────────────────────┤
│ Toplam Katılımcı: 25                                       │
│                                                             │
│ Kesme Sınırı: [20] ← Slider (1-25)                        │
│                                                             │
│ Üst Taraf: 20 katılımcı (1-20. sıra)                      │
│ Alt Taraf: 5 katılımcı (21-25. sıra) - Eleme turuna giremez│
│                                                             │
│ [Devam Et]                                                  │
└─────────────────────────────────────────────────────────────┘
```

#### Adım 2: Bay Geçme Seçimi
```
Kullanıcı arayüzü:
┌─────────────────────────────────────────────────────────────┐
│ Bay Geçme Uygulanacak mı?                                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ ○ Evet, bay geçme uygula                                   │
│ ○ Hayır, bay geçme uygulama                                │
│                                                             │
│ [Devam Et]                                                  │
└─────────────────────────────────────────────────────────────┘
```

#### Adım 3: Kombinasyon Seçimi
```
Kullanıcı arayüzü:
┌─────────────────────────────────────────────────────────────┐
│ Bracket Kombinasyonu Seçin                                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ ○ 8'lık Bracket    - 8 katılımcı, 12 elenen               │
│ ○ 16'lık Bracket   - 16 katılımcı, 4 elenen               │
│ ● 32'lık Bracket   - 12 bay + 8 eşleşme                   │
│ ○ 64'lük Bracket   - 44 bay + 8 eşleşme                   │
│ ○ 128'lik Bracket  - 108 bay + 8 eşleşme                  │
│                                                             │
│ [Seçimi Onayla]                                             │
└─────────────────────────────────────────────────────────────┘
```

### 6. Kombinasyon Hesaplama Algoritması

```
FUNCTION calculateCombinations(totalParticipants, cutoffRank, allowByes):
  upperParticipants = participants.take(cutoffRank)
  lowerParticipants = participants.skip(cutoffRank)
  
  combinations = []
  
  FOR each bracketSize in [8, 16, 32, 64, 128]:
    IF allowByes:
      IF upperParticipants.length <= bracketSize:
        byeCount = bracketSize - upperParticipants.length
        competingCount = upperParticipants.length
        eliminatedCount = 0
      ELSE:
        byeCount = 0
        competingCount = bracketSize
        eliminatedCount = upperParticipants.length - bracketSize
    ELSE:
      IF upperParticipants.length == bracketSize:
        byeCount = 0
        competingCount = bracketSize
        eliminatedCount = 0
      ELSE IF upperParticipants.length > bracketSize:
        byeCount = 0
        competingCount = bracketSize
        eliminatedCount = upperParticipants.length - bracketSize
      ELSE:
        // Mümkün değil
        continue
    
    combinations.add({
      bracketSize: bracketSize,
      byeCount: byeCount,
      competingCount: competingCount,
      eliminatedCount: eliminatedCount,
      possible: true
    })
  
  RETURN combinations
```

### 7. Kombinasyon Öneri Sistemi

#### Akıllı Öneri Algoritması
```
FUNCTION suggestOptimalCombination(combinations):
  // En optimal kombinasyonu öner
  optimal = null
  
  FOR each combination in combinations:
    score = 0
    
    // Bay geçme oranı puanı (25-50% arası optimal)
    byePercentage = (combination.byeCount / combination.bracketSize) * 100
    IF byePercentage >= 25 AND byePercentage <= 50:
      score += 10
    ELSE IF byePercentage < 25:
      score += 5
    ELSE:
      score += 2
    
    // Bracket boyutu puanı (16-32 arası optimal)
    IF combination.bracketSize >= 16 AND combination.bracketSize <= 32:
      score += 10
    ELSE IF combination.bracketSize == 8:
      score += 5
    ELSE:
      score += 3
    
    // Elenen katılımcı sayısı puanı (az elenen daha iyi)
    IF combination.eliminatedCount == 0:
      score += 15
    ELSE IF combination.eliminatedCount <= 4:
      score += 10
    ELSE:
      score += 5
    
    IF score > optimal.score:
      optimal = combination
  
  RETURN optimal
```

Bu sistem, kullanıcıya kesme sınırı belirleme ve bay geçme seçimi yapma imkanı verir, ardından tüm olası kombinasyonları göstererek en uygun seçimi yapmasını sağlar.

## 📊 Veri Yapısı

### 1. Eleme Maçı Tablosu
```
elimination_matches:
  - match_id: UUID
  - competition_id: UUID
  - classification_id: UUID
  - round_id: UUID
  - participant_1_id: UUID
  - participant_2_id: UUID
  - winner_id: UUID
  - bow_type: VARCHAR (recurve/barebow/compound)
  - match_format: VARCHAR (set_based/total_score)
  - status: VARCHAR (pending/active/completed)
  - match_data: JSONB (seri skorları, beraberlik atışları)
```

### 2. Maç Verisi JSON Yapısı

#### Recurve/Barebow Format
```json
{
  "format": "set_based",
  "sets": [
    {
      "set_number": 1,
      "participant_1_score": 28,
      "participant_2_score": 26,
      "participant_1_points": 2,
      "participant_2_points": 0
    }
  ],
  "total_points": {
    "participant_1": 6,
    "participant_2": 2
  },
  "tie_break": {
    "required": false,
    "participant_1_score": null,
    "participant_2_score": null,
    "winner": null
  }
}
```

#### Compound Format
```json
{
  "format": "total_score",
  "sets": [
    {
      "set_number": 1,
      "participant_1_score": 29,
      "participant_2_score": 28
    }
  ],
  "total_scores": {
    "participant_1": 146,
    "participant_2": 144
  },
  "tie_break": {
    "required": false,
    "participant_1_score": null,
    "participant_2_score": null,
    "winner": null
  }
}
```

## 🎯 UI/UX Gereksinimleri

### 1. Maç Skor Girişi
- Yay türüne göre farklı arayüz
- Seri bazlı skor girişi (Recurve/Barebow)
- Toplam skor girişi (Compound)
- Beraberlik atışı arayüzü
- Real-time puan hesaplama

### 2. Bracket Görünümü
- Yay türü işaretleme
- Maç formatı gösterimi
- Beraberlik durumu işaretleme
- İlerleme takibi

### 3. Sonuç Görüntüleme
- Detaylı maç sonuçları
- Seri bazlı skorlar
- Beraberlik atışı sonuçları
- İstatistikler

## 🔧 Teknik Gereksinimler

### 1. Skor Hesaplama Algoritmaları
- Recurve/Barebow: Set bazlı puanlama
- Compound: Toplam skor hesaplama
- Beraberlik durumu tespiti
- Merkeze yakınlık hesaplama

### 2. Veri Validasyonu
- Skor aralığı kontrolü (0-30 per set)
- Beraberlik atışı zorunluluğu
- Maç tamamlama kontrolü
- Veri tutarlılığı

### 3. Performans Optimizasyonu
- Real-time skor güncelleme
- Caching ile hızlı hesaplama
- Offline destek
- Sync mekanizması

## 🚀 Gelecek Geliştirmeler

### 1. Takım Eleme Sistemi
- Takım bazlı eleme formatları
- Karma takım eleme sistemi
- Takım skor hesaplama

### 2. Gelişmiş Özellikler
- Video analiz entegrasyonu
- İstatistiksel analiz
- Performans takibi
- Raporlama sistemi

### 3. Mobil Optimizasyon
- Touch-friendly arayüz
- Offline çalışma
- Push bildirimleri
- Senkronizasyon

---

*Bu dokümantasyon, eleme sisteminin temel mantığını açıklar ve gelecekteki geliştirmeler için rehber niteliğindedir.*
