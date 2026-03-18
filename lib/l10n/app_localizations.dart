import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const delegate = _AppLocalizationsDelegate();

  bool get isTr => locale.languageCode == 'tr';

  String get appName => 'Akçe Pay';
  String get welcomeBack => isTr ? 'Tekrar Hoş Geldiniz' : 'Welcome Back';
  String get secureBanking => isTr ? 'GÜVENLİ BANKACILIK' : 'SECURE BANKING';
  String get securebanking => isTr ? 'GÜVENLİ BANKACILIK' : 'SECURE BANKING';
  String get billAmount => isTr ? 'Fatura Tutarı' : 'Bill Amount';
  String get emailAddress => isTr ? 'E-posta adresi' : 'Email address';
  String get password => isTr ? 'Şifre' : 'Password';
  String get forgotPassword => isTr ? 'Şifremi unuttum?' : 'Forgot password?';
  String get login => isTr ? 'Giriş Yap' : 'Login';
  String get createAccount => isTr ? 'Hesap Oluştur' : 'Create Account';
  String get goodMorning => isTr ? 'Günaydın,' : 'Good morning,';
  String get totalBalance => isTr ? 'Toplam Bakiye' : 'Total Balance';
  String get thisMonth => isTr ? 'Bu ay +%2.4' : '+2.4% this month';
  String get details => isTr ? 'Detaylar' : 'Details';
  String get send => isTr ? 'Gönder' : 'Send';
  String get request => isTr ? 'İste' : 'Request';
  String get pay => isTr ? 'Öde' : 'Pay';
  String get cards => isTr ? 'Kartlar' : 'Cards';
  String get monthlySpending => isTr ? 'Aylık Harcama' : 'Monthly Spending';
  String get budgetUsed => isTr ? "Aylık bütçenizin %62'si kullanıldı" : '62% of your monthly budget used';
  String get recentTransactions => isTr ? 'Son İşlemler' : 'Recent Transactions';
  String get seeAll => isTr ? 'Tümünü Gör' : 'See All';
  String get home => isTr ? 'Ana Sayfa' : 'Home';
  String get transfers => isTr ? 'Transferler' : 'Transfers';
  String get profile => isTr ? 'Profil' : 'Profile';
  String get sendMoney => isTr ? 'Para Gönder' : 'Send Money';
  String get sendTo => isTr ? 'KİME GÖNDERELİM' : 'SEND TO';
  String get newContact => isTr ? 'Yeni' : 'New';
  String get enterAmount => isTr ? 'Tutar girin' : 'Enter amount';
  String get balance => isTr ? 'Bakiye' : 'Balance';
  String get addNote => isTr ? 'Not ekle (isteğe bağlı)' : 'Add a note (optional)';
  String get payBills => isTr ? 'Fatura Öde' : 'Pay Bills';
  String get billCategories => isTr ? 'FATURA KATEGORİLERİ' : 'BILL CATEGORIES';
  String get electricity => isTr ? 'Elektrik' : 'Electricity';
  String get water => isTr ? 'Su' : 'Water';
  String get internet => isTr ? 'İnternet' : 'Internet';
  String get naturalGas => isTr ? 'Doğalgaz' : 'Natural Gas';
  String get phone => isTr ? 'Telefon' : 'Phone';
  String get subscriptions => isTr ? 'Abonelikler' : 'Subscriptions';
  String get payNow => isTr ? 'Şimdi Öde' : 'Pay Now';
  String get activity => isTr ? 'İşlem Geçmişi' : 'Activity';
  String get searchTransactions => isTr ? 'İşlem ara' : 'Search transactions';
  String get all => isTr ? 'Tümü' : 'All';
  String get income => isTr ? 'Gelir' : 'Income';
  String get expenses => isTr ? 'Gider' : 'Expenses';
  String get today => isTr ? 'Bugün' : 'Today';
  String get yesterday => isTr ? 'Dün' : 'Yesterday';
  String get sendButton => isTr ? 'Gönder' : 'Send';
  String get successMessage => isTr ? 'İşlem Başarılı!' : 'Transaction Successful!';
  String get successSubtitle => isTr ? 'İşleminiz alındı.' : 'Your transaction has been submitted.';
  String get backToHome => isTr ? 'Ana Sayfaya Dön' : 'Back to Home';
  String get billNo => isTr ? 'Fatura / Abone No.' : 'Bill / Subscriber No.';
  String get enterBillNo => isTr ? 'Fatura veya abone numarası girin' : 'Enter bill or subscriber number';
  String get amount => isTr ? 'Tutar' : 'Amount';
  String get dueDate => isTr ? 'Son Ödeme' : 'Due Date';
  String get pendingBills => isTr ? 'Bekleyen Faturalar' : 'Pending Bills';
  String get settings => isTr ? 'Ayarlar' : 'Settings';
  String get language => isTr ? 'Dil' : 'Language';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'tr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
