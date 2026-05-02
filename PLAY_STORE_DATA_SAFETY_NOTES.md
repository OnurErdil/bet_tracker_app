# Bet Tracker - Play Store Data Safety Notes

Son güncelleme: 01.05.2026

Bu dosya, Bet Tracker uygulamasını Google Play Console’a yüklerken Data Safety / Veri Güvenliği formunu doldurmak için hazırlık notudur.

Bu dosya hukuki belge değildir. Play Console’daki güncel seçeneklere göre son kontrol yapılmalıdır.

---

## 1. Uygulama Özeti

Uygulama adı: Bet Tracker  
Package name: com.bettracker.app  
İletişim: bettrackerapptr@gmail.com  
Privacy Policy: https://onurerdil.github.io/bet_tracker_app/PRIVACY_POLICY

Bet Tracker; bahis önerisi, kupon, canlı skor veya bahis tahmini sunmaz.

Uygulamanın amacı:

- Kullanıcının kendi bahis kayıtlarını tutması
- Kasa hareketlerini takip etmesi
- Günlük kayıp limiti ve maksimum bahis limiti belirlemesi
- Kendi performans istatistiklerini görmesi
- Bahis disiplinini koruması

---

## 2. Genel Data Safety Cevapları

| Alan | Cevap |
|---|---|
| Kullanıcı verisi toplanıyor mu? | Evet |
| Veri üçüncü taraflarla paylaşılıyor mu? | Hayır |
| Veriler aktarım sırasında şifreleniyor mu? | Evet |
| Kullanıcı verilerinin silinmesini talep edebilir mi? | Evet |
| Uygulamada hesap oluşturma var mı? | Evet |
| Reklam için veri kullanılıyor mu? | Hayır |
| Analitik / reklam SDK var mı? | Hayır |
| Uygulama içi ödeme var mı? | Hayır |
| Abonelik / PRO üyelik var mı? | Hayır |
| Konum verisi alınıyor mu? | Hayır |
| Rehber / kişiler alınıyor mu? | Hayır |
| Kamera / mikrofon alınıyor mu? | Hayır |
| Fotoğraf / dosya erişimi alınıyor mu? | Hayır |
| Canlı skor / bahis API verisi kullanılıyor mu? | Hayır |

---

## 3. Toplanan Veri Kategorileri

### Personal info

Muhtemel işaretlenecek veri:

- Email address

Kullanım amacı:

- Account management
- App functionality

Açıklama:

Kullanıcının e-posta adresi Firebase Authentication ile giriş/kayıt işlemleri için kullanılır.

---

### User IDs

Muhtemel işaretlenecek veri:

- User IDs

Kullanım amacı:

- Account management
- App functionality

Açıklama:

Firebase Authentication UID, kullanıcının kendi verilerini kendi hesabıyla eşleştirmek için kullanılır.

---

### App activity / App interactions / User-generated content

Play Console’daki seçeneklere göre dikkatli değerlendirilmelidir.

Uygulamada kullanıcı şunları kendisi girer:

- Bahis kayıtları
- Spor, ülke, lig ve takım bilgileri
- Bahis türü
- Oran
- Tutar
- Bahis sonucu
- Güven puanı
- Not alanı
- Kasa hareketleri
- Disiplin ayarları

Kullanım amacı:

- App functionality
- Analytics, sadece uygulama içi kişisel istatistik anlamında

Not:

Buradaki “analytics” reklam/izleme analitiği değildir. Kullanıcıya kendi bahis performansını göstermek için uygulama içinde hesaplanan kişisel istatistiklerdir.

---

### Financial info

Dikkatli karar verilecek alan.

Uygulama şunları ALMAZ:

- Banka hesabı
- Kredi kartı
- Ödeme bilgisi
- Maaş bilgisi
- Kredi skoru
- Gerçek finans kurumu verisi

Kullanıcı şunları kendisi girebilir:

- Kasa tutarı
- Bahis tutarı
- Para ekleme / para çekme kaydı

Eğer Play Console’da “other financial info” gibi geniş bir seçenek çıkarsa, kullanıcı tarafından girilen kasa/bahis tutarları nedeniyle işaretlemek gerekebilir.

Eğer seçenekler sadece banka/kart/ödeme bilgisi gibi gerçek finansal kimlik bilgilerini kapsıyorsa, Hayır denebilir.

Son karar Play Console’daki açıklama metnine göre verilecek.

---

## 4. Veri Paylaşımı

Cevap: Hayır.

Bet Tracker kullanıcı verilerini:

- Reklam şirketleriyle paylaşmaz
- Bahis şirketleriyle paylaşmaz
- Pazarlama şirketleriyle paylaşmaz
- Üçüncü taraf kupon/tahmin servisleriyle paylaşmaz

Firebase, uygulamanın altyapı sağlayıcısıdır. Auth ve Firestore hizmetleri uygulamanın çalışması için kullanılır.

---

## 5. Veri Güvenliği

Veriler Firebase / Google altyapısı üzerinden saklanır.

Beyan:

- Veriler aktarım sırasında şifrelenir: Evet
- Kullanıcı kendi hesabına bağlı verileri görür
- Firestore Security Rules ile kullanıcıların yalnızca kendi verilerine erişmesi hedeflenir

---

## 6. Veri Silme

Uygulama içinde:

- Kullanıcı uygulama içinden “Hesap ve Veri Silme Talebi” bağlantısı ile e-posta talebi oluşturabilir.
- E-posta adresi: bettrackerapptr@gmail.com
- Konu: Bet Tracker Hesap ve Veri Silme Talebi

Uygulama dışında:

- Privacy Policy içinde aynı iletişim e-postası yer alır.
- Kullanıcı dışarıdan e-posta göndererek hesap ve veri silme talebi oluşturabilir.

Not:

İleride tam otomatik Firebase hesap silme butonu eklenebilir. Şimdilik talep yoluyla silme süreci kullanılacak.

---

## 7. Kullanım Amaçları

Toplanan veriler şu amaçlarla kullanılır:

- Hesap oluşturma ve giriş
- Kullanıcı verilerini doğru hesaba bağlama
- Bahis kayıtlarını saklama
- Kasa hareketlerini saklama
- Disiplin ayarlarını saklama
- Günlük limit ve maksimum bahis kontrollerini hesaplama
- Kişisel performans istatistiklerini gösterme

Veriler şu amaçlarla kullanılmaz:

- Reklam hedefleme
- Kullanıcı profili satışı
- Bahis önerisi üretme
- Kupon satışı
- Üçüncü taraf bahis yönlendirmesi

---

## 8. Play Console’da Dikkat Edilecekler

Form doldururken şu tutarlılık korunmalı:

- Privacy Policy ile Data Safety cevapları çelişmemeli.
- Uygulama reklam göstermediği için reklam kullanımı seçilmemeli.
- Uygulama ödeme almadığı için ödeme verisi seçilmemeli.
- Kullanıcı tarafından girilen kasa/bahis tutarları nedeniyle Financial info alanı dikkatle okunmalı.
- Hesap oluşturma olduğu için Account deletion / Data deletion alanları doldurulmalı.
- Privacy Policy URL aktif ve herkese açık olmalı.

---

## 9. Şimdilik Net Cevap Özeti

- Collects user data: Yes
- Shares user data: No
- Data encrypted in transit: Yes
- Users can request data deletion: Yes
- Account creation: Yes
- Ads: No
- Payments: No
- Location: No
- Contacts: No
- Camera/Microphone: No
- Photos/Files: No