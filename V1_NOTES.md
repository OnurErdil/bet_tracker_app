# Bet Tracker App - V1 Notes

## V1 Durumu

V1 kullanılabilir sürüm hazır kabul edildi.

Son kontroller:

- flutter analyze: OK
- flutter test: OK
- V1 final manuel test akışı: OK

## V1'de Tamamlanan Ana Özellikler

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

## Test Edilen Ana Akışlar

- Boş veri kontrolü
- Kasa ve disiplin ayarları
- Bahis ekleme
- Güven puanı ve limitler
- Disiplin modları
- Bahis düzenleme
- Silme ve geri alma
- Bekleyen bahis hızlı sonuçlandırma
- History filtreleri
- Kasa hareketleri
- Statistics doğrulama
- Mobil / tablet görünüm
- Çıkış / giriş / Google giriş
- Şifre sıfırlama
- Final reset ve reset sonrası yeni kayıt

## V1 Sonrası Polish / V2 Notları

Bunlar kritik hata değildir, sonraki iyileştirme başlıklarıdır:

- Mobil UX turu
- 390–425 px genişliklerde Add/Edit ülke-lig seçimleri
- History mobil üst özet kartları
- Quick filter chip mobil dizilimi
- Ana sayfadaki bekleyen bahis kart yoğunluğu
- Snackbar renklerini tek merkeze bağlama
- Sadece Uyarı modunda limit uyarısı ile başarı mesajını birleştirme
- Bekleyen bahsi sonradan sonuçlandırmada günlük limit mantığını yeniden çerçeveleme
- Play Store hazırlığı
- App icon / splash screen
- API ile takım / lig verisi genişletme
- Riverpod geçişi ileride değerlendirilecek
- PRO / abonelik sistemi ileride değerlendirilecek