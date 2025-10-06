# 🎯 Hit Score - Yarışma Yönetim Sistemi Logic Dokümantasyonu

## 📋 Genel Sistem Mantığı

Bu dokümantasyon, okçuluk yarışma yönetim sisteminin iş mantığını, veri akışlarını ve sistem kararlarını detaylı şekilde açıklamaktadır. Sistem, tüm kullanıcıların (admin, antrenör, sporcu) yarışmalara katılabileceği evrensel bir katılım modeli üzerine kuruludur.

## 👥 Kullanıcı Rolleri ve Yetki Mantığı

### Rol Tanımları
- **Admin**: Sistem yöneticisi, tüm yetkilere sahip (Emre)
- **Antrenör**: Yarışma oluşturabilir, sporcularını yönetebilir, kendi yarışmalarına katılabilir
- **Sporcu**: Yarışma oluşturabilir, Yarışmalara katılabilir, skor girebilir, kendi performansını takip edebilir

### Yetki Matrisi Mantığı
Sistem, rol bazlı erişim kontrolü (RBAC) kullanır ancak katılım konusunda esnek bir yaklaşım benimser:

**Yarışma Oluşturma**: Herkes yarışma oluşturabilir
**Yarışma Düzenleme**: Sadece oluşturan kişi ve adminler düzenleyebilir
**Katılım**: Tüm kullanıcılar yarışmalara katılabilir (rol fark etmeksizin)
**Skor Girişi**: Sadece kendi skorunu girebilir (kendi katılımı olan yarışmalarda)

## 🔄 Ana İş Akışları ve Logic

### 1️⃣ YARIŞMA OLUŞTURMA MANTIĞI

#### Temel Bilgi Doğrulama
- **Yarışma Adı**: Minimum 3 karakter, benzersizlik kontrolü
- **Açıklama**: Maksimum 500 karakter, opsiyonel
- **Görünür ID**: Otomatik oluşturma (İsim ilk 3 harf + sıra numarası)

#### Tarih Validasyon Logic
Sistem, tarih sıralamasını şu mantıkla kontrol eder:
```
Kayıt Başlangıç < Kayıt Bitiş < Yarışma Başlangıç < Yarışma Bitiş
Kayıt Başlangıç >= Şu anki tarih
```

#### Klasman Oluşturma Mantığı
Her klasman için gerekli alanlar:
- **Klasman Adı**: Benzersiz olmalı (aynı yarışma içinde) (classification_id ler olcak)
- **Cinsiyet**: Erkek/Kadın/Karışık seçenekleri
- **Yaş Kategorisi**: U15, U18, U21, Yetişkin, Master
- **Yay Tipi**: Recurve, Compound, Barebow, Traditional
- **Mesafe**: 18m, 30m, 70m gibi standart mesafeler
- **Round Tipi**: 30 ok, 60 ok, 720 round gibi formatlar
- **Katılımcı Limiti**: Opsiyonel, maksimum kapasite kontrolü

#### Yarışma Formatı Seçimi
**Sadece Sıralama Modu**:
- Klasik sıralama sistemi
- Skorlar toplanır, sıralama oluşturulur
- Madalya dağıtımı yapılır

**Eleme + Sıralama Modu**:
- Önce sıralama turu
- Sonra eleme turu (bracket sistemi)
- Eleme tarihi, sıralama bitiminden sonra olmalı
- Bracket boyutu otomatik hesaplanır (8, 16, 32, 64)

#### Takım Kategorileri Mantığı
**Bireysel**: Her sporcu kendi başına yarışır
**Takım**: Aynı cinsiyetten 3 sporcu
**Mix Takım**: 1 erkek + 1 kadın sporcu

### 2️⃣ KATILIM SİSTEMİ MANTIĞI

#### Evrensel Katılım Modeli
Sistem, tüm kullanıcıların yarışmalara katılabileceği esnek bir yapı kullanır:

**Kendi Kendine Kayıt**:
- Sporcu, uygun klasmanları görür
- Profil kontrolü yapılır (yaş, cinsiyet, kulüp bilgisi)
- Eksik profil varsa tamamlama yönlendirmesi
- İstek "pending" durumunda bekler

**Antrenör Tarafından Kayıt**:
- Antrenör, kendi sporcularını toplu kaydedebilir
- Otomatik onay (status: approved)
- Sporculara bildirim gönderilir

**Yarışma Sahibi Manuel Ekleme**:
- Yarışma sahibi, herhangi bir kullanıcıyı ekleyebilir
- Otomatik onay (status: approved)
- Kullanıcıya bildirim gönderilir

#### Profil Doğrulama Logic
Katılım öncesi kontrol edilen alanlar:
- Profil tamamlanmış mı?
- Yaş kategorisi uygun mu?
- Cinsiyet kategorisi uygun mu?
- Kulüp bilgisi mevcut mu?
- Daha önce aynı yarışmaya kayıtlı mı?

### 3️⃣ SKOR GİRİŞİ MANTIĞI

#### Skor Girişi Yetkilendirmesi
- Sadece kendi katılımı olan yarışmalarda skor girebilir
- Skor girişi süresi: Yarışma başlangıcı ile bitişi arası
- Skor kesinleştikten sonra değiştirilemez

#### Skor Hesaplama Logic
**Her Ok İçin**:
- 0-10 arası değer veya X (merkez)
- Set/End bazlı giriş
- Ara toplam otomatik hesaplama

**Toplam Skor Hesaplama**:
- Tüm okların toplamı
- 10'luk sayısı (10 puanlık oklar)
- X sayısı (merkez oklar)

#### Realtime Güncelleme Mantığı
- Skor girildiğinde Supabase Realtime Subscription üzerinden güncelleme
- Sadece değişen klasman için broadcast
- Debouncing (500ms gecikme) ile gereksiz istekleri önleme
- Sadece "skor kesinleştiğinde" diğer kullanıcılara bildirim

### 4️⃣ SIRALAMA SİSTEMİ MANTIĞI

#### Sıralama Kriterleri (Öncelik Sırası)
1. **Toplam Skor**: Yüksekten düşüğe
2. **X Sayısı**: Hala eşitlik varsa ( eğer outdoor yarışma ise , çünkü indoor da X yok)
3. **10'luk Sayısı**: Eşitlik durumunda
4. **Shoot-off**: Manuel atış yarışması gerekir

#### Sıralama Güncelleme Logic
- Yeni skor girildiğinde sıralama yeniden hesaplanır
- Sadece etkilenen sporcuların sırası değişir
- Animasyonlu geçiş (yukarı/aşağı hareket)
- Üst 3'e giren/çıkan sporculara özel bildirim

#### Renk Kodlama Sistemi
- 🥇 1. sıra: Altın
- 🥈 2. sıra: Gümüş
- 🥉 3. sıra: Bronz
- Elemeye kalan sporcular: Yeşil highlight

### 5️⃣ TAKIM SİSTEMİ MANTIĞI

#### Otomatik Takım Oluşturma
Sistem, yarışma bittiğinde otomatik olarak takımları oluşturur:

**Takım (Team) Logic**:
```
FOR her kulüp:
  - Aynı klasmandaki en iyi 3 sporcuyu al
  - Eğer 3 sporcu varsa:
    - Takım skoru = 3 sporcunun toplam skoru
    - Takımı kaydet
  - Eğer 3 sporcu yoksa:
    - Takım oluşturma
```

**Mix Takım Logic**:
```
FOR her kulüp:
  - En iyi erkek sporcuyu al
  - En iyi kadın sporcuyu al
  - Eğer her ikisi de varsa:
    - Mix takım skoru = 2 sporcunun toplam skoru
    - Mix takımı kaydet
  - Eğer ikisi de yoksa:
    - Mix takım oluşturma
```

#### Takım Sıralaması
- Kulüp bazlı gruplandırma
- Takım skoru = üye skorlarının toplamı
- Bireysel sıralama ile aynı kriterler

### 6️⃣ ELEMİNASYON SİSTEMİ MANTIĞI

#### Bracket Oluşturma Logic
**Bracket Boyutu Belirleme**:
- Katılımcı sayısına göre: 8, 16, 32, 64
- Eğer tam değilse, bazı sporcular "bye" (geçer) alır

**Eşleşme Sistemi**:
- 1. sıra vs Son sıra
- 2. sıra vs Son-1 sıra
- 3. sıra vs Son-2 sıra
- ... (merkezden dışa doğru)

#### Bracket Aşamaları
- 1/32, 1/16, 1/8, Çeyrek Final, Yarı Final, Final
- Her aşamada kazanan bir sonraki tura geçer
- Kaybeden "Elendi" statüsüne alınır

#### Eleme Maçı Skoru
- Set bazlı puan sistemi (klasik ve makaralı sistemi farklı)
- Kazanan otomatik bir sonraki tura aktarılır
- Bracket otomatik güncellenir

### 7️⃣ YARIŞMA DÜZENLEME MANTIĞI

#### Düzenlenebilir Alanlar
- Yarışma adı ve açıklama
- Tarihler (sadece henüz başlamamış yarışmalarda)
- Klasmanlar (ekle/çıkar/düzenle)
- Katılımcı limitleri

#### Düzenlenemez Alanlar
- Yarışma ID (sabit kalmalı)
- Skor sistemi (değiştirilirse tüm skorlar geçersiz olur)
- Eliminasyon formatı (değiştirilirse tüm braketler sıfırlanır)

#### Güvenlik Kontrolleri
- Sadece yarışma sahibi ve adminler düzenleyebilir
- Yarışma başladıktan sonra kritik alanlar kilitlenir
- Değişiklik geçmişi tutulur

## 🔔 Bildirim Sistemi Mantığı

### Bildirim Tetikleyicileri
**Yarışma Oluşturuldu**: Oluşturan kişiye onay
**Katılım İsteği**: Yarışma sahibine bildirim
**İstek Onay/Red**: İsteği gönderen sporcuya bildirim
**Yarışma Başlıyor**: 24 saat önce tüm katılımcılara
**Sıralama Değişti**: Etkilenen sporculara (üst 3'e giren/çıkan)
**Eleme Maçı**: Maça katılacak sporculara
**Yarışma Sonuçlandı**: Tüm katılımcılara

### Bildirim Öncelik Sistemi
- **Kritik**: Yarışma iptal, tarih değişikliği
- **Önemli**: Katılım onay/red, sıralama değişikliği
- **Bilgilendirici**: Genel duyurular, hatırlatmalar

## 📊 Veri Yapısı Mantığı

### Competition Model
- **competition_id**: Benzersiz UUID
- **competition_visible_id**: Kullanıcı dostu ID (ANK001)
- **status**: draft, registration_open, ongoing, completed
- **competition_types**: Bireysel, takım, mix takım kombinasyonları
- **classifications**: Klasman listesi (array)
- **temporal_fields**: Tarih alanları (registration, competition, elimination)

### Classification Model
- **classification_id**: Benzersiz UUID
- **competition_id**: Hangi yarışmaya ait
- **constraints**: Cinsiyet, yaş, yay tipi kısıtlamaları
- **participant_limit**: Maksimum katılımcı sayısı
- **scoring_rules**: Skorlama kuralları

### Participant Model
- **participant_id**: Benzersiz UUID
- **user_id**: Hangi kullanıcı
- **competition_id**: Hangi yarışma
- **classification_id**: Hangi klasman
- **status**: pending, approved, rejected
- **registered_by**: Kim tarafından kaydedildi (self/coach/admin)

### Score Model
- **score_id**: Benzersiz UUID
- **participant_id**: Hangi katılımcı
- **ends**: Set/End bazlı skorlar (array)
- **total_score**: Toplam skor
- **tens_count**: 10'luk sayısı
- **x_count**: X sayısı
- **submitted_at**: Kesinleşme tarihi

## 🚀 Performans Optimizasyonu Mantığı

### Realtime İletişim
- **Selective Listening**: Sadece değişen dokümanlar dinlenir
- **Debouncing**: 500ms gecikme ile gereksiz istekleri önleme
- **Batch Updates**: Toplu güncellemeler için batch işlemler

### Veri Yönetimi
- **Pagination**: Büyük listeler için sayfalama
- **Lazy Loading**: Bracket oluştururken tembel yükleme
- **Caching**: Offline-first yaklaşımı
- **Indexing**: Sık sorgulanan alanlar için indeksler

### Güvenlik Mantığı
- **Row Level Security**: Veritabanı seviyesinde yetki kontrolü
- **Input Validation**: Tüm girdiler doğrulanır
- **Rate Limiting**: API istekleri sınırlandırılır
- **Audit Trail**: Tüm değişiklikler loglanır

## 🎯 Sistem Karar Mantığı

### Yarışma Durumu Geçişleri
```
draft → registration_open (kayıt tarihi geldiğinde)
registration_open → ongoing (yarışma tarihi geldiğinde)
ongoing → completed (yarışma bitiş tarihi geldiğinde)
```

### Katılım Durumu Geçişleri
```
pending → approved (yarışma sahibi onayladığında)
pending → rejected (yarışma sahibi reddettiğinde)
approved → active (yarışma başladığında)
active → completed (skor girişi tamamlandığında)
```

### Skor Durumu Geçişleri
```
draft → submitted (sporcu skoru kesinleştirdiğinde)
submitted → final (yarışma bittiğinde)
```

Bu mantık dokümantasyonu, sistemin tüm karar noktalarını ve iş akışlarını kapsamlı şekilde açıklamaktadır. Her bir logic, gerçek dünya senaryoları düşünülerek tasarlanmış ve sistemin tutarlılığını sağlayacak şekilde yapılandırılmıştır.
