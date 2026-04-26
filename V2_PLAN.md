# Bet Tracker App - V2 Plan

## V2 Başlangıç Durumu

V1 kullanılabilir sürüm hazır kabul edildi.

Son V1 kontrolleri:

- flutter analyze: OK
- flutter test: OK
- V1 final manuel test akışı: OK

V2'nin amacı büyük mimari kırılım yapmak değil; önce V1 üzerinde polish, mobil UX ve kullanım mantığı iyileştirmeleri yapmaktır.

---

## V2.1 Mobil UX Polish

Öncelik: Dar ekranlarda daha temiz kullanım.

Hedefler:

- 390–425 px genişliklerde Add/Edit ülke-lig seçimlerini iyileştirmek
- History üst özet kartlarını mobil için daha özel tasarlamak
- Quick filter chip dizilimini mobilde daha düzenli hale getirmek
- Ana sayfadaki bekleyen bahis kartlarını biraz daha kompakt yapmak
- Form ekranlarında mobil spacing yoğunluğunu azaltmak

Not:
Bu başlık V1 için kritik hata değildir. V2 polish işidir.

---

## V2.2 Snackbar ve Mesaj Sistemi

Hedefler:

- showAppSnackBar fonksiyonunu tek merkezden tema uyumlu hale getirmek
- Başarı, uyarı, hata ve bilgi mesajları için ton sistemi kullanmak
- Geri Al snackbar yapısını korumak
- Sadece Uyarı modunda limit uyarısı ile başarı mesajını birleştirmek
- Snackbar sürelerini daha tutarlı hale getirmek

---

## V2.3 Günlük Limit ve Bahis Sonuçlandırma Mantığı

Mevcut V1 notu:

Limit aşan bir bahis Sadece Uyarı modunda beklemede eklenebiliyor.
Ancak sonradan kaybettiye çevrilirse günlük kayıp limiti nedeniyle engellenebiliyor.
Bu durumda bahis kazanmazsa beklemede kalma riski oluşuyor.

V2 hedefi:

- Yeni bahis ekleme limitlerle engellenebilir
- Mevcut/bekleyen bahsin gerçek sonucunu kaydetme genelde engellenmemeli
- Sonuç kaydedildikten sonra günlük limit aşılırsa:
    - warning: uyarı göster
    - block_bet: yeni bahisleri engelle
    - lock_day: günü kilitle

---

## V2.4 Play Store Hazırlığı

Hedefler:

- Uygulama adı kontrolü
- Paket adı kontrolü
- App icon
- Splash screen
- Android release build
- Firebase production ayar kontrolü
- Privacy policy ihtiyacı
- Store açıklama metni

---

## V2.5 Takım / Lig Veri Genişletme

Hedefler:

- Mevcut manuel takım ve lig kataloğunu büyütmek
- TheSportsDB gibi kaynaklardan sadece takım/lig verisi çekme ihtimalini araştırmak
- Live score ve pahalı API işlerine hemen girmemek
- Futbol öncelikli ilerlemek

---

## Şimdilik V2'de Hemen Yapılmayacaklar

- Riverpod gerçek geçişi
- PRO / abonelik sistemi
- Canlı skor API
- Kombine bahis sistemi
- Büyük dashboard redesign
- Büyük Firestore model değişikliği

---

## İlk Uygulama Sırası

1. V1_NOTES.md ve V2_PLAN.md dosyalarını ekle
2. GitHub final commit + v1.0.0 tag
3. V2.1 Mobil UX polish
4. V2.2 Snackbar sistemi
5. V2.3 Günlük limit / sonuçlandırma mantığı
6. V2.4 Play Store hazırlığı