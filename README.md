<p align="center">
  <img src="gorsel/paylasim/kapak-tr-en-1200x675.jpg" alt="SQL Server Query Store Başucu Rehberi ve İngilizce baskısı Handbook, kapaklar" width="100%">
</p>

# SQL Server Query Store Başucu Rehberi, betikler ve ölçümler

[English README](README.en.md)

[![Ölçülen sürümler](https://img.shields.io/badge/%C3%96l%C3%A7%C3%BClen%20s%C3%BCr%C3%BCmler-SQL%20Server%202019%20%7C%202022%20%7C%202025-blue.svg)](#ölçüm-matrisi)
[![PDF Türkçe](https://img.shields.io/badge/PDF-T%C3%BCrk%C3%A7e%2C%20196%20sayfa-red.svg)](https://github.com/dmcteknoloji/sql-server-query-store-basucu-rehberi/releases/download/v2.1/DMC-SQL-Server-Query-Store-Basucu-Rehberi-v2.1.pdf)
[![PDF English](https://img.shields.io/badge/PDF-English%2C%20215%20pages-red.svg)](https://github.com/dmcteknoloji/sql-server-query-store-basucu-rehberi/releases/download/v2.1/DMC-SQL-Server-Query-Store-Handbook-v2.1.pdf)

Bu depo, DMC Bilgi Teknolojileri'nin ücretsiz **SQL Server Query Store Başucu Rehberi** (196 sayfa) kitabının betiklerini ve ham ölçüm çıktılarını içerir. Kitabı okurken bir ölçümün nasıl yapıldığını merak ederseniz ya da bir betiği kendi sunucunuzda denemek isterseniz buradan alabilirsiniz.

Kitap SQL Server 2019, 2022 ve 2025 üzerinde, Azure'daki Windows Server sanal makinelerinde ölçüldü. Forced plan davranışı, OPPO, automatic plan correction, eşzamanlı yük testi ve iki düğümlü Availability Group denemeleri yalnızca SQL Server 2025 makinelerinde, otomatik parametrelendirme ve PSP olayları SQL Server 2022 CU25 ile 2025'te ölçüldü. Ölçemediğimiz yerler (SQL Server 2016 ve 2017, Linux, cluster'lı Availability Group, Standard edition, Azure SQL, tek tek cumulative update'ler) kitapta ve burada açıkça belirtilir.

Kitabın Türkçe ve İngilizce PDF'leri [Releases](../../releases) bölümündedir. İngilizce dosya `DMC-SQL-Server-Query-Store-Handbook-v2.1.pdf` adını taşır.

## Öne çıkan bulgular

Aşağıdaki sayılar kitaptaki ölçümlerden alındı. Her birinin koşulu yanında yazılıdır, koşulu bilmeden başka ortama taşımayın.

| Bulgu | Koşul | Kitapta |
|---|---|---|
| Her seferinde farklı sabit değerli ad hoc yükte `ALL` modu yaklaşık yüzde 60 yavaşladı, `AUTO` modunda fark çıkmadı | 8 eşzamanlı oturum, SQL Server 2025, tekrarlar arası dalgalanma geniş (71,9 ile 112,2 saniye) | Bölüm 6 |
| PSP, histogramdaki en yüksek ve en düşük `EQUAL_ROWS` oranı 100.000 olduğunda devreye girdi, 99.999'da girmedi | Tek kolonlu eşitlik koşulu, SQL Server 2022 CU25 ve 2025 RTM | Bölüm 9 |
| SQL Server 2025 RTM'de `parameter_sensitive_plan_optimization` olayı gelmedi, yerine `multiplan_dispatcher_plan_compiled` ve `multiplan_query_variant_plan_compiled` geldi | Aynı lab, iki sürüm karşılaştırması | Bölüm 9 |
| 24 query'nin yalnızca 5'i simple parameterization ile parametrelendi, planı trivial olan üçü (`TOP`, `DISTINCT`, `IN` listesi) parametrelenmedi | SQL Server 2022 CU25 ve 2025 RTM, aynı sonuç | Bölüm 9 |
| Flush sırasında kalıcı hale gelen her yeni query için yaklaşık 5,3 işlem, 3 log boşaltması ve 14 KB log yazıldı | 43.056 query, 178 saniyelik flush, SQL Server 2025 RTM | Bölüm 6 |
| `AUTO` capture mode 300 tek seferlik query'nin hiçbirini yakalamadı, `ALL` modu 300'ünü yakaladı. 40 kez çalışan query `AUTO` modunda da yakalandı | SQL Server 2019, 2022 ve 2025, aynı sonuç | Bölüm 5 |
| Parameter sniffing yüzünden yanlış plan, büyük müşteri için yaklaşık 22 kat yavaşlık yarattı (737,71 ms, tarama planında 33,23 ms). Küçük müşteri için aynı plan yaklaşık 365 kat hızlıydı | 420 bin satırlık tablo, SQL Server 2025 | Bölüm 8 |
| Secondary'den primary'ye giden Query Store kuyruğu 25.000 mesajda doydu ve sonrasında gelen mesajlar kalıcı olarak düştü | Tek oturumdan 20.000 farklı sorgu, iki düğümlü Availability Group, `CLUSTER_TYPE = NONE` | Bölüm 12 |
| Dinamik `EXEC` döngüsüyle ve doğrudan çalışan sorgular secondary'den primary'ye aynı şekilde ulaştı | 8 çalıştırma biçimi, 2025 RTM | Bölüm 12 |
| Automatic plan correction'da `Success` durumu hiçbir koşuda görülmedi, `Verifying` durumundan `Expired` durumuna geçiş sabitlenen planı sessizce kaldırdı | SQL Server 2022 CU25 ve 2025 RTM | Bölüm 12 |

## Kitabın içeriği

Kitap 20 bölümdür ve kendi başına okunabilir. Ölçülmüş her sonuç yeşil "DMC ölçümü" kutularında durur, yalnızca belgeye dayananlar metinde "belgeye göre" diye işaretlidir.

| Grup | Bölümler |
|---|---|
| Mimari ve kurulum | 1 Query Store nedir, 2 Tarihçe ve sürüm farkları, 3 Mimari ve veri modeli, 4 Aktif etmek, 5 Ayarlar rehberi |
| İş yükü ayarı | 6 Büyük veritabanları, flush ve kota, 7 Raporlar ve T-SQL ile okuma, 8 Plan regression'ı ve plan forcing, 10 Query Store hints, 11 Wait stats |
| İç işleyiş ve inceleme | 9 Plan cache, PSP, OPPO ve otomatik parametrelendirme, 14 Ek konular (sabitlenen plan neden uygulanamaz, index bakımı, native procedure) |
| Yüksek erişilebilirlik ve Availability Group | 12 Automatic plan correction, uyumluluk seviyesi yükseltmesi ve secondary replica'lar, 13 İşletme, bakım ve failover öncesi kontrol |
| Hazır betikler ve başvuru | 15 Tuzaklar ve sorun giderme, 16 Hazır betikler, 17 Hızlı başvuru kartı, 18 Ölçüm betikleri, 19 Sözlük, 20 Kaynaklar ve ölçüm ortamının sınırları |

## Hızlı başlangıç

Kitabın 4. bölümündeki başlangıç ayarı, SQL Server 2019 ve sonrası için Microsoft belgelerindeki örneklere dayanır. Üç sürümde çalıştırıldı ama sizin iş yükünüz için ölçülmüş bir hedef değildir. Önce test ortamında deneyin, çünkü `ALTER DATABASE ... SET QUERY_STORE` o veritabanının plan cache'ini temizleyebilir.

```sql
ALTER DATABASE [VeritabaniAdi]
SET QUERY_STORE = ON
(
  OPERATION_MODE              = READ_WRITE,
  CLEANUP_POLICY              = (STALE_QUERY_THRESHOLD_DAYS = 30),
  DATA_FLUSH_INTERVAL_SECONDS = 900,
  MAX_STORAGE_SIZE_MB         = 1000,
  INTERVAL_LENGTH_MINUTES     = 60,
  SIZE_BASED_CLEANUP_MODE     = AUTO,
  QUERY_CAPTURE_MODE          = AUTO,
  MAX_PLANS_PER_QUERY         = 200,
  WAIT_STATS_CAPTURE_MODE     = ON
);

-- Açtıktan sonra doğrulayın, actual_state_desc değeri READ_WRITE olmalı
SELECT actual_state_desc, readonly_reason, current_storage_size_mb, max_storage_size_mb
FROM sys.database_query_store_options;
```

## Depoda neler var

| Klasör | İçeriği |
|---|---|
| `gorsel/` | Kitabın tanıtım görselleri. `paylasim/` altında sosyal medya boyutları var (1200x675 ve GitHub önizleme 1280x640). |
| `betikler/` | Kitaptaki T-SQL blokları. Klasör adı kitaptaki bölüm numarasıdır. |
| `betikler/00-demo-veritabani.sql` | Kitaptaki örnek çıktıların alındığı demo veritabanlarını kurar. |
| `betikler/tum-bloklar.sql` | Tüm blokları sırayla çalıştıran tek dosya. |
| `olcum/surum-karsilastirma/` | SQL Server 2019, 2022 ve 2025'te çalıştırılan deneyler ve her sürümün ham çıktısı. |
| `olcum/forced-plan/` | Sabitlenen planın Query Store `READ_WRITE`, `READ_ONLY` ve `OFF` durumlarında uygulanıp uygulanmadığı ve plan ile parametre başına süreler. |
| `olcum/kapatma-ve-read-only/` | `OFF (FORCED)` ile veri kaybı ve `READ_ONLY` iken Query Store prosedürlerinin davranışı. |
| `olcum/psp-ve-oppo/` | PSP ve OPPO denemeleri. |
| `olcum/psp-tetikleme/` | PSP'nin devreye girme eşiği, atlama nedenleri, dispatcher ve variant planlar, hint adı denemeleri. SQL Server 2022 CU25 ve 2025 RTM. İçindeki README dosyası her denemeyi anlatır. |
| `olcum/flush-ve-disk/` | Flush ve disk I/O ölçümü. 60.000 farklı query'nin elle flush süresi, 4 oturumla 150 saniyelik yük, disk sayaçları ve yoklama sorgusu. |
| `olcum/tempdb-ve-replica/` | `tempdb` için `is_query_store_on` bayrağı (üç sürüm, `model` ve yeniden başlatma denemeleri) ve SQL Server 2025'te secondary replica ile ilgili katalog nesneleri. |
| `olcum/automatic-plan-correction/` | Regression'ın kendiliğinden bulunup planın sabitlenmesi. |
| `olcum/eszamanli-yuk/` | 8 eşzamanlı oturumla `OFF`, `AUTO` ve `ALL` modlarının karşılaştırması. |
| `olcum/temizleme-betigi/` | Ad hoc ve iç query'leri temizleyen betiğin `READ_ONLY` iken denemesi. |
| `olcum/ek-konular/` | Yedek, restore, klon ve Query Store bellek ölçümleri. |
| `olcum/bolum-18-dogrulama/` | Kitaptaki Bölüm 18 betiklerinin, kitapta basıldığı haliyle ikinci kez çalıştırılmış çıktıları. |
| `betikler/senaryolar/` ve `betikler/senaryolar-en/` | Kitabın ölçüm ve izleme senaryolarının T-SQL blokları, Türkçe ve İngilizce yorumlu. Flush penceresi, otomatik parametrelendirme, hint'lerin tablo olarak okunması, durum geçişi alarmı, failover öncesi kontrol, index bakımı, native procedure, Availability Group kurulumu ve geri basınç ölçümü. |
| `olcum/senaryolar/` | Aynı senaryoların ham ölçüm çıktıları. Hangi dosyanın hangi sürümden geldiği klasördeki README dosyasındadır. |
| `olcum/ornek-cikti-kutulari-kaynagi.txt` | Kitaptaki "Örnek çıktı" kutularının alındığı ham çıktı. |

## Bölüm 18 senaryoları

Kitabın Bölüm 18'inde 14 ölçüm senaryosu vardır. İlk altı senaryo `olcum/` altında kendi klasörlerindedir. Sonrakilerin betikleri `betikler/senaryolar/` (Türkçe yorumlu) ve `betikler/senaryolar-en/` (İngilizce yorumlu) altındadır, ham çıktıları `olcum/senaryolar/` altındadır. İki betik klasörünün dosya adları aynıdır. "Ölçüldüğü sürüm" sütunu betiğin hangi sürümde çalıştırıldığını gösterir, başka sürümde çalışacağı anlamına gelmez.

| # | Senaryo | Ölçüldüğü sürüm | Ön koşul | Betik | Ham çıktı |
|---|---|---|---|---|---|
| 1 | Sabitlenen plan, parametre başına süre | 2025 | sysadmin, test sunucusu, 420 bin satırlık tablo | `olcum/forced-plan/` | `olcum/forced-plan/` |
| 2 | `OFF (FORCED)` ile veri kaybı | 2025 | sysadmin, veritabanı oluşturur ve siler | `olcum/kapatma-ve-read-only/` | `olcum/kapatma-ve-read-only/` |
| 3 | `READ_ONLY` iken Query Store prosedürleri | 2025 | sysadmin | `olcum/kapatma-ve-read-only/` | `olcum/kapatma-ve-read-only/` |
| 4 | Eşzamanlı yük testi | 2025 | 8 eşzamanlı bağlantı açabilen `sqlcmd` ya da PowerShell | `olcum/eszamanli-yuk/` | `olcum/eszamanli-yuk/` |
| 5 | PSP tetikleme laboratuvarı | 2022 CU25, 2025 | uyumluluk seviyesi 160 ve üstü | `olcum/psp-tetikleme/` | `olcum/psp-tetikleme/` |
| 6 | Flush ve disk I/O ölçümü | 2025 | ayrı bir veri diski (betikte `F:\data`), sysadmin | `olcum/flush-ve-disk/` | `olcum/flush-ve-disk/` |
| 7 | PSP olaylarını keşif tabanlı toplamak | 2022 CU25, 2025 | sysadmin (sunucu düzeyinde Extended Events) | `betikler/senaryolar/bolum-18-psp-olaylarini-kesif-tabanli-toplamak/` | `olcum/senaryolar/psp-olaylari/` |
| 8 | Otomatik parametrelendirme ölçümü | 2022 CU25, 2025 | sysadmin, veritabanı düzeyinde `PARAMETERIZATION` ayarı değişir | `betikler/senaryolar/bolum-18-otomatik-parametrelendirme-olcumu/` | `olcum/senaryolar/otomatik-parametrelendirme/` |
| 9 | Index bakımı ve sabitlenen plan | 2022 CU25, 2025 | sysadmin, `ONLINE` işlem için Enterprise ya da Developer (online denemesi yapılmadı) | `betikler/senaryolar/bolum-18-index-bakimi-ve-sabitlenen-plan/` | `olcum/senaryolar/index-bakimi/` |
| 10 | Native procedure ve istatistik toplama | 2022 CU25, 2025 | In-Memory OLTP, betik `MEMORY_OPTIMIZED_DATA` dosya grubu kurar | `betikler/senaryolar/bolum-18-native-procedure-ve-istatistik-toplama/` | `olcum/senaryolar/native-procedure/` |
| 11 | Flush penceresi örnekleyici | 2025 | sysadmin, yaklaşık 1 GB boş alan (bizim koşuda log 600 MB, Query Store 213 MB) | `betikler/senaryolar/bolum-18-flush-penceresi-ornekleyici/` | `olcum/senaryolar/flush-penceresi/` |
| 12 | Secondary replica doğrulaması ve geri basınç | 2025 RTM | iki Windows Server makinesi, sertifika kimlik doğrulaması, `CLUSTER_TYPE = NONE`, HADR açık, sysadmin | `betikler/senaryolar/bolum-18-secondary-replica-dogrulamasi-ve-geri-basinc/` | `olcum/senaryolar/ag-geri-basinc/` |
| 13 | Secondary'de çalıştırma biçimleri | 2025 RTM | 12. senaryonun kurduğu Availability Group, okunabilir secondary | `betikler/senaryolar/bolum-18-secondary-de-calistirma-bicimleri/` | `olcum/senaryolar/ag-calistirma-bicimleri/` |
| 14 | Flush sırasında işlem ve log sayaçları | 2025 | sysadmin, yaklaşık 1 GB boş alan (bizim koşuda log 600 MB, Query Store 213 MB) | `betikler/senaryolar/bolum-18-flush-sirasinda-islem-ve-log-sayaclari/` | `olcum/senaryolar/flush-islem-sayaclari/` |

Bölüm 12 ve 13'teki alarm, yakalayıcı yordam ve failover öncesi kontrol betikleri de `betikler/senaryolar/` altındadır. Betik dosyalarının başındaki yorum satırı hangi kitap bölümünden alındığını söyler.

## Betikleri çalıştırmadan önce

- Önce test ortamında deneyin. Birçok betik veritabanı oluşturur, siler ya da Query Store ayarlarını değiştirir.
- `ALTER DATABASE ... SET QUERY_STORE` komutları o veritabanının plan cache'ini temizleyebilir.
- Temizleme betiği query'leri siler ve silinen veri geri gelmez. Sabitlenmiş planı ya da hint'i olan query'lere dokunmaz.
- Availability Group betikleri yalnızca `CLUSTER_TYPE = NONE` ile kurulmuş iki düğümlü bir group'ta denendi. Cluster'lı group'ta ve çok sayıda veritabanı olan sunucularda denenmedi. Sertifika betiğindeki parolayı kendi güçlü parolanızla değiştirin.
- SQL Server 2019'da 2022 ve sonrasına özgü nesneleri kullanan betikler hata verir (hint görünümleri, `plan_type_desc`, `replica_group_id` gibi). Kitapta bu bloklar işaretlidir.

## Bilinen eksikler

- `olcum/kapatma-ve-read-only/off-forced-ve-read-only.sql` dosyasının son bölümü, hint konmuş bir query'ye plan sabitlemeyi denediği için hata verir. `READ_ONLY` iken sonuç temiz olarak `read-only-prosedurleri.sql` dosyasında alındı. Kitap bu ikinci dosyanın sonucunu kullanır.
- `olcum/surum-karsilastirma/betikler/kapatma-yollari.sql` dosyasındaki süre ölçümü bölümü sözdizimi hatası verdi. Yük testi için `olcum/eszamanli-yuk/` klasöründeki betikler kullanıldı.
- Laboratuvar veritabanı ve değişken adları kitap yayınlandıktan sonra standarda çekildi (`qs_lab_*`, `@plan_id_tarama` gibi). `olcum/bolum-18-dogrulama/ad-standardi-sonrasi/` yeni adlarla alınan çıktıları, diğer ham çıktılar eski adları (`lc`, `lim_f`, `ov`, `psp_lab`, `flush_lab`) içerir. Eşleşme tablosu o klasördeki README dosyasındadır.
- Automatic plan correction'ın `Success` durumu hiçbir koşuda görülmedi. Cluster'sız group'ta `SET (ROLE = SECONDARY)` komutu 41104 hatası verdi, failover `FORCE_FAILOVER_ALLOW_DATA_LOSS` ile yapıldı. İkisi de kitapta açıkça yazılıdır.
- Çıktı dosyalarında sunucu adları (`vm-qs2019`, `vm-qs2022`, `vm-qs2025`) geçer. Bunlar ölçüm için kurduğumuz geçici makinelerdir.

## Ölçüm matrisi

| Konu | SQL Server 2019 | SQL Server 2022 CU25 | SQL Server 2025 RTM |
|---|---|---|---|
| Varsayılan ayarlar, `model` kalıtımı, capture mode, plan cache | Ölçüldü | Ölçüldü | Ölçüldü |
| PSP, atlama nedenleri, çarpıklık eşiği | Yok (PSP gelmemiştir) | Ölçüldü | Ölçüldü |
| Otomatik parametrelendirme, index bakımı, native procedure | Ölçülmedi | Ölçüldü | Ölçüldü |
| Forced plan yaşam döngüsü, `OFF (FORCED)`, `READ_ONLY`, eşzamanlı yük | Ölçülmedi | Ölçülmedi | Ölçüldü |
| Flush, işlem ve log sayaçları | Ölçülmedi | Ölçülmedi | Ölçüldü |
| Automatic plan correction durum geçişleri | Ölçülmedi | Ölçüldü | Ölçüldü |
| İki düğümlü Availability Group, secondary replica | Ölçülmedi | Ölçülmedi | Ölçüldü (`CLUSTER_TYPE = NONE`) |

Ölçülmeyenler SQL Server 2016 ve 2017, Linux, cluster'lı Availability Group, Standard edition, Azure SQL ve tek tek cumulative update'lerdir.

| Sürüm | Build | Edition | Makine |
|---|---|---|---|
| SQL Server 2019 | 15.0.4470.1 (CU32 ve GDR) | Developer | Azure Standard D4s_v5, Windows Server 2022 |
| SQL Server 2022 | 16.0.4255.1 (CU25) | Developer | Azure Standard D4s_v5, Windows Server 2022 |
| SQL Server 2025 | 17.0.1000.7 (RTM) | Enterprise Developer | Azure Standard D8s_v5, Windows Server 2025 (Availability Group için iki makine) |

## Lisans

Bu depoda ayrı bir lisans dosyası yoktur. Betikler ve ölçüm çıktıları kitabın okuyucuları için herkese açık olarak yayınlanmıştır. Katkı için [`CONTRIBUTING.md`](CONTRIBUTING.md), atıf için `CITATION.cff` dosyasına bakın. `python3 tools/kontrol.py` depodaki yolları ve gizli bilgi kalıplarını denetler.

## Atıf

Kitaptan alıntı yaparken yazarı ve DMC Bilgi Teknolojileri'ni belirtin.

```bibtex
@misc{ozenc2026querystore,
  author    = {Özenç, Çağlar},
  title     = {SQL Server Query Store Başucu Rehberi},
  year      = {2026},
  publisher = {DMC Bilgi Teknolojileri},
  note      = {Sürüm 2.1, PDF},
  url       = {https://github.com/dmcteknoloji/sql-server-query-store-basucu-rehberi}
}
```

APA biçimi: Özenç, Ç. (2026). *SQL Server Query Store başucu rehberi* (Sürüm 2.1) [PDF]. DMC Bilgi Teknolojileri. https://github.com/dmcteknoloji/sql-server-query-store-basucu-rehberi

## Yazar

Çağlar Özenç, 6x Microsoft Data Platform MVP, DMC Bilgi Teknolojileri kurucusu. [caglarozenc.com](https://caglarozenc.com), [LinkedIn](https://www.linkedin.com/in/caglarozenc/), [dmcteknoloji.com](https://www.dmcteknoloji.com). Hata ve eksik için depoya issue açabilir ya da iletisim@dmcteknoloji.com adresine yazabilirsiniz.
