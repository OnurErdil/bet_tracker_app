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

Repo içinde şu not dosyaları var veya olmalı:

V1_NOTES.md
V2_PLAN.md
PROJECT_RECOVERY_NOTES.md

V1 kullanılabilir sürüm hazır kabul edildi.

Son kontroller:

flutter analyze
flutter test

Son bilinen durum:

flutter analyze: OK
flutter test: OK
V1 final manuel test akışı: OK

V1 final manuel testte geçen ana akışlar:


Tamamlanan ana özellikler:


Başta sadece Flutter kodunda userId filtreleri vardı. Bu yeterli değildir.

Yapılan:


Ders:

Firebase projelerinde güvenlik sadece client koduna bırakılmamalı.
Firestore Rules erken yapılmalı.

Firestore batch işlemlerinde 500 belge sınırı vardır.

Yapılan:


Ders:

Firestore’da toplu silme işlemleri 500 belge sınırı düşünülerek yazılmalı.

Yapılan:


Ders:

Reset akışı ayrı ve kontrollü servis olarak kalmalı.

Net hesap kuralları netleştirildi:

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

Ders:

İade bahis kazanç veya zarar değildir. Net etki sıfır olmalı.

Yapılan:


Ders:

Model katmanı yanlış veya eski veriye karşı savunmalı olmalı.

Yapılan:


Ders:

Sadece bahis tarihi yetmez. Oluşturulma zamanı da tutulmalı.

V1’de genel tasarım dili toparlandı.

Kullanılan ortak yapılar:


Tamamlanan başlıklar:


Ders:

Hardcoded renk, padding ve radius projeyi dağıtır.
Token sistemi erken kurulmalı.

V1 sonunda küçük ama işe yarar test altyapısı kuruldu.

Test edilen alanlar:


Firebase servis testlerine V1’de girilmedi. Bu bilinçli karardır.

Ders:

Önce saf domain/model/helper testleri yazılmalı.
Firebase servis testleri sonraya bırakılabilir.

Ana mobil test cihazı:

Vivo Y36
Yaklaşık genişlik: 393 px

Mobil genel durum V1 için kullanılabilir seviyede. Ancak V2.1’de mobil polish yapılmalı.

Yakalanan mobil polish konuları:


Bu konular kritik V1 hatası değildir. V2.1 mobil UX polish işidir.


Gerçek Android cihazda Google ile girişte hata görüldü.

Hata:

PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10)

Bu görsel polish değildir. V1 hotfix önceliğindedir.

Muhtemel nedenler:


Çözüm sırası:

cd android
.\gradlew signingReport

Çıktıda debug için şunları bul:

Variant: debug
SHA1:
SHA-256:

Sonra Firebase Console’da:

Project Settings
Your apps
Android app
Add fingerprint

Debug SHA-1 ve SHA-256 ekle.

Sonra yeni google-services.json indir ve şuradaki dosyanın üstüne koy:

android/app/google-services.json

Ardından:

flutter clean
flutter pub get
flutter run

Vivo Y36 gerçek cihazda Google ile giriş tekrar test edilmeli.

Ders:

Google Sign-In Android’de ApiException 10 verirse ilk bakılacak yer SHA-1/SHA-256 ve google-services.json dosyasıdır.

Günlük kayıp limiti ve bekleyen bahis sonuçlandırma arasında ileride düzeltilmesi gereken mantık konusu var.

Mevcut durum:


İleride doğru mantık:


Ders:

Gerçek hayatta oynanmış bir bahsin sonucunu kaydetmek, yeni bahis oynamakla aynı kurala tabi tutulmamalı.

Repo:

https://github.com/OnurErdil/bet_tracker_app

GitHub’da görülen önemli commitler:

Complete V1 final stabilization
Add V1 notes and V2 roadmap

Repo içinde şu dosyalar var:

V1_NOTES.md
V2_PLAN.md

Kontrol edilmesi gereken konu:

v1.0.0 tag atıldı mı belirsiz.

Atılmadıysa:

git tag v1.0.0
git push origin v1.0.0

Ders:

Çalışan sürüm commit ve tag ile mühürlenmeli.

Gerçek cihazdaki ApiException 10 çözülmeli.


Yapılacaklar:


Vivo Y36 / 393 px referans alınacak.

Yapılacaklar:


Yeni bahis ekleme ile mevcut bahsi sonuçlandırma ayrılacak.


Yapılacaklar:


Yapılacaklar:


V2 başında hemen yapılmayacaklar:


Bu işler notta duracak ama V2.1 polish ve hotfix tamamlanmadan başlanmayacak.


Önce çalışan V1 çıkarılmalı. Canlı skor, API, PRO, Play Store gibi büyük işler erken eklenmemeli.


Mobil test cihazı erken belirlenmeli. Bu projede referans Vivo Y36 / 393 px.


Firestore Rules en başta netleştirilmeli.


Finansal hesaplama kuralları en başta yazılı olmalı.


Snackbar ve genel mesaj sistemi tek merkezden yönetilmeli.


Google Sign-In mutlaka gerçek Android cihazda test edilmeli.


Kod değişikliklerinde küçük, kontrollü adımlar daha güvenli oldu. Büyük refactor yerine aşamalı ilerleme bu projede daha iyi sonuç verdi.


Yeni bir sohbette devam edilecekse şu prompt kullanılabilir:

Bu proje Flutter + Firebase tabanlı Bet Tracker App projesidir. GitHub repo: https://github.com/OnurErdil/bet_tracker_app

V1 final manuel test akışı tamamlandı. flutter analyze ve flutter test OK. V1 kullanılabilir sürüm hazır kabul edildi. Repo içinde V1_NOTES.md ve V2_PLAN.md var. Ayrıca PROJECT_RECOVERY_NOTES.md dosyası proje geçmişini ve devam yolunu özetliyor.

Şu an öncelik Vivo Y36 gerçek cihazda Google Sign-In ApiException 10 hatasını düzeltmek. Muhtemel çözüm Firebase’e debug SHA-1/SHA-256 eklemek, yeni google-services.json indirmek, flutter clean / flutter pub get / flutter run ile gerçek cihazda tekrar test etmek.

Google hotfix sonrası sıradaki işler: snackbar tema sistemi, V2.1 mobil UX polish, Add/Edit mobil taşmalar, Home compact kartlar, History mobil özet kartları, Quick filter dizilimi, Bankroll kartları, Statistics dialog düzeni.

Kod değişikliklerinde mümkünse eski blok + yeni blok formatı kullanılmalı. Büyük mimari kırılım yapılmamalı.

Bir şey bozulursa:

flutter analyze
flutter test
Google Sign-In ApiException 10 hotfix.
Snackbar sistemi ve V2.1 mobil UX polish.
Önce hotfix ve polish tamamlanmalı.
