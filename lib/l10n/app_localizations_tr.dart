// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'HitScore';

  @override
  String get loginTitle => 'Giriş Yap';

  @override
  String get emailLabel => 'E-posta';

  @override
  String get passwordLabel => 'Şifre';

  @override
  String get loginButton => 'Giriş Yap';

  @override
  String get loginWithGoogle => 'Google ile Giriş Yap';

  @override
  String get loginErrorGoogle => 'Google ile giriş başarısız.';

  @override
  String get signInWithApple => 'Apple ile Giriş Yap';

  @override
  String get profileTitle => 'Profil';

  @override
  String get refresh => 'Yenile';

  @override
  String get errorGeneric => 'Bir hata oluştu.';

  @override
  String get networkError => 'Ağ sorunu. Lütfen bağlantınızı kontrol edin.';

  @override
  String get setupProfile => 'Profil Oluştur';

  @override
  String get setupProfileDescription => 'Profil bulunamadı. Lütfen profilinizi tamamlayın.';

  @override
  String get exitSetupConfirm => 'Profil kurulumundan çıkmak istediğinize emin misiniz?';

  @override
  String get back => 'Geri';

  @override
  String get role => 'Rol';

  @override
  String get gender => 'Cinsiyet';

  @override
  String get genderRequired => 'Cinsiyet zorunludur';

  @override
  String get roleRequired => 'Rol zorunludur';

  @override
  String get roleWarningTitle => 'Rol Seçimi Bilgisi';

  @override
  String get roleWarningMessage => 'Rolünüzü hesabınızı silmeden değiştirmeniz mümkün değildir. Rollerin farklı işlevleri Hit Archery uygulamasında vardır, bu uygulamada her rolün işlevi aynıdır.';

  @override
  String get understood => 'Anladım';

  @override
  String get birthDateLabel => 'Doğum tarihi';

  @override
  String get birthDateRequired => 'Doğum tarihi zorunludur';

  @override
  String get phoneNumber => 'Telefon numarası';

  @override
  String get selectCity => 'Şehir Seç';

  @override
  String get homeTab => 'Ana Sayfa';

  @override
  String get profileTab => 'Profil';

  @override
  String get clubLabel => 'Kulüp';

  @override
  String get profileId => 'Profil ID';

  @override
  String get contactInfo => 'İletişim Bilgileri';

  @override
  String get addressSimple => 'Adres';

  @override
  String get phoneNumberSimple => 'Telefon';

  @override
  String get countryLabel => 'Ülke';

  @override
  String get cityLabel => 'Şehir';

  @override
  String get clubIdLabel => 'Kulüp ID';

  @override
  String get editProfile => 'Profili Düzenle';

  @override
  String get save => 'Kaydet';

  @override
  String get cancel => 'Vazgeç';

  @override
  String get firstName => 'Ad';

  @override
  String get firstNameRequired => 'Ad zorunludur';

  @override
  String get lastName => 'Soyad';

  @override
  String get lastNameRequired => 'Soyad zorunludur';

  @override
  String get birthDate => 'Doğum Tarihi';

  @override
  String get dateNotSelected => 'Seçilmedi';

  @override
  String get male => 'Erkek';

  @override
  String get female => 'Kadın';

  @override
  String get personalInfo => 'Kişisel Bilgiler';

  @override
  String get clubInfo => 'Kulüp Bilgileri';

  @override
  String get selectCountry => 'Ülke Seç';

  @override
  String get selectClub => 'Kulüp Seç';

  @override
  String get allCountries => 'Tüm Ülkeler';

  @override
  String get allCities => 'Tüm Şehirler';

  @override
  String get individualClub => 'Bireysel (Kulüp Yok)';

  @override
  String get removeClub => 'Kulübü Kaldır';

  @override
  String get roleChangeNotAllowed => 'Rol kurulumdan sonra değiştirilemez';

  @override
  String get changePhoto => 'Fotoğrafı değiştir';

  @override
  String get removePhoto => 'Fotoğrafı kaldır';

  @override
  String get emailVerificationRequiredTitle => 'E-posta doğrulaması gerekli';

  @override
  String get emailVerificationLoginContent => 'Lütfen giriş yapmadan önce e-postanızı doğrulayın.';

  @override
  String get emailVerificationRequiredOk => 'Tamam';

  @override
  String get loginSuccessRedirectingShort => 'Giriş başarılı. Yönlendiriliyor...';

  @override
  String get loginErrorInvalidCredentials => 'E-posta veya şifre hatalı.';

  @override
  String get loginErrorGeneric => 'Bir hata oluştu. Lütfen tekrar deneyin.';

  @override
  String welcomeWithName(String name) {
    return 'Hoş geldin $name';
  }

  @override
  String get createCompetitionTitle => 'Yarışma Oluştur';

  @override
  String get competitionGeneralInfo => 'Genel Bilgiler';

  @override
  String get competitionGeneralInfoDesc => 'Aşağıya yarışma bilgilerini girin.';

  @override
  String get competitionNameLabel => 'Yarışma adı';

  @override
  String get competitionDescriptionLabel => 'Açıklama';

  @override
  String get competitionDuration => 'Yarışma Süresi';

  @override
  String get competitionDurationDesc => 'Başlangıç ve bitiş tarihlerini seçin.';

  @override
  String get startDate => 'Başlangıç tarihi';

  @override
  String get endDate => 'Bitiş tarihi';

  @override
  String get competitionDateHint => 'GG.AA.YYYY';

  @override
  String get registrationDatesLabel => 'Kayıt Tarihleri';

  @override
  String get registrationDatesOptional => 'Opsiyonel kayıt başlangıç ve bitiş zamanları.';

  @override
  String get registrationStartLabel => 'Kayıt başlangıcı';

  @override
  String get registrationEndLabel => 'Kayıt bitişi';

  @override
  String get savingInProgress => 'Kaydediliyor...';

  @override
  String get saveAndContinue => 'Kaydet ve Devam Et';

  @override
  String get competitionNameRequired => 'Yarışma adı zorunludur';

  @override
  String get startDateRequired => 'Başlangıç tarihi zorunludur';

  @override
  String get endDateRequired => 'Bitiş tarihi zorunludur';

  @override
  String get startDateCannotBeAfterEndDate => 'Başlangıç tarihi bitişten sonra olamaz';

  @override
  String get competitionSavedSuccess => 'Yarışma başarıyla oluşturuldu!';

  @override
  String get competitionLoadError => 'Yarışmalar yüklenemedi';

  @override
  String get classifications => 'Klasmanlar';

  @override
  String get addClassification => 'Klasman Ekle';

  @override
  String get noClassificationsYet => 'Henüz klasman eklenmedi';

  @override
  String get noClassificationsDesc => 'Devam etmek için en az bir klasman ekleyin.';

  @override
  String get delete => 'Sil';

  @override
  String get classificationAtLeastOneRequired => 'Lütfen en az bir klasman ekleyin';

  @override
  String get completeCompetition => 'Yarışmayı Tamamla';

  @override
  String get savingGeneric => 'Kaydediliyor...';

  @override
  String get untitledCompetition => 'İsimsiz Yarışma';

  @override
  String get dateLabelGeneric => 'Tarih';

  @override
  String get dateNotProvided => 'Tarih belirtilmemiş';

  @override
  String get invalidDate => 'Geçersiz tarih';

  @override
  String get enterValidDistance => 'Geçerli bir mesafe girin';

  @override
  String get fillAllFields => 'Lütfen tüm alanları doldurun';

  @override
  String get classificationNameLabel => 'Klasman adı';

  @override
  String get ageGroupLabel => 'Yaş grubu';

  @override
  String get bowTypeLabel => 'Yay tipi';

  @override
  String get environmentLabel => 'Ortam';

  @override
  String get distanceMetersLabel => 'Mesafe (metre)';

  @override
  String get customDistance => 'Özel Mesafe';

  @override
  String get customDistanceMeters => 'Özel mesafe (metre)';

  @override
  String get editClassificationTitle => 'Klasman Düzenle';

  @override
  String get addClassificationTitle => 'Klasman Ekle';

  @override
  String get myCompetitionsTitle => 'Yarışmalarım';

  @override
  String get myCompetitionsSubtitle => 'Yarışmalarınızı görüntüleyin ve yönetin.';

  @override
  String get myCompetitionsEmptyTitle => 'Henüz yarışma yok';

  @override
  String get myCompetitionsEmptyDesc => 'Başlamak için ilk yarışmanızı oluşturun.';

  @override
  String get competitionStatusDraft => 'Taslak';

  @override
  String get competitionStatusActive => 'Aktif';

  @override
  String get competitionStatusCompleted => 'Tamamlandı';

  @override
  String get competitionStatusCancelled => 'İptal Edildi';

  @override
  String get competitionCreatedOn => 'Oluşturulma tarihi';

  @override
  String get competitionStartsOn => 'Başlangıç tarihi';

  @override
  String get competitionEndsOn => 'Bitiş tarihi';

  @override
  String get registrationStartsOn => 'Kayıt başlangıcı';

  @override
  String get registrationEndsOn => 'Kayıt bitişi';

  @override
  String get competitionParticipants => 'Katılımcılar';

  @override
  String get competitionViewDetails => 'Detayları Görüntüle';

  @override
  String get competitionEdit => 'Düzenle';

  @override
  String get competitionDelete => 'Sil';

  @override
  String get competitionDeleteConfirm => 'Bu yarışmayı silmek istediğinizden emin misiniz?';

  @override
  String get competitionDeleteSuccess => 'Yarışma başarıyla silindi';

  @override
  String get editCompetitionTitle => 'Yarışmayı Düzenle';

  @override
  String get competitionUpdateSuccess => 'Yarışma başarıyla güncellendi';

  @override
  String get competitionUpdateError => 'Yarışma güncellenemedi';

  @override
  String get classificationDeleteConfirm => 'Bu klasmanı silmek istediğinizden emin misiniz?';

  @override
  String get classificationDeleteTitle => 'Klasmanı Sil';

  @override
  String get competitionCreatedSuccess => 'Yarışma başarıyla oluşturuldu!';

  @override
  String get competitionDateLabel => 'Tarih';

  @override
  String get competitionDateNotProvided => 'Tarih belirtilmemiş';

  @override
  String get competitionInvalidDate => 'Geçersiz tarih';

  @override
  String get ageGroup9_10 => '9-10 Yaş';

  @override
  String get ageGroup11_12 => '11-12 Yaş';

  @override
  String get ageGroup13_14 => '13-14 Yaş';

  @override
  String get ageGroupU18 => 'U18 (15-16-17)';

  @override
  String get ageGroupU21 => 'U21 (18-19-20)';

  @override
  String get ageGroupSenior => 'Büyükler';

  @override
  String get bowTypeRecurve => 'Klasik';

  @override
  String get bowTypeCompound => 'Makaralı';

  @override
  String get bowTypeBarebow => 'Barebow';

  @override
  String get environmentIndoor => 'Salon';

  @override
  String get environmentOutdoor => 'Açık Hava';

  @override
  String get genderMale => 'Erkek';

  @override
  String get genderFemale => 'Kadın';

  @override
  String get genderMixed => 'Karma';

  @override
  String get genderLabel => 'Cinsiyet';

  @override
  String get unsavedChangesTitle => 'Kaydedilmemiş Değişiklikler';

  @override
  String get unsavedChangesMessage => 'Değişiklikler kaydedilmeyecek. Emin misiniz?';

  @override
  String get exit => 'Çık';

  @override
  String get comingSoon => 'Yakında';

  @override
  String get signOut => 'Çıkış Yap';

  @override
  String get signOutConfirm => 'Çıkış yapmak istediğinizden emin misiniz?';

  @override
  String get profileUpdated => 'Profil başarıyla kaydedildi';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get languageSettings => 'Dil';

  @override
  String get themeSettings => 'Tema';

  @override
  String get lightTheme => 'Açık';

  @override
  String get darkTheme => 'Koyu';

  @override
  String get systemTheme => 'Sistem';

  @override
  String competitionClassificationsCount(int count) {
    return 'Klasmanlar: $count';
  }

  @override
  String get competitionVisibleIdLabel => 'Yarışma ID';

  @override
  String get competitionVisibleIdCopyTooltip => 'ID\'yi kopyala';

  @override
  String get competitionVisibleIdCopied => 'Yarışma ID kopyalandı';

  @override
  String get participantsTitle => 'Katılımcılar';

  @override
  String get participantsLoadError => 'Katılımcılar yüklenemedi';

  @override
  String get participantsEmptyTitle => 'Henüz katılımcı yok';

  @override
  String get participantsEmptyDesc => 'Bu yarışmaya henüz kimse kayıt olmadı.';

  @override
  String get participantAthleteId => 'Kullanıcı ID';

  @override
  String get participantGender => 'Cinsiyet';

  @override
  String get participantAgeGroup => 'Yaş grubu';

  @override
  String get participantEquipment => 'Ekipman';

  @override
  String get pendingStatus => 'Beklemede';

  @override
  String get acceptedStatus => 'Kabul Edildi';

  @override
  String get cancelledStatus => 'Reddedildi';

  @override
  String get acceptRequest => 'Kabul Et';

  @override
  String get rejectRequest => 'Reddet';

  @override
  String get changeStatus => 'Durumu Değiştir';

  @override
  String get acceptRequestConfirm => 'Bu katılımcıyı kabul ediyor musunuz?';

  @override
  String get rejectRequestConfirm => 'Bu katılımcıyı reddediyor musunuz?';

  @override
  String get changeToAcceptedConfirm => 'Durumu kabul edildi olarak değiştir?';

  @override
  String get changeToRejectedConfirm => 'Durumu reddedildi olarak değiştir?';

  @override
  String get requestAccepted => 'İstek kabul edildi';

  @override
  String get requestRejected => 'İstek reddedildi';

  @override
  String get statusChanged => 'Durum değiştirildi';

  @override
  String get activeCompetitionsTitle => 'Aktif Yarışmalar';

  @override
  String get activeCompetitionsSubtitle => 'Uygun yarışmaları incele ve katıl.';

  @override
  String get activeCompetitionsEmptyTitle => 'Aktif yarışma yok';

  @override
  String get activeCompetitionsEmptyDesc => 'Şu anda kayıta açık yarışma bulunmuyor.';

  @override
  String get competitionJoin => 'Katıl';

  @override
  String get competitionJoined => 'Yarışmaya katıldınız';

  @override
  String get competitionJoinError => 'Yarışmaya katılım başarısız';

  @override
  String get athleteProfileRequired => 'Sporcu profili gerekli. Lütfen önce profilinizi tamamlayın.';

  @override
  String get athlete => 'Sporcu';

  @override
  String get coach => 'Antrenör';

  @override
  String get registrationOpen => 'Kayıt açık';

  @override
  String get registrationClosed => 'Kayıt kapalı';

  @override
  String get registrationAllowedLabel => 'Kayda izin ver';

  @override
  String get registrationAllowedDesc => 'Açık olduğunda kullanıcılar katılım isteği gönderebilir. Bunu daha sonra değiştirebilirsiniz.';

  @override
  String get scoreAllowedLabel => 'Skor girişine izin ver';

  @override
  String get scoreAllowedDesc => 'Katılımcılar skor girişi yapabilir. Yarışma başlamadan önce açın; bunu daha sonra değiştirebilirsiniz.';

  @override
  String get requestSent => 'İstek gönderildi';

  @override
  String get pending => 'Beklemede';

  @override
  String get cancelRequest => 'İsteği iptal et';

  @override
  String get cancelRequestConfirm => 'Katılım isteğini iptal etmek istiyor musun?';

  @override
  String get requestCancelled => 'İstek iptal edildi';

  @override
  String get pendingClassificationLabel => 'İstenen klasman';

  @override
  String get selectClassificationTitle => 'Klasman seç';

  @override
  String get selectClassificationInstruction => 'Katılmak için klasmanını seç';

  @override
  String get noClassificationsAvailable => 'Bu yarışma için klasman yok';

  @override
  String get addAthletes => 'Katılımcı Ekle';

  @override
  String get searchAthleteHint => 'Sporcu ara';

  @override
  String get add => 'Ekle';

  @override
  String selectedCount(int count) {
    return '$count seçili';
  }

  @override
  String get onlyEligible => 'Sadece uygun olanlar';

  @override
  String get noResults => 'Sonuç yok';

  @override
  String get operationFailed => 'İşlem başarısız';

  @override
  String get addedSuccessfully => 'Başarıyla eklendi';

  @override
  String get addToCompetition => 'Yarışmaya ekle';

  @override
  String get searchCompetitionHint => 'Yarışma ara';

  @override
  String get alreadyRequestedThisClassification => 'Bu klasman için zaten bekleyen bir isteğiniz var';

  @override
  String pendingRequestsCount(int count) {
    return 'Bekleyen istek: $count';
  }

  @override
  String acceptedParticipantsCount(int count) {
    return 'Kabul edilen: $count';
  }

  @override
  String get all => 'Tümü';

  @override
  String get classification => 'Klasman';

  @override
  String get participantClassification => 'Klasman';

  @override
  String get participantCompetitionsTitle => 'Katılımlarım';

  @override
  String get participantCompetitionsSubtitle => 'Katıldığınız yarışmaları görüntüleyin.';

  @override
  String get participantCompetitionsEmptyTitle => 'Henüz katılım yok';

  @override
  String get participantCompetitionsEmptyDesc => 'Henüz hiçbir yarışmaya katılmadınız.';

  @override
  String get participantCompetitionsLoadError => 'Katılımlar yüklenemedi';

  @override
  String get competitionStatus => 'Durum';

  @override
  String get joinedOn => 'Katılım tarihi';

  @override
  String get leaveCompetition => 'Ayrıl';

  @override
  String get leaveCompetitionConfirm => 'Bu yarışmadan ayrılmak istiyor musunuz?';

  @override
  String get competitionLeft => 'Yarışmadan ayrıldınız';

  @override
  String get leaveCompetitionError => 'Yarışmadan ayrılma başarısız';

  @override
  String get scoreEntryTitle => 'Skor Girişi';

  @override
  String get scoreEntrySubtitle => 'Bu yarışma için skorlarınızı girin';

  @override
  String get enterScore => 'Skor Gir';

  @override
  String get scoreEntryComingSoon => 'Skor girişi özelliği yakında';

  @override
  String get scoreEntryAllowed => 'Skor girişi açık';

  @override
  String get scoreEntryNotAllowed => 'Skor girişi kapalı';

  @override
  String get classificationLabel => 'Klasman';

  @override
  String get roundCountLabel => 'Round sayısı';

  @override
  String get arrowsPerSetLabel => 'Seri başı ok sayısı';

  @override
  String get setsPerRoundLabel => 'Round başına seri sayısı';

  @override
  String roundSeparator(Object roundNumber) {
    return 'Round $roundNumber';
  }

  @override
  String get myOrganizedCompetitionsTitle => 'Düzenlediğim Yarışmalar';

  @override
  String get myOrganizedCompetitionsSubtitle => 'Oluşturduğunuz yarışmaları yönetin.';

  @override
  String get participantClub => 'Kulüp';

  @override
  String get noClub => 'Kulüp Yok';

  @override
  String get currentSet => 'Mevcut Seri';

  @override
  String get totalScore => 'Toplam Skor';

  @override
  String tapScoreToContinue(int setNumber) {
    return 'Antrenmana devam etmek için aşağıdaki skor butonlarına dokunun. Şu anda $setNumber. Seriyi yazıyorsunuz.';
  }

  @override
  String editSet(int setNumber) {
    return 'Düzenle - Seri $setNumber';
  }

  @override
  String get edit => 'Düzenle';

  @override
  String overwritingSet(int setNumber) {
    return 'Şu anda $setNumber. Seriyi yeniden yazıyorsunuz. Devam etmek için aşağıdaki skor butonlarına dokunun.';
  }

  @override
  String get guestTitle => 'Hoş geldin';

  @override
  String get guestSubtitle => 'Aktif yarışmaları keşfet veya devam etmek için giriş yap.';

  @override
  String get goToLogin => 'Giriş Ekranına Git';

  @override
  String get browseActiveCompetitions => 'Aktif Yarışmalar';

  @override
  String get onboardingWelcomeTitle => 'Hoş geldin';

  @override
  String get onboardingWelcomeSubtitle => 'Dilini seç ve HitScore\'u keşfet';

  @override
  String get onboardingLanguageNext => 'İleri';

  @override
  String get onboardingGetStarted => 'Başla';

  @override
  String get onboardingIntroTitle => 'Yarışmaları kolayca yönet';

  @override
  String get onboardingIntroDescription => 'Yarışmalara katıl, etkinlik düzenle ve skorları takip et.';

  @override
  String get onboardingFeaturesTitle => 'Neler yapabilirsin';

  @override
  String get onboardingFeatureSessionsTitle => 'Katıl';

  @override
  String get onboardingFeatureSessionsDescription => 'Aktif yarışmaları incele ve katılım isteği gönder.';

  @override
  String get onboardingFeatureCoachTitle => 'Düzenle';

  @override
  String get onboardingFeatureCoachDescription => 'Yarışma oluştur, katılımcıları ve klasmanları yönet.';

  @override
  String get onboardingFeatureToolsTitle => 'Skor Takibi';

  @override
  String get onboardingFeatureToolsDescription => 'Skorları net ve uyumlu ekranlarda gir, takip et.';

  @override
  String get availableScoreButtonsLabel => 'Mevcut Skor Butonları';

  @override
  String get availableScoreButtonsDescription => 'Bu klasman için hangi skor butonlarının kullanılacağını seçin';

  @override
  String get autoFilled => 'Otomatik Dolduruldu';

  @override
  String get roundSettingsLabel => 'Tur Ayarları';

  @override
  String get scoreEntryNotAllowedTitle => 'Skor Girişi Mevcut Değil';

  @override
  String get scoreEntryNotAllowedMessage => 'Bu yarışma için şu an için skor girişi yapılamamaktadır. Organizatör açtığı zaman skor girebileceksiniz.';

  @override
  String get ok => 'Tamam';

  @override
  String get filters => 'Filtreler';

  @override
  String get filter => 'Filtre';

  @override
  String get apply => 'Uygula';

  @override
  String get clear => 'Temizle';

  @override
  String get dateFrom => 'Başlangıç tarihi';

  @override
  String get dateTo => 'Bitiş tarihi';

  @override
  String get dateRange => 'Tarih aralığı';

  @override
  String get presetToday => 'Bugün';

  @override
  String get presetThisWeek => 'Bu hafta';

  @override
  String get presetThisMonth => 'Bu ay';

  @override
  String get scorePermission => 'Skor izni';

  @override
  String get scoreAllowed => 'Açık';

  @override
  String get scoreNotAllowed => 'Kapalı';

  @override
  String get sets => 'Seriler';

  @override
  String setLabel(int setNumber) {
    return 'Seri $setNumber';
  }

  @override
  String get arrows => 'Oklar';

  @override
  String get competitionArchiveTitle => 'Yarışma Arşivi';

  @override
  String get competitionArchiveEmptyTitle => 'Arşivde yarışma yok';

  @override
  String get competitionArchiveEmptyDesc => 'Tamamlanan veya geçmiş yarışmalar burada görünecek.';

  @override
  String get addOrganizer => 'Organizatör ekle';

  @override
  String get addOrganizersTitle => 'Organizatör Ekle';

  @override
  String get addOrganizersSubtitle => 'İsim veya profil ID ile ara ve seç.';

  @override
  String get searchUserHint => 'Kullanıcı ara (isim veya profil ID)';

  @override
  String get organizersUpdated => 'Organizatörler güncellendi';

  @override
  String get update => 'Güncelle';

  @override
  String get searchToFindUsers => 'Kullanıcı bulmak için arama yapın';

  @override
  String get creatorTag => 'Oluşturan';

  @override
  String get competitionArchiveSubtitle => 'Tüm yarışmaları incele, geçmiş ve şimdiki.';

  @override
  String get arrowMissSymbol => 'M';

  @override
  String get arrowXSymbol => 'X';

  @override
  String get noArrowsYet => 'Henüz ok yok';

  @override
  String get undo => 'Geri al';

  @override
  String get reset => 'Sıfırla';

  @override
  String get complete => 'Tamamla';

  @override
  String maximumSetsReached(int setsPerRound) {
    return 'Maksimum seri sayısına ulaşıldı ($setsPerRound). Daha fazla seri ekleyemezsiniz.';
  }

  @override
  String get noScoreYet => 'Henüz skor girilmemiş';

  @override
  String get notificationsTitle => 'Bildirimler';

  @override
  String get notificationsWelcomeTitle => 'Güncel Kalın';

  @override
  String get notificationsWelcomeSubtitle => 'Yarışmalarınız ve aktiviteleriniz hakkında en son güncellemeleri alın';

  @override
  String get noNotificationsTitle => 'Henüz bildirim yok';

  @override
  String get noNotificationsSubtitle => 'Yeni bildirimleriniz olduğunda burada görünecek';

  @override
  String get total => 'Toplam';

  @override
  String get eliminationSettingsTitle => 'Eleme Ayarları';

  @override
  String get eliminationSettingsSubtitle => 'Yarışmanız için eleme sistemini yapılandırın';

  @override
  String get bowTypeSelection => 'Yay Türü Seçimi';

  @override
  String get bowTypeSelectionSubtitle => 'Eleme maçları için yay türünü seçin';

  @override
  String get recurveBow => 'Klasik Yay';

  @override
  String get barebowBow => 'Çıplak Yay';

  @override
  String get compoundBow => 'Makaralı Yay';

  @override
  String get cutoffSettings => 'Kesme Sınırı Ayarları';

  @override
  String get cutoffSettingsSubtitle => 'Eleme turuna katılacak sporcular için kesme sırası belirleyin';

  @override
  String get cutoffRank => 'Kesme Sırası';

  @override
  String get cutoffLimit => 'Kesme Sınırı';

  @override
  String cutoffLimitDescription(Object count) {
    return 'İlk $count sıradaki sporcu eleme sistemine dahil olur';
  }

  @override
  String get athleteCount => 'Sporcu Sayısı';

  @override
  String get enterValueBetween => '8-256 arasında bir değer girin';

  @override
  String get possibleBracketCombinations => 'Olası Bracket Kombinasyonları';

  @override
  String availableOptionsForCutoff(Object count) {
    return 'Cutoff ($count sporcu) için mevcut seçenekler:';
  }

  @override
  String personBracket(Object count) {
    return '$count Kişilik Bracket';
  }

  @override
  String get allAthletesInMainTable => 'Tüm sporcular ana tabloda';

  @override
  String preliminaryElimination(Object total, Object winners) {
    return 'Ön Eleme: $total sporcu → $winners kazanan';
  }

  @override
  String get allAthletesInMainTableShort => 'Tüm sporcular ana tabloda';

  @override
  String preliminaryEliminationShort(Object total, Object winners) {
    return 'Ön Eleme: $total sporcu → $winners kazanan';
  }

  @override
  String get close => 'Kapat';

  @override
  String get showAllMatches => 'Tüm Maçları Göster';

  @override
  String get detailedMatchSchedule => 'Detaylı Maç Programı';

  @override
  String mainTableStart(Object count) {
    return 'Ana Tablo Başlangıcı ($count sporcu)';
  }

  @override
  String preliminaryEliminationStart(Object target, Object total) {
    return 'Ön Eleme ($total → $target sporcu)';
  }

  @override
  String get byeSettings => 'Bay Geçme Ayarları';

  @override
  String get byeSettingsSubtitle => 'Bay geçme (otomatik yükselme) ayarlarını yapılandırın';

  @override
  String get allowByes => 'Bay Geçmeye İzin Ver';

  @override
  String get allowByesSubtitle => 'En yüksek sıralamalı sporcular için otomatik yükselmeyi etkinleştir';

  @override
  String get byeStrategy => 'Bay Geçme Stratejisi';

  @override
  String get highestRankingStrategy => 'En Yüksek Sıralama';

  @override
  String get evenDistributionStrategy => 'Eşit Dağılım';

  @override
  String get performanceBasedStrategy => 'Performans Bazlı';

  @override
  String get bracketSettings => 'Bracket Ayarları';

  @override
  String get bracketSettingsSubtitle => 'Eleme için bracket boyutunu seçin';

  @override
  String get eliminationPreview => 'Eleme Önizleme';

  @override
  String get noValidCombinations => 'Geçerli kombinasyon yok';

  @override
  String get recommended => 'Önerilen';

  @override
  String get eliminationBracketTitle => 'Eleme Bracket';

  @override
  String get totalParticipants => 'Katılımcı';

  @override
  String get activeMatches => 'Aktif';

  @override
  String get currentRound => 'Tur';

  @override
  String get round => 'Tur';

  @override
  String get bracketTree => 'Bracket Ağacı';

  @override
  String get bracketVisualizationComingSoon => 'Bracket Görselleştirme';

  @override
  String get bracketVisualizationSubtitle => 'İnteraktif bracket ağacı görünümü yakında gelecek';

  @override
  String get matches => 'Maçlar';

  @override
  String get noMatchesInRound => 'Bu turda maç yok';

  @override
  String get noMatchesInRoundSubtitle => 'Maçlar oluşturulduğunda burada görünecek';

  @override
  String get scoreMatch => 'Skor';

  @override
  String get bye => 'Bay';

  @override
  String get unknown => 'Bilinmeyen';

  @override
  String get eliminationSettings => 'Ayarlar';

  @override
  String get exportResults => 'Sonuçları Dışa Aktar';

  @override
  String get eliminationStatusTitle => 'Eleme Durumu';

  @override
  String get statusActive => 'Aktif';

  @override
  String get statusEliminated => 'Elendi';

  @override
  String get statusChampion => 'Şampiyon';

  @override
  String get statusUnknown => 'Bilinmeyen';

  @override
  String get currentPosition => 'Mevcut Pozisyon';

  @override
  String get bracketPosition => 'Pozisyon';

  @override
  String get byeStatusMessage => 'Bay geçtiniz ve otomatik olarak sonraki tura yükseldiniz';

  @override
  String get nextMatch => 'Sonraki Maç';

  @override
  String get you => 'Sen';

  @override
  String get tbd => 'Belirlenecek';

  @override
  String get scheduledTime => 'Planlanma';

  @override
  String get noUpcomingMatch => 'Yaklaşan maç yok';

  @override
  String get myMatches => 'Maçlarım';

  @override
  String get noMatchHistory => 'Henüz maç geçmişi yok';

  @override
  String get victory => 'Zafer';

  @override
  String get defeat => 'Mağlubiyet';

  @override
  String get statistics => 'İstatistikler';

  @override
  String get matchesPlayed => 'Oynanan';

  @override
  String get wins => 'Galibiyet';

  @override
  String get losses => 'Mağlubiyet';

  @override
  String get matchScoringTitle => 'Maç Skor Girişi';

  @override
  String get participant1 => 'Katılımcı 1';

  @override
  String get participant2 => 'Katılımcı 2';

  @override
  String get selectSet => 'Seri Seç';

  @override
  String get set => 'Seri';

  @override
  String get scoring => 'Skor Girişi';

  @override
  String get score => 'Skor';

  @override
  String get saveSet => 'Seriyi Kaydet';

  @override
  String get completedSets => 'Tamamlanan Seriler';

  @override
  String get tieBreak => 'Beraberlik Atışı';

  @override
  String get tieBreakDescription => 'Maç berabere. Beraberlik atışı gerekiyor.';

  @override
  String get startTieBreak => 'Beraberlik Atışı Başlat';

  @override
  String get completeMatch => 'Maçı Tamamla';

  @override
  String get matchCompleted => 'Maç Tamamlandı';

  @override
  String get matchCompletedDescription => 'Maç başarıyla tamamlandı ve kaydedildi';

  @override
  String get completed => 'Tamamlandı';

  @override
  String get active => 'Aktif';

  @override
  String get classificationNamePreview => 'Klasman İsmi Önizleme';

  @override
  String get classificationNamePreviewEmpty => 'Otomatik oluşturulan ismi görmek için klasman özelliklerini seçin';

  @override
  String get autoSelected => 'Otomatik Seçildi';

  @override
  String get multiByeSystem => 'Çoklu Bay Sistem';

  @override
  String multiByeSystemStart(String total, String target) {
    return 'Çoklu Bay Eleme Sistemi ($total → $target sporcu)';
  }

  @override
  String multiByeSystemShort(String threeRound, String twoRound, String oneRound, String zeroRound) {
    return '3T: $threeRound, 2T: $twoRound, 1T: $oneRound, 0T: $zeroRound';
  }

  @override
  String get thirdPlaceMatch => '3.lük Maçı';

  @override
  String get thirdPlaceMatchTitle => '3.LÜK MAÇI';

  @override
  String thirdPlaceMatchDescription(int round) {
    return '3.LÜK: L${round}_1 vs L${round}_2';
  }

  @override
  String get register => 'Kayıt Ol';

  @override
  String get forgotPassword => 'Şifremi Unuttum';

  @override
  String get confirmPasswordLabel => 'Şifre Tekrarı';

  @override
  String get passwordTooShort => 'Şifre en az 6 karakter olmalıdır';

  @override
  String get passwordMismatch => 'Şifreler eşleşmiyor';

  @override
  String get emailRequired => 'E-posta gereklidir';

  @override
  String get tooManyRequests => 'Çok fazla istek. Lütfen daha sonra tekrar deneyin';

  @override
  String get emailVerificationRequiredContent => 'Adresinize bir doğrulama e-postası gönderdik. Lütfen e-postanızı kontrol edin ve hesabınızı etkinleştirmek için doğrulama bağlantısına tıklayın.';

  @override
  String get emailAlreadyRegisteredTitle => 'E-posta Zaten Kayıtlı';

  @override
  String get emailAlreadyRegisteredMessage => 'Bu e-posta adresi zaten kayıtlı. Lütfen giriş yapmayı deneyin.';

  @override
  String get forgotPasswordTitle => 'Şifremi Unuttum';

  @override
  String get forgotPasswordDescription => 'E-posta adresinizi girin, size şifre sıfırlama bağlantısı gönderelim.';

  @override
  String get sendResetLink => 'Sıfırlama Bağlantısı Gönder';

  @override
  String get resetLinkSent => 'Şifre sıfırlama bağlantısı e-postanıza gönderildi';

  @override
  String get resetPasswordTitle => 'Şifre Sıfırla';

  @override
  String get newPasswordLabel => 'Yeni Şifre';

  @override
  String get confirmPasswordRequired => 'Lütfen şifrenizi onaylayın';

  @override
  String get passwordRequired => 'Şifre gereklidir';

  @override
  String get resetPasswordButton => 'Şifreyi Sıfırla';

  @override
  String get passwordResetSuccess => 'Şifre başarıyla sıfırlandı';

  @override
  String get redirectingToLogin => 'Giriş sayfasına yönlendiriliyor...';

  @override
  String get invalidResetLink => 'Geçersiz veya süresi dolmuş sıfırlama bağlantısı';

  @override
  String get invalidResetLinkDescription => 'Bu şifre sıfırlama bağlantısı geçersiz veya süresi dolmuş. Lütfen yeni bir şifre sıfırlama isteği gönderin.';

  @override
  String get backToLogin => 'Giriş Ekranına Dön';

  @override
  String get tokenExpired => 'Şifre sıfırlama bağlantısının süresi doldu';

  @override
  String get passwordResetError => 'Şifre sıfırlama hatası';

  @override
  String get processingAuthentication => 'Sıfırlama bağlantısı doğrulanıyor...';

  @override
  String get resetPasswordNewPasswordTitle => 'Yeni Şifre Girin';

  @override
  String get resetPasswordNewPasswordDescription => 'Lütfen aşağıya yeni şifrenizi girin';

  @override
  String get tokenExpiryWarning => 'Bu sıfırlama bağlantısının süresi hızla doluyor. Lütfen işlemi hemen tamamlayın.';

  @override
  String error(String message) {
    return 'Hata: $message';
  }
}
