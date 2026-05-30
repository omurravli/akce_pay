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
  String get budgetUsed =>
      isTr ? "Aylık bütçenizin %62'si kullanıldı" : '62% of your monthly budget used';
  String get recentTransactions =>
      isTr ? 'Son İşlemler' : 'Recent Transactions';
  String get seeAll => isTr ? 'Tümünü Gör' : 'See All';
  String get home => isTr ? 'Ana Sayfa' : 'Home';
  String get transfers => isTr ? 'Transferler' : 'Transfers';
  String get profile => isTr ? 'Profil' : 'Profile';
  String get sendMoney => isTr ? 'Para Gönder' : 'Send Money';
  String get sendTo => isTr ? 'KİME GÖNDERELİM' : 'SEND TO';
  String get newContact => isTr ? 'Yeni' : 'New';
  String get enterAmount => isTr ? 'Tutar girin' : 'Enter amount';
  String get balance => isTr ? 'Bakiye' : 'Balance';
  String get addNote =>
      isTr ? 'Not ekle (isteğe bağlı)' : 'Add a note (optional)';
  String get payBills => isTr ? 'Fatura Öde' : 'Pay Bills';
  String get billCategories =>
      isTr ? 'FATURA KATEGORİLERİ' : 'BILL CATEGORIES';
  String get electricity => isTr ? 'Elektrik' : 'Electricity';
  String get water => isTr ? 'Su' : 'Water';
  String get internet => isTr ? 'İnternet' : 'Internet';
  String get naturalGas => isTr ? 'Doğalgaz' : 'Natural Gas';
  String get phone => isTr ? 'Telefon' : 'Phone';
  String get subscriptions => isTr ? 'Abonelikler' : 'Subscriptions';
  String get payNow => isTr ? 'Şimdi Öde' : 'Pay Now';
  String get activity => isTr ? 'İşlem Geçmişi' : 'Activity';
  String get searchTransactions =>
      isTr ? 'İşlem ara' : 'Search transactions';
  String get all => isTr ? 'Tümü' : 'All';
  String get income => isTr ? 'Gelir' : 'Income';
  String get expenses => isTr ? 'Gider' : 'Expenses';
  String get today => isTr ? 'Bugün' : 'Today';
  String get yesterday => isTr ? 'Dün' : 'Yesterday';
  String get sendButton => isTr ? 'Gönder' : 'Send';
  String get successMessage =>
      isTr ? 'İşlem Başarılı!' : 'Transaction Successful!';
  String get successSubtitle =>
      isTr ? 'İşleminiz alındı.' : 'Your transaction has been submitted.';
  String get backToHome => isTr ? 'Ana Sayfaya Dön' : 'Back to Home';
  String get billNo => isTr ? 'Fatura / Abone No.' : 'Bill / Subscriber No.';
  String get enterBillNo =>
      isTr ? 'Fatura veya abone numarası girin' : 'Enter bill or subscriber number';
  String get amount => isTr ? 'Tutar' : 'Amount';
  String get dueDate => isTr ? 'Son Ödeme' : 'Due Date';
  String get pendingBills => isTr ? 'Bekleyen Faturalar' : 'Pending Bills';
  String get settings => isTr ? 'Ayarlar' : 'Settings';
  String get language => isTr ? 'Dil' : 'Language';
  String get pleaseFillAllFields =>
      isTr ? 'Lütfen tüm alanları doldurun' : 'Please fill in all fields';
  String get loginFailed =>
      isTr ? 'Giriş başarısız. Email veya şifre hatalı.' : 'Login failed. Email or password is incorrect.';
  String get registerSuccess =>
      isTr ? 'Kayıt başarılı! Giriş yapabilirsiniz.' : 'Registration successful! You can now sign in.';
  String get registerFailed =>
      isTr ? 'Kayıt başarısız. Bilgileri kontrol edin.' : 'Registration failed. Please check your information.';
  String get joinAkcePay =>
      isTr ? 'Akçe Pay dünyasına katılmak için bilgileri doldur.' : 'Fill in your details to join Akce Pay.';
  String get fullName => isTr ? 'Ad Soyad' : 'Full Name';
  String get requiredField => isTr ? 'Zorunlu alan' : 'Required field';
  String get validEmail => isTr ? 'Geçerli bir email girin' : 'Enter a valid email';
  String get phoneNumber => isTr ? 'Telefon Numarası' : 'Phone Number';
  String get age => isTr ? 'Yaş' : 'Age';
  String get minimumSixChars =>
      isTr ? 'En az 6 karakter' : 'At least 6 characters';
  String get noAccountQuestion =>
      isTr ? 'Hesabınız yok mu? ' : "Don't have an account? ";
  String get signUpNow =>
      isTr ? 'Hemen Kayıt Ol' : 'Sign Up Now';
  String get demoLoginFailed =>
      isTr ? 'Demo hesaba giriş yapılamadı.' : 'Demo account sign-in failed.';
  String get walletNotFoundTitle =>
      isTr ? 'Cüzdan Bulunamadı' : 'Wallet Not Found';
  String get walletNotFoundDescription => isTr
      ? 'Para yüklemek için aktif bir banka hesabınız/cüzdanınız bulunmuyor. Lütfen önce bir cüzdan oluşturun.'
      : 'There is no active bank account or wallet available for loading money. Please create a wallet first.';
  String get close => isTr ? 'Kapat' : 'Close';
  String get loadMoney => isTr ? 'Para Yükle' : 'Load Money';
  String get selectAccount => isTr ? 'Hesap Seçin' : 'Select Account';
  String get amountTry => isTr ? 'Tutar (₺)' : 'Amount (₺)';
  String get cancel => isTr ? 'İptal' : 'Cancel';
  String get balanceLoaded =>
      isTr ? 'Bakiye yüklendi' : 'Balance loaded';
  String get operationSuccessful =>
      isTr ? 'İşlem başarılı' : 'Operation successful';
  String get operationFailed =>
      isTr ? 'İşlem başarısız' : 'Operation failed';
  String get upload => isTr ? 'Yükle' : 'Load';
  String get textSize => isTr ? 'Yazı Boyutu' : 'Text Size';
  String get logout => isTr ? 'Çıkış Yap' : 'Log Out';
  String get primaryAccount => isTr ? 'Ana Hesap' : 'Primary Account';
  String get foreignCurrencyAccount =>
      isTr ? 'Döviz Hesabı' : 'Foreign Currency Account';
  String get akceCard => 'Akçe Card';
  String get noSpendingYet =>
      isTr ? 'Henüz harcama yok.' : 'No spending yet.';
  String get noTransactionHistory =>
      isTr ? 'Henüz işlem geçmişi yok.' : 'No transaction history yet.';
  String get noDemoTransactionHistory => isTr
      ? 'Bu demo hesapta henüz işlem geçmişi yok.'
      : 'This demo account has no transaction history yet.';
  String get recipientLabel => isTr ? 'Alıcı' : 'Recipient';
  String get billLabel => isTr ? 'Fatura' : 'Bill';
  String get date => isTr ? 'Tarih' : 'Date';
  String get referenceNo => isTr ? 'Ref No' : 'Ref No';
  String get transferFailed =>
      isTr ? 'Transfer başarısız. Bakiye yetersiz olabilir.' : 'Transfer failed. Balance may be insufficient.';
  String get pendingBillsCount =>
      isTr ? '3 fatura ödeme bekliyor' : '3 bills are awaiting payment';
  String get demoUserName => isTr ? 'Demo Kullanici' : 'Demo User';

  // === Chatbot ===
  String get akceChat => 'AkçeChat';
  String get chatWelcome => isTr ? 'Merhaba! Ben AkçeChat. Size nasıl yardımcı olabilirim?' : 'Hello! I am AkçeChat. How can I help you?';
  String get chatHint => isTr ? 'Bir şeyler yazın veya seçin...' : 'Type something or choose...';
  String get chatGoToMarket => isTr ? 'Borsaya git' : 'Go to market';
  String get chatGoToTransfer => isTr ? 'Para gönder' : 'Send money';
  String get chatGoToBills => isTr ? 'Fatura öde' : 'Pay bills';
  String get chatGoToPortfolio => isTr ? 'Portföyüme bak' : 'Check my portfolio';
  String get chatGoToActivity => isTr ? 'Hesap hareketleri' : 'Account activity';
  String get chatUnknown => isTr ? 'Sizi anlayamadım, lütfen aşağıdaki seçeneklerden birini seçin.' : 'I couldn''t understand you, please choose one of the options below.';
  String chatDidYouMean(String label) => isTr ? '\"$label\" mi demek istediniz?' : 'Did you mean \"$label\"?';

  // === Haberler / News ===
  String get news => isTr ? 'Haberler' : 'News';
  String get readMore => isTr ? 'Devamını Oku' : 'Read More';
  String get chatGoToNews => isTr ? 'Haberleri gör' : 'See news';

  // === Yeni: Piyasalar / Trading ===
  String get market => isTr ? 'Piyasalar' : 'Markets';
  String get tradeBuySell => isTr ? 'Al / Sat' : 'Buy / Sell';
  String get buy => isTr ? 'Al' : 'Buy';
  String get sell => isTr ? 'Sat' : 'Sell';
  String get gold => isTr ? 'Altın' : 'Gold';
  String get silver => isTr ? 'Gümüş' : 'Silver';
  String get usd => isTr ? 'Dolar' : 'USD';
  String get eur => isTr ? 'Euro' : 'EUR';
  String get buyPrice => isTr ? 'Alış' : 'Buy';
  String get sellPrice => isTr ? 'Satış' : 'Sell';
  String get change24h => isTr ? '24s Değişim' : '24h Change';
  String get marketSubtitle => isTr
      ? 'Anlık altın, gümüş ve döviz kurları'
      : 'Live gold, silver and currency rates';
  String get tradeConfirm =>
      isTr ? 'İşlemi Onayla' : 'Confirm Transaction';
  String get tradeBuyTitle =>
      isTr ? 'Varlık Satın Al' : 'Buy Asset';
  String get tradeSellTitle =>
      isTr ? 'Varlık Sat' : 'Sell Asset';
  String get tradeAmountTl =>
      isTr ? 'Harcanacak TL Tutarı' : 'TL Amount to spend';
  String get tradeQuantity => isTr ? 'Miktar' : 'Quantity';
  String get tradeBuySuccess =>
      isTr ? 'Alış işlemi başarılı.' : 'Purchase successful.';
  String get tradeSellSuccess =>
      isTr ? 'Satış işlemi başarılı.' : 'Sale successful.';
  String get tradeFailed =>
      isTr ? 'İşlem başarısız. Bakiye/miktar kontrol edin.' : 'Transaction failed.';

  // === Yeni: Portföy ===
  String get portfolio => isTr ? 'Portföy' : 'Portfolio';
  String get portfolioValue =>
      isTr ? 'Portföy Değeri' : 'Portfolio Value';
  String get profitLoss => isTr ? 'Kâr / Zarar' : 'Profit / Loss';
  String get holdings => isTr ? 'Varlıklarım' : 'Holdings';
  String get avgCost =>
      isTr ? 'Ortalama Maliyet' : 'Average Cost';
  String get currentPrice => isTr ? 'Güncel Fiyat' : 'Current Price';
  String get noHoldings =>
      isTr ? 'Henüz varlığınız yok' : 'No holdings yet';
  String get startTrading =>
      isTr ? 'Al/Sat sayfasından başlayabilirsiniz' : 'Start from Buy/Sell';
  String get allocation => isTr ? 'Dağılım' : 'Allocation';

  // === Yeni: Cashback ===
  String get cashback => isTr ? 'Cashback' : 'Cashback';
  String get cashbackBalance =>
      isTr ? 'Cashback Bakiyesi' : 'Cashback Balance';
  String get cashbackHistory =>
      isTr ? 'Cashback Geçmişi' : 'Cashback History';
  String get cashbackHowItWorks =>
      isTr ? 'Nasıl Çalışır?' : 'How it works';
  String get cashbackRates =>
      isTr ? 'Kazanım Oranları' : 'Earning Rates';
  String get withdrawToWallet =>
      isTr ? 'Cüzdana Aktar' : 'Withdraw to Wallet';
  String get cashbackWithdrawSuccess => isTr
      ? 'Cashback bakiyesi cüzdana aktarıldı.'
      : 'Cashback balance moved to wallet.';
  String get cashbackEmpty =>
      isTr ? 'Henüz cashback kazanmadınız.' : 'No cashback earned yet.';
  String get categoryShopping => isTr ? 'Alışveriş' : 'Shopping';
  String get categoryBills => isTr ? 'Faturalar' : 'Bills';
  String get categoryTransfer => isTr ? 'Transfer' : 'Transfer';
  String get categoryTrade => isTr ? 'Yatırım' : 'Trade';

  // === Yeni: Admin Panel ===
  String get adminPanel => isTr ? 'Admin Paneli' : 'Admin Panel';
  String get adminStats => isTr ? 'İstatistikler' : 'Statistics';
  String get totalUsers => isTr ? 'Toplam Kullanıcı' : 'Total Users';
  String get activeUsers => isTr ? 'Aktif Kullanıcı' : 'Active Users';
  String get totalVolume => isTr ? 'Toplam Hacim' : 'Total Volume';
  String get totalTransactions => isTr ? 'Toplam İşlem' : 'Total Transactions';
  String get totalCashbackPaid =>
      isTr ? 'Ödenen Cashback' : 'Total Cashback Paid';
  String get usersList => isTr ? 'Kullanıcılar' : 'Users';
  String get suspend => isTr ? 'Askıya Al' : 'Suspend';
  String get activate => isTr ? 'Aktif Et' : 'Activate';

  // === Demo hesap ===
  String get useDemoAccount =>
      isTr ? 'Demo Hesap ile Devam Et' : 'Continue with Demo Account';
  String get demoHint => isTr
      ? 'Auth bypass ile bos bir hesap acilir. Para, gecmis ve portfoy sifirdan baslar.'
      : 'Opens an empty account with auth bypass. Balance, history, and portfolio start from zero.';
  String get demoBanner => isTr
      ? 'DEMO MOD - Auth bypass aktif. Veriler bu cihazda lokal test icin calisiyor.'
      : 'DEMO MODE - Auth bypass is active. Data runs locally on this device for testing.';
  String checkingAccount(String currency) =>
      isTr ? 'Vadesiz $currency' : 'Checking $currency';
  String assetName(String symbol, [String? fallback]) {
    switch (symbol) {
      case 'GOLD_GR':
        return isTr ? 'Gram Altın' : 'Gram Gold';
      case 'SILVER_GR':
        return isTr ? 'Gümüş (gr)' : 'Silver (gr)';
      case 'USD':
        return isTr ? 'Dolar' : 'USD';
      case 'EUR':
        return isTr ? 'Euro' : 'EUR';
      default:
        return fallback ?? symbol;
    }
  }

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
