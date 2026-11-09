# Senaryo ölçümleri

Kitabın Bölüm 18'indeki ve sonradan eklenen bölümlerdeki senaryoların ham ölçüm çıktıları. Betikler `betikler/senaryolar/` ve `betikler/senaryolar-en/` klasöründedir, kitaptaki Bölüm 18 ile aynı metindir.

| Klasör | İçeriği | Sürüm |
|---|---|---|
| `psp-olaylari/` | PSP ve multiplan olaylarının keşfi ve sayımı | SQL Server 2022 CU25 ve 2025 RTM |
| `flush-penceresi/` | Elle flush sırasında örnekleyici çıktısı, bekleme testi | SQL Server 2025 RTM |
| `otomatik-parametrelendirme/` | 24 query için simple ve forced parametrelendirme tablosu | SQL Server 2022 CU25 ve 2025 RTM |
| `native-procedure/` | `sp_xtp_control_query_exec_stats` açıkken ve kapalıyken süre | SQL Server 2022 CU25 ve 2025 RTM |
| `apc-durum-gecisleri/` | `Verifying` durumundan `Expired` durumuna geçiş ve alarm sorgusu | SQL Server 2022 CU25 ve 2025 RTM'de gözlendi, buradaki çıktı 2022'den |
| `index-bakimi/` | `REBUILD`, `DROP_EXISTING`, `DISABLE` sonrası sabitlenen planın durumu | SQL Server 2022 CU25 ve 2025 RTM |
| `flush-islem-sayaclari/` | Flush öncesi ve sonrası işlem ve log sayaçları | SQL Server 2025 RTM |
| `ag-calistirma-bicimleri/` | Secondary'de sekiz farklı çalıştırma biçiminin iki düğümde okunması | SQL Server 2025 RTM |
| `kuyruk-alarmi/` | `pending_message_count` eşiği için hata günlüğü uyarısı ve Agent alert sayacı | SQL Server 2025 RTM |
| `apc-yakalayici-yordam/` | Sağlamlaştırılmış `qs_apc_yakala` yordamıyla 24 turluk `Verifying` ve `Expired` izlemesi | SQL Server 2025 RTM |
| `ag-geri-basinc/` | İki düğümlü Availability Group'ta kuyruk doygunluğu ve `pending_message_count` örneklemesi | SQL Server 2025 RTM |

Dosyalar ölçüm sırasında alındığı gibi durur, düzenlenmedi. Bu klasörde olmayan ölçümler kitapta anlatılır ama ham çıktıları depoda yoktur. Bunun için kitaptaki betikleri çalıştırıp kendi çıktınızı alabilirsiniz.

Bilinen sınırlar: Availability Group, `CLUSTER_TYPE = NONE` ile kurulmuş iki düğümlüdür. `Success` durumu hiçbir koşuda görülmedi. Ayrıntı kitabın Kaynaklar bölümündedir.
