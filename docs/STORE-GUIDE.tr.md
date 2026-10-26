# CipherVault 2.0.1 — mağaza ve Linux yayını

## Dosyalar ve kimlikler

| Hedef | Yüklenecek dosya | Kimlik |
|---|---|---|
| Google Play | `CipherVault_2.0.1_play-store.aab` | `com.bulgan.ciphervault` |
| Microsoft Store | `CipherVault_2.0.1_x64-store.msix` | `EkremBulgan.CipherVaultDesktop` |
| Linux Debian/Ubuntu | `CipherVault_2.0.1_amd64.deb` | x86_64 / amd64 |
| Diğer Linux masaüstleri | `CipherVault_2.0.1_linux_x64.tar.gz` | x86_64; glibc 2.35+, GTK 3, libsecret |

Android sürümü: `2.0.1`, versionCode: `3`. MSIX sürümü: `2.0.1.0`. Windows ZIP dosyası taşınabilir kurulum içindir; MSIX ürününe ZIP yüklenmez. AAB telefona doğrudan kurulmaz; Play test kanalı üzerinden dağıtılır. `-android_arm64.apk` dosyası doğrudan kurulum içindir. Google Play imzası ile doğrudan dağıtım imzası farklı olabilir; kanallar arasında geçmeden önce şifreli yedek oluştur.

Mağaza metinleri: [STORE-LISTING.md](STORE-LISTING.md).

## Google Play

1. Play Console’da CipherVault ürününü aç. Paket adını değiştirme: `com.bulgan.ciphervault`.
2. Önce dahili test veya kapalı test sürümü oluştur; imzalı AAB dosyasını yükle. Play App Signing ayarını tamamla. Yükleme anahtarını ve parolalarını GitHub’a koyma, bu anahtarı gelecek sürümlerde koru.
3. Gizlilik politikası: https://github.com/idginity124/CipherVault/blob/main/PRIVACY.md
4. Destek: https://github.com/idginity124/CipherVault/issues
5. Uygulama türü: Uygulama. Uygun kategori: Araçlar. Reklam, uygulama içi satın alma ve geliştirici hesabına giriş yok. Arayüz şu an Türkçe; İngilizce mağaza açıklaması bunu belirtmeli.
6. İnceleme notu: Uygulama uzaktaki bir hesaba giriş istemez. İlk açılışta incelemeci kendi örnek ana parolasını (en az 12 karakter) oluşturarak boş kasayı açabilir. Gerçek kullanıcı parolası veya hesabı verilmez.
7. Veri güvenliği formunu son sürüme göre doldur: kayıtlar cihazda şifrelenir; kamera yalnızca QR taraması için kullanılır. Android sürümü İnternet izni içermez, uygulama analitik/reklam SDK’sı içermez. Dosya paylaşımı kullanıcının açık isteğiyle işletim sisteminin paylaşım ekranına gider. Google’ın güncel tanımlarını kontrol et; formdaki yanıtlar mağaza sorumluluğundadır.
8. Gerçek cihazda yeni kasa oluşturma, kilitleme, yeniden açılış, parola değiştirme, şifreli yedek geri yükleme ve QR aktarımını örnek kayıtlarla dene.

Yeni kişisel geliştirici hesaplarında üretim erişimi için en az 12 test kullanıcısının 14 gün kesintisiz katıldığı kapalı test şartı uygulanabilir. Ayrıntılar: https://support.google.com/googleplay/android-developer/answer/14151465

Mevcut hedef API 36’dır. AAB, Google bundletool doğrulamasından geçmiştir; 64-bit yerel kütüphaneler 16 KB uyumlu hizalamaya sahiptir ve paket `PAGE_ALIGNMENT_16K` ister. Bunlar fiziksel cihaz testinin yerine geçmez.

Kaynaklar: https://support.google.com/googleplay/android-developer/answer/11926878 ve https://developer.android.com/guide/practices/page-sizes

## Microsoft Store

Görünen mağaza adı: **CipherVault Desktop**.

- Identity/Name: `EkremBulgan.CipherVaultDesktop`
- Identity/Publisher: `CN=AA8BCA5B-124C-4770-90E7-C0618BC9398D`
- PublisherDisplayName: `Ekrem Bulgan`
- Store ID: `9PJ6218L3HBK`

Partner Center → CipherVault Desktop → Packages bölümüne `-store.msix` yükle. Microsoft Store kabul edilen paketi imzalar; gönderim dosyası normal imzasız yan yükleme paketi olarak kurulamaz. Paket hazırlamak, uygulamayı mağazaya göndermek veya onay almak değildir. Dağıtım için Windows 10/11 Desktop x64 seçilir.

`runFullTrust` açıklaması için:

> CipherVault Desktop is a Flutter Win32 desktop application. It requires runFullTrust to run its native Flutter host and plugins for user-selected file import/export, clipboard operations and local encrypted vault storage. Vault records are encrypted on the device. The application does not require administrator privileges, install drivers or install a Windows service. It does not provide an account server or automatic cloud synchronization.

Gizlilik URL’si ve destek bağlantısı Google Play ile aynıdır. Kategori olarak Productivity veya Utilities + tools kullanılabilir. Uygulama parola üretmek için kriptografik rastgelelik kullanır; üretken yapay zekâ özelliği yoktur. Mağaza açıklamalarını, yaş derecelendirmesini ve gerçek uygulama ekran görüntülerini tamamla. Windows App Certification Kit ve gerçek Windows kullanım testini gönderimden önce yap.

Kaynak: https://docs.flutter.dev/deployment/windows

## Linux

```bash
# Debian / Ubuntu
sudo apt install ./CipherVault_2.0.1_amd64.deb

# Taşınabilir paket
tar -xzf CipherVault_2.0.1_linux_x64.tar.gz
cd CipherVault-2.0.1-linux-x64
./ciphervault
```

Taşınabilir pakette `lib/` ve `data/` klasörlerini çalıştırılabilir dosyanın yanında tut. Sistem GTK 3, libsecret ve masaüstü GSettings şemalarını sağlamalıdır. Paket Ubuntu 22.04 tabanında yerel olarak üretildi; glibc gereksinimleri denetlendi. Her dağıtımda sertifikasyon yapıldığı anlamına gelmez.

## Yeniden üretme

- Android: `flutter build appbundle --release` (yerel imzalama ayarları gerekir).
- Windows: Windows ortamında `./scripts/package-windows.ps1`; aynı işlem yalnızca elle başlatılan `Windows package (manual)` GitHub Actions işinde vardır. Push/PR olayları derleme başlatmaz.
- Linux: Ubuntu 22.04 tabanında `flutter build linux --release`, ardından `python3 scripts/package-linux.py`. Betik eski sürüm paketi ve glibc 2.35’ten yeni semboller gerektiren çıktıyı reddeder.

Bu sürüm geliştirme önizlemesidir; bağımsız güvenlik denetiminden geçtiği iddia edilmez.

## Mağaza görselleri

Paket klasöründeki `store/` bölümünde 512×512 simge, 1024×500 Türkçe/İngilizce tanıtım görselleri ve örnek verilerle oluşturulan masaüstü/mobil Flutter arayüz önizlemeleri bulunur. Bunlar ortak uygulama bileşenlerinden üretilmiştir; gerçek hedef cihazdaki son görünümü ve çalışmayı gönderim öncesinde kontrol et.
