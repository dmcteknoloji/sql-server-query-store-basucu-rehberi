Flush ve disk I/O olcumu
SQL Server 2025 RTM (17.0.1000.7), Azure Standard D8s_v5, Windows Server 2025. Veri ve log dosyalari ayri bir Premium SSD diskte (P10, F: surucusu).

01 kurulum, 02 ve 03 Faz B (60.000 farkli query biriktirip elle flush), 04 isci, 05 ornekleyici, 06 PowerShell surucusu (Faz C ve D), 07 ve 08 cozumleme, 09 ve 10 XE persist oturumu.
Cikti dosyalari
- faz-b-1-kosu, faz-b-2-kosu, faz-b-3-kosu: elle flush sureleri (884, 80 ve 177 saniye).
- faz-c-*: 4 oturumla 150 saniyelik yuk, saniye saniye ve 15 saniyelik pencere ozeti, disk sayaclari ve yoklama sorgusu ham verisi.
- xe-persist: persist olaylari ve bellek siniri olayi.

Notlar
- Betikler qs_lab_flush veritabanini siler ve yeniden olusturur. Yalnizca test sunucusunda calistirin.
- 1. ve 2. kosunun ciktilari veritabaninin onceki adiyla (flush_lab) alindi, 3. kosu yeni adla.
- 06 numarali surucuda faz tablosuna yazan Faz() islevi calismadi, 07 numarali cozumleme fazlari kayitli verilerin zaman bosluklarindan turetir.
- Faz C tek kosudur, ilk dakikadaki yavaslik soguk baslangictan ayrilamadi.
