import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Navigation
      'nav_home': 'Home',
      'nav_education': 'Education',
      'nav_detection': 'Detection',
      'nav_explore': 'Explore',
      'nav_personal': 'Personal',
      
      // Common
      'back': 'Back',
      'save': 'Save',
      'cancel': 'Cancel',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
      'confirm': 'Confirm',
      'success': 'Success',
      'error': 'Error',
      'delete': 'Delete',
      'edit': 'Edit',
      
      // Auth
      'login': 'Login',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'username': 'Username',
      'forgot_password': 'Forgot Password?',
      'dont_have_account': "Don't have an account?",
      'already_have_account': 'Already have an account?',
      
      // Settings
      'settings': 'Settings',
      'language': 'Language',
      'profile': 'Profile',
      'logout': 'Logout',
      'change_language': 'Change Language',
      'language_changed': 'Language successfully changed to',
      'confirm_language_change': 'Are you sure you want to change the language to',
      'logout_confirm': 'Are you sure you want to logout?',
      
      // Language Names
      'english': 'English',
      'indonesian': 'Bahasa Indonesia',
      
      // Profile Menu
      'personal_info': 'Personal Information',
      'history': 'History',
      'help': 'Help',
      'about_us': 'About Us',
      
      // Personal Info
      'full_name': 'FULL NAME',
      'address': 'ADDRESS',
      'new_password': 'NEW PASSWORD',
      'confirm_password': 'CONFIRM NEW PASSWORD',
      'edit_profile': 'Edit Profile',
      'name': 'NAME',
      
      // History
      'no_history': 'No history',
      'delete_all': 'Delete All',
      'delete_history': 'Delete History',
      'delete_all_history': 'Delete All History',
      'delete_confirm': 'Are you sure you want to delete',
      'delete_all_confirm': 'Are you sure you want to delete all history?',
      'history_deleted': 'History successfully deleted',
      'all_history_deleted': 'All history successfully deleted',
      
      // Help
      'need_help': 'Need Help?',
      'we_ready_to_help': 'We are ready to help you',
      'contact_us': 'Contact Us',
      'send_email': 'Send Email',
      'send_question': 'Send your questions or complaints via email. Our support team will respond as soon as possible.',
      'faq': 'Frequently Asked Questions',
      'faq_1_q': 'How to use the sign detection feature?',
      'faq_1_a': 'Open the Detection menu, then point the camera at the traffic sign. The app will automatically detect and provide information about the sign.',
      'faq_2_q': 'How to view the sign catalog?',
      'faq_2_a': 'On the home page, you can see various categories of traffic signs such as Prohibition, Warning, Command, and Direction.',
      'faq_3_q': 'Does this app require an internet connection?',
      'faq_3_a': 'Some features such as sign detection and education can be used offline. However, the explore maps feature requires an internet connection.',
      'faq_4_q': 'How to change language?',
      'faq_4_a': 'Open Settings menu > Language, then select the desired language.',
      'email_error': 'Cannot open email application. Please send email to: rambuid09@gmail.com',
      
      // About Us
      'about_app': 'About Application',
      'about_app_desc': 'RambuID is a traffic sign education application designed to help users understand various types of traffic signs easily and interactively.',
      'about_app_desc2': 'With advanced features such as sign detection using camera, complete sign catalog, interactive education, and sign location maps, RambuID helps increase awareness and understanding of traffic signs in Indonesia.',
      'main_features': 'Main Features',
      'feature_detection': 'Sign Detection',
      'feature_detection_desc': 'Detect traffic signs in real-time using camera',
      'feature_catalog': 'Sign Catalog',
      'feature_catalog_desc': 'Complete collection of various types of traffic signs',
      'feature_education': 'Interactive Education',
      'feature_education_desc': 'Learn traffic signs in a fun way',
      'feature_maps': 'Explore Maps',
      'feature_maps_desc': 'Find traffic sign locations around you',
      'app_version': 'Application Version',
      'all_rights_reserved': '© 2025 RambuID. All rights reserved.',
      
      // Validation Messages
      'name_required': 'Name cannot be empty',
      'email_required': 'Email cannot be empty',
      'email_invalid': 'Invalid email format',
      'address_required': 'Address cannot be empty',
      'password_required': 'New password must be filled',
      'password_min': 'Password minimum 6 characters',
      'password_not_match': 'Password does not match',
      'profile_update_failed': 'Failed to update profile',
      'profile_update_success': 'Profile successfully saved!',
      'profile_load_failed': 'Failed to load profile',
      'choose_profile_photo': 'Choose Profile Photo',
      'take_from_camera': 'Take from Camera',
      'choose_from_gallery': 'Choose from Gallery',
      'remove_photo': 'Remove Photo',
      'camera_error': 'Failed to take photo from camera',
      'gallery_error': 'Failed to choose image from gallery',
      
      // Home/Beranda
      'traffic_signs_catalog': 'Traffic Signs Catalog',
      'search': 'Search',
      
      // Education
      'education_title': 'Traffic Education',
      'learn_more': 'Learn More',
      
      // Detection
      'detection_title': 'Sign Detection',
      'take_photo': 'Take Photo',
      
      // Maps
      'explore_maps': 'Explore Maps',
      'your_location': 'Your Location',
      'search_location': 'Search location...',
      'destination': 'Destination',
      'near': 'Near',
      'all_categories': 'All',
      'fastest_route': 'Fastest route currently based on traffic conditions',
      'km_from_location': 'km from your location',
      'estimated_minutes': 'Estimated',
      'minutes': 'minutes',
      
      // Categories
      'category_prohibition': 'Prohibition',
      'category_warning': 'Warning',
      'category_command': 'Command',
      'category_direction': 'Direction',
      'category_all': 'All',
      
      // Detection
      'detection': 'Detection',
      'point_camera': 'Point camera at traffic sign',
      'detecting': 'Detecting sign...',
      'detection_result': 'Detection Result',
      'sign_detected': 'Sign Detected:',
      'close': 'Close',
      'scan_again': 'Scan Again',
      'sign_description': 'Description:',
      
      // Detail Sign
      'sign_detail': 'Sign Detail',
      'sign_name': 'SIGN NAME',
      'sign_type': 'SIGN TYPE',
      'information': 'INFORMATION',
      'listen': 'Listen',
      'stop': 'Stop',
      
      // Education
      'sign_list': 'Sign List',
      'search_sign_name': 'Search Sign Name',
      'data_not_found': 'Data not found',
    },
    'id': {
      // Navigation
      'nav_home': 'Beranda',
      'nav_education': 'Edukasi',
      'nav_detection': 'Deteksi',
      'nav_explore': 'Jelajahi',
      'nav_personal': 'Personal',
      
      // Common
      'back': 'Kembali',
      'save': 'Simpan',
      'cancel': 'Batal',
      'yes': 'Ya',
      'no': 'Tidak',
      'ok': 'OK',
      'confirm': 'Konfirmasi',
      'success': 'Berhasil',
      'error': 'Error',
      'delete': 'Hapus',
      'edit': 'Ubah',
      
      // Auth
      'login': 'Masuk',
      'register': 'Daftar',
      'email': 'Email',
      'password': 'Kata Sandi',
      'username': 'Nama Pengguna',
      'forgot_password': 'Lupa Kata Sandi?',
      'dont_have_account': 'Belum punya akun?',
      'already_have_account': 'Sudah punya akun?',
      
      // Settings
      'settings': 'Pengaturan',
      'language': 'Bahasa',
      'profile': 'Profil',
      'logout': 'Keluar',
      'change_language': 'Ganti Bahasa',
      'language_changed': 'Bahasa berhasil diubah ke',
      'confirm_language_change': 'Apakah Anda yakin ingin mengubah bahasa ke',
      'logout_confirm': 'Apakah Anda yakin ingin keluar?',
      
      // Language Names
      'english': 'English',
      'indonesian': 'Bahasa Indonesia',
      
      // Profile Menu
      'personal_info': 'Tentang Pribadi',
      'history': 'Riwayat',
      'help': 'Bantuan',
      'about_us': 'Tentang Kami',
      
      // Personal Info
      'full_name': 'NAMA LENGKAP',
      'address': 'ALAMAT',
      'new_password': 'KATA SANDI BARU',
      'confirm_password': 'KONFIRMASI KATA SANDI BARU',
      'edit_profile': 'Ubah Profil',
      'name': 'NAMA',
      
      // History
      'no_history': 'Tidak ada riwayat',
      'delete_all': 'Hapus Semua',
      'delete_history': 'Hapus Riwayat',
      'delete_all_history': 'Hapus Semua Riwayat',
      'delete_confirm': 'Apakah Anda yakin ingin menghapus',
      'delete_all_confirm': 'Apakah Anda yakin ingin menghapus semua riwayat?',
      'history_deleted': 'Riwayat berhasil dihapus',
      'all_history_deleted': 'Semua riwayat berhasil dihapus',
      
      // Help
      'need_help': 'Butuh Bantuan?',
      'we_ready_to_help': 'Kami siap membantu Anda',
      'contact_us': 'Hubungi Kami',
      'send_email': 'Kirim Email',
      'send_question': 'Kirimkan pertanyaan atau keluhan Anda melalui email. Tim support kami akan merespons secepat mungkin.',
      'faq': 'Pertanyaan Umum',
      'faq_1_q': 'Bagaimana cara menggunakan fitur deteksi rambu?',
      'faq_1_a': 'Buka menu Deteksi, lalu arahkan kamera ke rambu lalu lintas. Aplikasi akan secara otomatis mendeteksi dan memberikan informasi tentang rambu tersebut.',
      'faq_2_q': 'Bagaimana cara melihat katalog rambu?',
      'faq_2_a': 'Di halaman beranda, Anda dapat melihat berbagai kategori rambu lalu lintas seperti Larangan, Peringatan, Perintah, dan Petunjuk.',
      'faq_3_q': 'Apakah aplikasi ini memerlukan koneksi internet?',
      'faq_3_a': 'Beberapa fitur seperti deteksi rambu dan edukasi dapat digunakan offline. Namun, untuk fitur jelajahi maps memerlukan koneksi internet.',
      'faq_4_q': 'Bagaimana cara mengubah bahasa?',
      'faq_4_a': 'Buka menu Pengaturan > Bahasa, lalu pilih bahasa yang diinginkan.',
      'email_error': 'Tidak dapat membuka aplikasi email. Silakan kirim email ke: rambuid09@gmail.com',
      
      // About Us
      'about_app': 'Tentang Aplikasi',
      'about_app_desc': 'RambuID adalah aplikasi edukasi rambu lalu lintas yang dirancang untuk membantu pengguna memahami berbagai jenis rambu lalu lintas dengan mudah dan interaktif.',
      'about_app_desc2': 'Dengan fitur-fitur canggih seperti deteksi rambu menggunakan kamera, katalog rambu lengkap, edukasi interaktif, dan peta lokasi rambu, RambuID membantu meningkatkan kesadaran dan pemahaman tentang rambu lalu lintas di Indonesia.',
      'main_features': 'Fitur Utama',
      'feature_detection': 'Deteksi Rambu',
      'feature_detection_desc': 'Deteksi rambu lalu lintas secara real-time menggunakan kamera',
      'feature_catalog': 'Katalog Rambu',
      'feature_catalog_desc': 'Koleksi lengkap berbagai jenis rambu lalu lintas',
      'feature_education': 'Edukasi Interaktif',
      'feature_education_desc': 'Pelajari rambu lalu lintas dengan cara yang menyenangkan',
      'feature_maps': 'Jelajahi Maps',
      'feature_maps_desc': 'Temukan lokasi rambu lalu lintas di sekitar Anda',
      'app_version': 'Versi Aplikasi',
      'all_rights_reserved': '© 2025 RambuID. All rights reserved.',
      
      // Validation Messages
      'name_required': 'Nama tidak boleh kosong',
      'email_required': 'Email tidak boleh kosong',
      'email_invalid': 'Format email tidak valid',
      'address_required': 'Alamat tidak boleh kosong',
      'password_required': 'Kata sandi baru harus diisi',
      'password_min': 'Kata sandi minimal 6 karakter',
      'password_not_match': 'Kata sandi tidak cocok',
      'profile_update_failed': 'Gagal memperbarui profil',
      'profile_update_success': 'Profil berhasil disimpan!',
      'profile_load_failed': 'Gagal memuat profil',
      'choose_profile_photo': 'Pilih Foto Profil',
      'take_from_camera': 'Ambil dari Kamera',
      'choose_from_gallery': 'Pilih dari Galeri',
      'remove_photo': 'Hapus Foto',
      'camera_error': 'Gagal mengambil foto dari kamera',
      'gallery_error': 'Gagal memilih gambar dari galeri',
      
      // Home/Beranda
      'traffic_signs_catalog': 'Katalog Rambu Lalu Lintas',
      'search': 'Cari',
      
      // Education
      'education_title': 'Edukasi Lalu Lintas',
      'learn_more': 'Pelajari Lebih Lanjut',
      
      // Detection
      'detection_title': 'Deteksi Rambu',
      'take_photo': 'Ambil Foto',
      
      // Maps
      'explore_maps': 'Jelajahi Peta',
      'your_location': 'Lokasi Anda',
      'search_location': 'Cari lokasi...',
      'destination': 'Destinasi',
      'near': 'Dekat',
      'all_categories': 'Semua',
      'fastest_route': 'Rute tercepat saat ini berdasarkan kondisi lalu lintas',
      'km_from_location': 'km dari lokasi Anda',
      'estimated_minutes': 'Estimasi',
      'minutes': 'menit',
      
      // Categories
      'category_prohibition': 'Larangan',
      'category_warning': 'Peringatan',
      'category_command': 'Perintah',
      'category_direction': 'Petunjuk',
      'category_all': 'Semua',
      
      // Detection
      'detection': 'Deteksi',
      'point_camera': 'Arahkan kamera ke rambu lalu lintas',
      'detecting': 'Mendeteksi rambu...',
      'detection_result': 'Hasil Deteksi',
      'sign_detected': 'Rambu Terdeteksi:',
      'close': 'Tutup',
      'scan_again': 'Scan Lagi',
      'sign_description': 'Deskripsi:',
      
      // Detail Sign
      'sign_detail': 'Detail Rambu',
      'sign_name': 'NAMA RAMBU',
      'sign_type': 'JENIS RAMBU',
      'information': 'KETERANGAN',
      'listen': 'Dengarkan',
      'stop': 'Berhenti',
      
      // Education
      'sign_list': 'Daftar Rambu',
      'search_sign_name': 'Cari Nama Rambu',
      'data_not_found': 'Data tidak ditemukan',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]![key] ?? key;
  }

  // Helper getters untuk akses cepat
  String get navHome => translate('nav_home');
  String get navEducation => translate('nav_education');
  String get navDetection => translate('nav_detection');
  String get navExplore => translate('nav_explore');
  String get navPersonal => translate('nav_personal');
  
  String get back => translate('back');
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get yes => translate('yes');
  String get no => translate('no');
  String get edit => translate('edit');
  String get delete => translate('delete');
  
  String get login => translate('login');
  String get register => translate('register');
  String get email => translate('email');
  String get password => translate('password');
  String get username => translate('username');
  
  String get settings => translate('settings');
  String get language => translate('language');
  String get profile => translate('profile');
  String get logout => translate('logout');
  String get changeLanguage => translate('change_language');
  String get languageChanged => translate('language_changed');
  String get confirmLanguageChange => translate('confirm_language_change');
  String get logoutConfirm => translate('logout_confirm');
  
  String get english => translate('english');
  String get indonesian => translate('indonesian');
  
  String get personalInfo => translate('personal_info');
  String get history => translate('history');
  String get help => translate('help');
  String get aboutUs => translate('about_us');
  
  String get fullName => translate('full_name');
  String get address => translate('address');
  String get newPassword => translate('new_password');
  String get confirmPassword => translate('confirm_password');
  String get editProfile => translate('edit_profile');
  String get name => translate('name');
  
  String get noHistory => translate('no_history');
  String get deleteAll => translate('delete_all');
  String get deleteHistory => translate('delete_history');
  String get deleteAllHistory => translate('delete_all_history');
  String get deleteConfirm => translate('delete_confirm');
  String get deleteAllConfirm => translate('delete_all_confirm');
  String get historyDeleted => translate('history_deleted');
  String get allHistoryDeleted => translate('all_history_deleted');
  
  String get needHelp => translate('need_help');
  String get weReadyToHelp => translate('we_ready_to_help');
  String get contactUs => translate('contact_us');
  String get sendEmail => translate('send_email');
  String get sendQuestion => translate('send_question');
  String get faq => translate('faq');
  String get faq1Q => translate('faq_1_q');
  String get faq1A => translate('faq_1_a');
  String get faq2Q => translate('faq_2_q');
  String get faq2A => translate('faq_2_a');
  String get faq3Q => translate('faq_3_q');
  String get faq3A => translate('faq_3_a');
  String get faq4Q => translate('faq_4_q');
  String get faq4A => translate('faq_4_a');
  String get emailError => translate('email_error');
  
  String get aboutApp => translate('about_app');
  String get aboutAppDesc => translate('about_app_desc');
  String get aboutAppDesc2 => translate('about_app_desc2');
  String get mainFeatures => translate('main_features');
  String get featureDetection => translate('feature_detection');
  String get featureDetectionDesc => translate('feature_detection_desc');
  String get featureCatalog => translate('feature_catalog');
  String get featureCatalogDesc => translate('feature_catalog_desc');
  String get featureEducation => translate('feature_education');
  String get featureEducationDesc => translate('feature_education_desc');
  String get featureMaps => translate('feature_maps');
  String get featureMapsDesc => translate('feature_maps_desc');
  String get appVersion => translate('app_version');
  String get allRightsReserved => translate('all_rights_reserved');
  
  String get nameRequired => translate('name_required');
  String get emailRequired => translate('email_required');
  String get emailInvalid => translate('email_invalid');
  String get addressRequired => translate('address_required');
  String get passwordRequired => translate('password_required');
  String get passwordMin => translate('password_min');
  String get passwordNotMatch => translate('password_not_match');
  String get profileUpdateFailed => translate('profile_update_failed');
  String get profileUpdateSuccess => translate('profile_update_success');
  String get profileLoadFailed => translate('profile_load_failed');
  String get chooseProfilePhoto => translate('choose_profile_photo');
  String get takeFromCamera => translate('take_from_camera');
  String get chooseFromGallery => translate('choose_from_gallery');
  String get removePhoto => translate('remove_photo');
  String get cameraError => translate('camera_error');
  String get galleryError => translate('gallery_error');
  
  String get trafficSignsCatalog => translate('traffic_signs_catalog');
  String get search => translate('search');
  String get educationTitle => translate('education_title');
  String get detectionTitle => translate('detection_title');
  String get exploreMaps => translate('explore_maps');
  String get takePhoto => translate('take_photo');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'id'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}