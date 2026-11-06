PSP (Parameter Sensitive Plan) ve OPPO denemeleri
SQL Server 2022 CU25 (16.0.4255.1, Windows Server 2022) ve SQL Server 2025 RTM (17.0.1000.7, Windows Server 2025), Azure sanal makineleri.

01 kitaptaki Bolum 18 PSP betigi. Dispatcher ve 3 variant plan uretir. Uyumluluk seviyesi 160 yazilidir, 2025'te 170 icin ilk satirdaki sayiyi degistirin.
02 XE olaylari ve atlama nedeni numaralandirmasi (sys.dm_xe_objects, sys.dm_xe_map_values).
03 atlama nedenlerini tek tek tetikleyen 12 senaryo (SQL Server 2022).
04 en yuksek ve en dusuk EQUAL_ROWS oranini degistiren supurme, PSP esigi.
05 esigin tam siniri (99.999 ve 100.000) ve uc katmanli veri.
06 variant query metinlerindeki sinir degerleri (predicate_range).
07 sp_executesql ile PSP ve Query Store hint adi denemesi.
08 hint etkileri (MAXDOP, OPTIMIZE FOR, RECOMPILE, DISABLE_PARAMETER_SNIFFING) ve belgelerde gecen hint adlari.
09 OPPO olaylari ve satir ici hint (SQL Server 2025).
10 SQL Server 2025'te XE olayi ile Query Store kaydinin ayni calistirmada karsilastirilmasi.
11 PSP aday kontrolu (histogramda en yuksek ve en dusuk EQUAL_ROWS orani).

Notlar
- Betikler psp_lab veritabanini siler ve yeniden olusturur. Yalnizca test sunucusunda calistirin.
- Cikti dosyalarindaki sunucu adlari (vm-qs2022, vm-qs2025) olcum icin kurulan gecici makinelerdir.
- 07 ve 08 numarali betiklerde olay okuma proseduru kendi cagri metnini yanlis suzdugu icin bazi bolumlerde olay satiri bos gelir. Kitaptaki sonuclar 01, 05 ve 10 numarali dosyalardan alindi.
- PSP acikken ve kapaliyken toplam sure karsilastirmasi denendi, zamanlayici cozunurlugu (yaklasik 15 ms) yuzunden anlamli sonuc cikmadi ve kitapta kullanilmadi.
- SQL Server 2025 RTM'de parameter_sensitive_plan_optimization olayi PSP calistigi halde gelmedi (10 numarali dosya).
