# Bet Tracker App - Project Recovery Notes

## 1. Projenin Amacı

Bet Tracker App, bahis önerisi veya kupon veren bir uygulama değildir. Ana amaç kullanıcının kendi bahislerini kaydetmesi, kasa yönetimi yapması, günlük kayıp limitini takip etmesi ve bahis disiplinini korumasıdır.

Temel konumlandırma:

- Kupon değil, kontrol.
- Bahis tahmini değil, kişisel performans takibi.
- Canlı skor / oran önerisi değil, kasa disiplini.
- Sorumlu oyun ve özdenetim odağı.

Bu çizgi korunmalı. Uygulama ileride büyüse bile “bahis öneri uygulaması”na dönüştürülmemeli.

---

## 2. Teknoloji ve Repo

Ana teknoloji:

- Flutter
- Dart
- Firebase Auth
- Google Sign-In
- Cloud Firestore
- Android Studio

GitHub repo:

```text
https://github.com/OnurErdil/bet_tracker_app
```

Repo içinde şu not dosyaları var veya olmalı:

```text
V1_NOTES.md
V2_PLAN.md
PROJECT_RECOVERY_NOTES.md
```

---

## 3. V1 Durumu

V1 kullanılabilir sürüm hazır kabul edildi.

Son kontroller:

```bash
flutter analyze
flutter test
```

Son bilinen durum:

```text
flutter analyze: OK
flutter test: OK
V1 final manuel test akışı: OK
```

V1 final manuel testte geçen ana akışlar:

- Boş veri kontrolü
- Kasa ve disiplin ayarları
- Bahis ekleme
- Güven puanı ve limitler
- Disiplin modları
- Bahis düzenleme
- Bahis silme ve geri alma
- Bekleyen bahis hızlı sonuçlandırma
- History filtreleri
- Kasa hareketleri
- Statistics doğrulama
- Mobil / tablet görünüm
- Çıkış / giriş / Google giriş
- Şifre sıfırlama
- Final reset ve reset sonrası yeni kayıt

---

## 4. V1’de Tamamlanan Ana Özellikler

Tamamlanan ana özellikler:

- Firebase Auth ile giriş / kayıt
- Google ile giriş
- Şifre sıfırlama
- Bahis ekleme
- Bahis düzenleme
- Bahis silme ve geri alma
- Bekleyen bahisleri hızlı sonuçlandırma
- Kazandı / Kaybetti / İade / Beklemede sonuç yönetimi
- Kasa hareketleri ekleme / düzenleme / silme
- Başlangıç kasası yönetimi
- Güncel kasa hesabı
- Maksimum bahis limiti
- Günlük kayıp limiti
- Disiplin modları:
  - Sadece Uyarı
  - Bahsi Engelle
  - Günü Kilitle
- Güven puanı sistemi
- Güven 9 / 10 için çarpanlı limit sistemi
- Bahis geçmişi arama ve gelişmiş filtreler
- Quick filter chipleri
- History üst özet kartları
- Statistics ekranı
- Genel tasarım dili
- Ortak spacing / radius / kart sistemi
- Domain / model / helper testleri

---

## 5. Önemli Teknik Düzeltmeler

### Firestore Security Rules

Başta sadece Flutter kodunda userId filtreleri vardı. Bu yeterli değildir.

Yapılan:

- Firestore Security Rules düzenlendi.
- Kullanıcı sadece kendi verisini okuyup yazabilir hale getirildi.

Ders:

```text
Firebase projelerinde güvenlik sadece client koduna bırakılmamalı.
Firestore Rules erken yapılmalı.
```

### Batch Delete Limiti

Firestore batch işlemlerinde 500 belge sınırı vardır.

Yapılan:

- Kullanıcı bahislerini toplu silme akışı sağlamlaştırıldı.
- Kasa hareketlerini toplu silme akışı sağlamlaştırıldı.
- Reset işlemleri batch limitine karşı daha güvenli hale getirildi.

Ders:

```text
Firestore’da toplu silme işlemleri 500 belge sınırı düşünülerek yazılmalı.
```

### ResetService

Yapılan:

- Bahisleri silme
- Kasa hareketlerini silme
- Başlangıç kasasını sıfırlama
- Disiplin ayarlarını varsayılana döndürme
- Reset sonrası yeni kayıt ekleme testi

Ders:

```text
Reset akışı ayrı ve kontrollü servis olarak kalmalı.
```

### BetCalculator

Net hesap kuralları netleştirildi:

```text
Kazandı:
payout = odd * stake
netProfit = payout - stake

Kaybetti:
payout = 0
netProfit = -stake

İade:
payout = stake
netProfit = 0

Beklemede:
payout = 0
netProfit = 0
```

Ders:

```text
İade bahis kazanç veya zarar değildir. Net etki sıfır olmalı.
```

### Confidence Score

Yapılan:

- confidenceScore 1–10 arasına clamp edildi.
- fromMap ve toMap güvenli hale getirildi.
- Yanlış/eski veri gelirse varsayılan değerlerle çalışması sağlandı.

Ders:

```text
Model katmanı yanlış veya eski veriye karşı savunmalı olmalı.
```

### createdAt Sıralama

Yapılan:

- Bahislerde createdAt desteği eklendi.
- Aynı gün içindeki bahis sıralaması daha doğru hale getirildi.

Ders:

```text
Sadece bahis tarihi yetmez. Oluşturulma zamanı da tutulmalı.
```

---

## 6. Tasarım Sistemi

V1’de genel tasarım dili toparlandı.

Kullanılan ortak yapılar:

- AppColors
- AppSpacing
- AppRadius
- AppStyles
- Ortak kartlar
- Ortak chip / badge yapıları
- Ortak button loading yapısı

Tamamlanan başlıklar:

- Genel tasarım dili
- Ortak spacing / radius / kart sistemi
- Ana sayfa modernizasyon
- Ortak widget/component düzeni
- Badge / chip / durum rengi standardı
- Statistics sadeleştirme
- Add/Edit form helper düzeni

Ders:

```text
Hardcoded renk, padding ve radius projeyi dağıtır.
Token sistemi erken kurulmalı.
```

---

## 7. Test Altyapısı

V1 sonunda küçük ama işe yarar test altyapısı kuruldu.

Test edilen alanlar:

- BetCalculator
- BankrollDisciplineCalculator
- BetModel
- BankrollTransaction
- BetFormHelpers

Firebase servis testlerine V1’de girilmedi. Bu bilinçli karardır.

Ders:

```text
Önce saf domain/model/helper testleri yazılmalı.
Firebase servis testleri sonraya bırakılabilir.
```

---

## 8. Gerçek Cihaz ve Mobil Test Notları

Ana mobil test cihazı:

```text
Vivo Y36
Yaklaşık genişlik: 393 px
```

Mobil genel durum V1 için kullanılabilir seviyede. Ancak V2.1’de mobil polish yapılmalı.

Yakalanan mobil polish konuları:

- AddBetPage:
  - Ülke / lig / ev sahibi / deplasman alanlarında uzun metin taşması
- EditBetPage:
  - Add ekranıyla aynı mobil taşma problemi
- HomePage:
  - Son bahis kartları mobilde kalabalık
  - Bekleyen bahis kartları mobilde kalabalık
  - Hızlı işlemler bölümü fazla büyük
  - FAB bazı kartlarla görsel olarak kalabalık hissettiriyor
- BetHistoryPage:
  - Üst özet kartları mobilde özel tasarım isteyebilir
  - Quick filter chip dizilimi daha iyi olabilir
- StatisticsPage:
  - Disiplin ayarları dialogunda uzun label kesilebiliyor
- BankrollPage:
  - Büyük tutarlarda işlem kartları sıkışıyor
  - Tutar chip’i mobilde taşmaya yakın
- Genel:
  - Snackbar renkleri tek merkeze bağlanmalı

Bu konular kritik V1 hatası değildir. V2.1 mobil UX polish işidir.

---

## 9. En Önemli Açık Hotfix

Gerçek Android cihazda Google ile girişte hata görüldü.

Hata:

```text
PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10)
```

Bu görsel polish değildir. V1 hotfix önceliğindedir.

Muhtemel nedenler:

- Firebase Android uygulamasına debug SHA-1 ekli değil.
- Firebase Android uygulamasına debug SHA-256 ekli değil.
- Package name uyuşmuyor.
- google-services.json eski.
- Yanlış Firebase projesinden google-services.json alınmış olabilir.

Çözüm sırası:

```bash
cd android
.\gradlew signingReport
```

Çıktıda debug için şunları bul:

```text
Variant: debug
SHA1:
SHA-256:
```

Sonra Firebase Console’da:

```text
Project Settings
Your apps
Android app
Add fingerprint
```

Debug SHA-1 ve SHA-256 ekle.

Sonra yeni google-services.json indir ve şuradaki dosyanın üstüne koy:

```text
android/app/google-services.json
```

Ardından:

```bash
flutter clean
flutter pub get
flutter run
```

Vivo Y36 gerçek cihazda Google ile giriş tekrar test edilmeli.

Ders:

```text
Google Sign-In Android’de ApiException 10 verirse ilk bakılacak yer SHA-1/SHA-256 ve google-services.json dosyasıdır.
```

---

## 10. Önemli Mantık Notu

Günlük kayıp limiti ve bekleyen bahis sonuçlandırma arasında ileride düzeltilmesi gereken mantık konusu var.

Mevcut durum:

- Limit aşan bir bahis “Sadece Uyarı” modunda beklemede eklenebiliyor.
- Sonradan bu bahis kaybettiye çevrilirse günlük kayıp limiti nedeniyle engellenebiliyor.
- Böylece bahis kazanmazsa beklemede kalma riski oluşuyor.

İleride doğru mantık:

- Yeni bahis ekleme limitlere takılabilir.
- Mevcut/bekleyen bahsin gerçek sonucunu kaydetme genelde engellenmemeli.
- Sonuç kaydedildikten sonra günlük limit aşılırsa:
  - Sadece Uyarı: uyarı göster
  - Bahsi Engelle: bundan sonraki yeni bahisleri engelle
  - Günü Kilitle: günü kilitle

Ders:

```text
Gerçek hayatta oynanmış bir bahsin sonucunu kaydetmek, yeni bahis oynamakla aynı kurala tabi tutulmamalı.
```

---

## 11. GitHub Durumu

Repo:

```text
https://github.com/OnurErdil/bet_tracker_app
```

GitHub’da görülen önemli commitler:

```text
Complete V1 final stabilization
Add V1 notes and V2 roadmap
```

Repo içinde şu dosyalar var:

```text
V1_NOTES.md
V2_PLAN.md
```

Kontrol edilmesi gereken konu:

```text
v1.0.0 tag atıldı mı belirsiz.
```

Atılmadıysa:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Ders:

```text
Çalışan sürüm commit ve tag ile mühürlenmeli.
```

---

## 12. V2 Yol Haritası

### Öncelik 1: Google Sign-In Hotfix

Gerçek cihazdaki ApiException 10 çözülmeli.

### Öncelik 2: Snackbar Sistemi

Yapılacaklar:

- showAppSnackBar() tek merkezden tema uyumlu hale getirilecek.
- Başarı / uyarı / hata / bilgi tonları olacak.
- Geri Al snackbar’ı özel kalacak.
- Limit uyarısı ve başarı mesajı birleştirilecek.
- Açık renk snackbar koyu tema ile uyumlu hale getirilecek.

### Öncelik 3: V2.1 Mobil UX Polish

Vivo Y36 / 393 px referans alınacak.

Yapılacaklar:

- Add/Edit mobil form taşmaları
- Home compact son bahis kartları
- Home compact bekleyen bahis kartları
- Home hızlı işlemler bölümü
- FAB yerleşimi
- History mobil üst özet kartları
- Quick filter chip dizilimi
- Bankroll mobil işlem kartları
- Statistics mobil dialog düzeni

### Öncelik 4: Günlük Limit ve Sonuçlandırma Mantığı

Yeni bahis ekleme ile mevcut bahsi sonuçlandırma ayrılacak.

### Öncelik 5: Play Store Hazırlığı

Yapılacaklar:

- Uygulama adı
- Package name kontrolü
- App icon
- Splash screen
- Android release build
- Firebase production ayarları
- Privacy policy
- Store açıklaması

### Öncelik 6: Takım / Lig Veri Genişletme

Yapılacaklar:

- Manuel takım/lig kataloğunu büyütme
- TheSportsDB gibi kaynakları araştırma
- Önce sadece takım/lig verisi
- Canlı skor ve pahalı API işleri sonraya

---

## 13. Şimdilik Yapılmayacaklar

V2 başında hemen yapılmayacaklar:

- Riverpod gerçek geçişi
- PRO / abonelik
- Canlı skor API
- Kombine bahis sistemi
- Büyük dashboard redesign
- Büyük Firestore model değişikliği

Bu işler notta duracak ama V2.1 polish ve hotfix tamamlanmadan başlanmayacak.

---

## 14. Bu Projede Alınan Dersler

### Ders 1

Önce çalışan V1 çıkarılmalı. Canlı skor, API, PRO, Play Store gibi büyük işler erken eklenmemeli.

### Ders 2

Mobil test cihazı erken belirlenmeli. Bu projede referans Vivo Y36 / 393 px.

### Ders 3

Firestore Rules en başta netleştirilmeli.

### Ders 4

Finansal hesaplama kuralları en başta yazılı olmalı.

### Ders 5

Snackbar ve genel mesaj sistemi tek merkezden yönetilmeli.

### Ders 6

Google Sign-In mutlaka gerçek Android cihazda test edilmeli.

### Ders 7

Kod değişikliklerinde küçük, kontrollü adımlar daha güvenli oldu. Büyük refactor yerine aşamalı ilerleme bu projede daha iyi sonuç verdi.

---

## 15. Yeni Sohbette Devam Promptu

Yeni bir sohbette devam edilecekse şu prompt kullanılabilir:

```text
Bu proje Flutter + Firebase tabanlı Bet Tracker App projesidir. GitHub repo: https://github.com/OnurErdil/bet_tracker_app

V1 final manuel test akışı tamamlandı. flutter analyze ve flutter test OK. V1 kullanılabilir sürüm hazır kabul edildi. Repo içinde V1_NOTES.md ve V2_PLAN.md var. Ayrıca PROJECT_RECOVERY_NOTES.md dosyası proje geçmişini ve devam yolunu özetliyor.

Şu an öncelik Vivo Y36 gerçek cihazda Google Sign-In ApiException 10 hatasını düzeltmek. Muhtemel çözüm Firebase’e debug SHA-1/SHA-256 eklemek, yeni google-services.json indirmek, flutter clean / flutter pub get / flutter run ile gerçek cihazda tekrar test etmek.

Google hotfix sonrası sıradaki işler: snackbar tema sistemi, V2.1 mobil UX polish, Add/Edit mobil taşmalar, Home compact kartlar, History mobil özet kartları, Quick filter dizilimi, Bankroll kartları, Statistics dialog düzeni.

Kod değişikliklerinde mümkünse eski blok + yeni blok formatı kullanılmalı. Büyük mimari kırılım yapılmamalı.
```

---

## 16. En Kısa Kurtarma Özeti

Bir şey bozulursa:

1. GitHub repo aç.
2. V1_NOTES.md, V2_PLAN.md, PROJECT_RECOVERY_NOTES.md dosyalarını oku.
3. Terminalde çalıştır:

```bash
flutter analyze
flutter test
```

4. İlk açık iş:
   Google Sign-In ApiException 10 hotfix.

5. Sonraki iş:
   Snackbar sistemi ve V2.1 mobil UX polish.

6. V1’e yeni büyük özellik ekleme.
   Önce hotfix ve polish tamamlanmalı.
