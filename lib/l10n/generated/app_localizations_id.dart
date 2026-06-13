// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLId extends AppL {
  AppLId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Polaris';

  @override
  String get commonCancel => 'Batal';

  @override
  String get commonSave => 'Simpan';

  @override
  String get commonSaving => 'Menyimpan…';

  @override
  String get commonDelete => 'Hapus';

  @override
  String get commonOk => 'OK';

  @override
  String get commonRetry => 'Coba lagi';

  @override
  String get navLife => 'Hidup';

  @override
  String get navEvents => 'Acara';

  @override
  String get navLifestyle => 'Gaya Hidup';

  @override
  String get navSettings => 'Pengaturan';

  @override
  String get onboardingWelcome => 'Selamat datang di Polaris';

  @override
  String get onboardingSetup => 'Atur hitung mundur Anda';

  @override
  String get onboardingDescription =>
      'Data ini tersimpan di perangkat Anda. Digunakan untuk memperkirakan sisa hari menggunakan tabel harapan hidup publik.';

  @override
  String get onboardingBirthDate => 'Tanggal lahir';

  @override
  String get onboardingSex => 'Jenis kelamin biologis';

  @override
  String get onboardingCountry => 'Negara';

  @override
  String get onboardingStart => 'Mulai hitung mundur';

  @override
  String get onboardingDisclaimer =>
      'Hanya estimasi — berdasarkan tabel harapan hidup publik (WHO, BPS). Bukan prediksi medis.';

  @override
  String get sexFemale => 'Perempuan';

  @override
  String get sexMale => 'Laki-laki';

  @override
  String get sexUndisclosed => 'Tidak diisi';

  @override
  String get lifeTitle => 'Sisa Hariku';

  @override
  String get lifeDisplayDays => 'Hari';

  @override
  String get lifeDisplayWeeks => 'Minggu';

  @override
  String get lifeDisplayMonths => 'Bulan';

  @override
  String get lifeDisplayYears => 'Tahun';

  @override
  String get lifeDisplayPercent => '%';

  @override
  String lifeAlreadyLived(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted hari telah dijalani',
      one: '1 hari telah dijalani',
    );
    return '$_temp0';
  }

  @override
  String get lifeEstimatedEndDate => 'Perkiraan tanggal akhir';

  @override
  String get lifeExpectancyUsed => 'Harapan hidup yang dipakai';

  @override
  String lifeExpectancyYears(String years) {
    return '$years tahun';
  }

  @override
  String lifeFailedToCompute(String error) {
    return 'Gagal menghitung estimasi: $error';
  }

  @override
  String get lifeUnitDays => 'HARI TERSISA';

  @override
  String get lifeUnitWeeks => 'MINGGU TERSISA';

  @override
  String get lifeUnitMonths => 'BULAN TERSISA';

  @override
  String get lifeUnitYears => 'TAHUN TERSISA';

  @override
  String get lifeUnitPercent => 'TELAH DIJALANI';

  @override
  String get eventsNewEvent => 'Acara baru';

  @override
  String get eventsEmptyTitle => 'Belum ada acara';

  @override
  String get eventsEmptyBody =>
      'Ketuk \"Acara baru\" untuk menambah ulang tahun, tenggat, atau perjalanan — lalu sematkan satu ke widget home screen.';

  @override
  String get eventsEditTitle => 'Ubah acara';

  @override
  String get eventsNewTitle => 'Acara baru';

  @override
  String get eventsFieldTitle => 'Judul';

  @override
  String get eventsFieldTitleRequired => 'Judul harus diisi.';

  @override
  String get eventsFieldWhen => 'Kapan';

  @override
  String get eventsFieldRepeats => 'Berulang';

  @override
  String get eventsFieldNote => 'Catatan (opsional)';

  @override
  String get eventsAccentColor => 'Warna aksen';

  @override
  String get eventsDeleteConfirmTitle => 'Hapus acara?';

  @override
  String eventsDeleteConfirmBody(String title) {
    return '\"$title\" akan dihapus.';
  }

  @override
  String eventsPinFailed(String error) {
    return 'Gagal menyematkan: $error';
  }

  @override
  String eventsDeleteFailed(String error) {
    return 'Gagal menghapus: $error';
  }

  @override
  String eventsSaveFailed(String error) {
    return 'Gagal menyimpan: $error';
  }

  @override
  String get eventsCountdownToday => 'Hari ini';

  @override
  String get eventsCountdownTomorrow => 'Besok';

  @override
  String eventsCountdownDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hari',
      one: '1 hari',
    );
    return '$_temp0';
  }

  @override
  String get eventsCountdownPast => 'Telah lewat';

  @override
  String get eventsActionPin => 'Sematkan';

  @override
  String get eventsActionUnpin => 'Lepaskan';

  @override
  String get eventsActionDelete => 'Hapus';

  @override
  String get eventsActionsMenuLabel => 'Aksi lainnya';

  @override
  String get eventsPinnedSemanticLabel => 'Tersemat ke widget';

  @override
  String eventsCountdownBadgeSemanticLabel(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days hari lagi',
      one: '1 hari lagi',
      zero: 'Hari ini',
    );
    return '$_temp0';
  }

  @override
  String lifeCountdownSemanticLabel(String value, String unit) {
    return '$value $unit';
  }

  @override
  String get recurrenceNone => 'Tidak berulang';

  @override
  String get recurrenceYearly => 'Tahunan';

  @override
  String get recurrenceMonthly => 'Bulanan';

  @override
  String get recurrenceWeekly => 'Mingguan';

  @override
  String get lifestyleQuickLog => 'Catat cepat';

  @override
  String get lifestyleHistoryHeader => '7 hari terakhir';

  @override
  String get lifestyleHistoryHelper => 'Geser baris untuk menghapus';

  @override
  String get lifestyleHistoryEmpty =>
      'Belum ada catatan dalam 7 hari terakhir.';

  @override
  String get lifestyleHistoryEmptyHint =>
      'Ketuk \"Catat cepat\" untuk mencatat pertama kali.';

  @override
  String get lifestyleCategoryWater => 'Air';

  @override
  String get lifestyleCategorySleep => 'Tidur';

  @override
  String get lifestyleCategoryExercise => 'Olahraga';

  @override
  String get lifestyleCategoryMood => 'Mood';

  @override
  String get lifestyleUnitGlasses => 'gelas';

  @override
  String get lifestyleUnitHours => 'jam';

  @override
  String get lifestyleUnitMinutes => 'menit';

  @override
  String get lifestyleUnitMood => '/5';

  @override
  String lifestyleEntriesToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count catatan hari ini',
      one: '1 catatan hari ini',
    );
    return '$_temp0';
  }

  @override
  String get lifestyleDeleteConfirmTitle => 'Hapus catatan?';

  @override
  String lifestyleDeleteConfirmBody(String category) {
    return 'Hapus catatan $category ini?';
  }

  @override
  String get lifestyleQuickLogCategory => 'Kategori';

  @override
  String get lifestyleQuickLogValue => 'Nilai';

  @override
  String lifestyleQuickLogRange(String min, String max, String unit) {
    return '$min–$max $unit';
  }

  @override
  String get lifestyleQuickLogValueRequired => 'Masukkan angka.';

  @override
  String lifestyleQuickLogValueOutOfRange(String range, String unit) {
    return 'Harus $range $unit.';
  }

  @override
  String get lifestyleNoteOptional => 'Catatan (opsional)';

  @override
  String lifestyleSaveFailed(String error) {
    return 'Gagal menyimpan: $error';
  }

  @override
  String lifestyleDeleteFailed(String error) {
    return 'Gagal menghapus: $error';
  }

  @override
  String get lifestyleHistoryYesterday => 'Kemarin';

  @override
  String lifestyleHistoryDaysAgo(int count) {
    return '${count}h lalu';
  }

  @override
  String lifestyleLoadFailed(String error) {
    return 'Gagal memuat: $error';
  }

  @override
  String get insightsSectionTitle => 'Saran untuk Anda';

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get settingsLanguage => 'Bahasa';

  @override
  String get settingsLanguageSystem => 'Ikuti sistem';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageIndonesian => 'Bahasa Indonesia';

  @override
  String get settingsAbout => 'Tentang';

  @override
  String settingsAboutVersion(String version) {
    return 'Versi $version';
  }

  @override
  String get settingsProfile => 'Profil';

  @override
  String get settingsHideLifeCountdown => 'Sembunyikan hitung mundur hidup';

  @override
  String get settingsHideLifeCountdownHint =>
      'Redam hitung mundur di beranda kalau terasa berat.';

  @override
  String get settingsDangerZone => 'Zona berbahaya';

  @override
  String get settingsClearAllData => 'Hapus semua data';

  @override
  String get settingsClearAllDataConfirmTitle => 'Hapus semuanya?';

  @override
  String get settingsClearAllDataConfirmBody =>
      'Menghapus profil, acara, catatan gaya hidup, dan widget tersemat. Tidak bisa dibatalkan.';
}
