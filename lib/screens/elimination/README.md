# 🏆 Eleme Sistemi (Elimination System)

Bu dizin, Hit Score uygulamasının eleme sistemi UI ekranlarını içerir.

## 📁 Dosya Yapısı

### Organizatör Ekranları
- **elimination_settings_screen.dart**: Eleme sistemi ayarları (yay türü, kesme sınırı, bay geçme, bracket boyutu)
- **elimination_bracket_screen.dart**: Bracket yönetimi ve maç görüntüleme
- **match_scoring_screen.dart**: Maç skor girişi (Recurve/Barebow/Compound formatları)

### Katılımcı Ekranları
- **elimination_status_screen.dart**: Katılımcının eleme durumu, maç geçmişi ve istatistikleri

## 🎯 Navigasyon Akışı

### Organizatör Tarafı
```
Home Screen
  → My Organized Competitions
    → Competition Participants Screen
      → Elimination Settings Screen
        → Elimination Bracket Screen
          → Match Scoring Screen
```

### Katılımcı Tarafı
```
Home Screen
  → Active Competitions
    → Competition Details Screen
      → Elimination Status Screen
```

## 📋 Özellikler

### Elimination Settings Screen
- ✅ Yay türü seçimi (Recurve, Barebow, Compound)
- ✅ Kesme sınırı ayarlama (slider ile)
- ✅ Bay geçme ayarları (aktif/pasif)
- ✅ Bay geçme stratejisi seçimi
- ✅ Bracket boyutu seçimi (8, 16, 32, 64, 128)
- ✅ Kombinasyon önizleme
- ✅ Responsive tasarım

### Elimination Bracket Screen
- ✅ Bracket ağacı görünümü (placeholder)
- ✅ Tur seçici
- ✅ Maç listesi ve durumları
- ✅ Aktif maç sayacı
- ✅ Maç skor girişine yönlendirme
- ✅ Responsive tasarım

### Match Scoring Screen
- ✅ Yay türüne göre farklı skor sistemi
- ✅ Set bazlı skor girişi
- ✅ Recurve/Barebow: Set puanlama sistemi (2-1-0)
- ✅ Compound: Toplam skor sistemi
- ✅ Set geçmişi görüntüleme
- ✅ Beraberlik atışı desteği
- ✅ Maç tamamlama
- ✅ Responsive tasarım

### Elimination Status Screen
- ✅ Durum göstergesi (Aktif/Elendi/Şampiyon)
- ✅ Mevcut pozisyon bilgisi
- ✅ Bay geçme durumu
- ✅ Sonraki maç bilgisi
- ✅ Maç geçmişi
- ✅ İstatistikler (oynanan, galibiyet, mağlubiyet)
- ✅ Responsive tasarım

## 🌍 Çok Dilli Destek (i18n)

Tüm string'ler `AppLocalizations` kullanılarak tanımlanmıştır:
- İngilizce: `lib/l10n/app_en.arb`
- Türkçe: `lib/l10n/app_tr.arb`

## 🎨 UI/UX Özellikleri

### Responsive Tasarım
- ✅ Text scaler clamp (max 1.3)
- ✅ SafeArea kullanımı
- ✅ LayoutBuilder ile dinamik boyutlandırma
- ✅ Overflow koruması

### Tasarım Standartları
- ✅ Material Design 3
- ✅ Theme-aware renkler
- ✅ Consistent spacing
- ✅ Icon kullanımı
- ✅ Card-based layout

### Kullanıcı Deneyimi
- ✅ Loading states
- ✅ Empty states
- ✅ Error handling
- ✅ Success feedback
- ✅ Pull-to-refresh
- ✅ Input validation

## 🚀 Gelecek Geliştirmeler

### Backend Entegrasyonu
- [ ] Supabase servis entegrasyonu
- [ ] Real-time güncellemeler
- [ ] Veri senkronizasyonu

### Bracket Görselleştirme
- [ ] İnteraktif bracket ağacı
- [ ] Zoom/pan özellikleri
- [ ] SVG/Canvas rendering

### Gelişmiş Özellikler
- [ ] Push bildirimleri
- [ ] PDF export
- [ ] Canlı skor güncelleme
- [ ] Video analiz entegrasyonu

## 📝 Notlar

- Tüm ekranlar şu anda **UI-only** (backend entegrasyonu yok)
- Simüle edilmiş veriler kullanılıyor
- Provider/State management implementasyonu bekleniyor
- ELEMINATION_SYSTEM_LOGIC.md dosyasına göre tasarlandı

## 🔗 İlgili Dosyalar

- **Logic Dokümantasyonu**: `/ELEMINATION_SYSTEM_LOGIC.md`
- **Organizatör Ekranlar**: `/lib/screens/organized/`
- **Katılımcı Ekranlar**: `/lib/screens/`
- **Localization**: `/lib/l10n/`

