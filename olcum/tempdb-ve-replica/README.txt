tempdb Query Store bayragi ve secondary replica nesneleri
SQL Server 2019 (15.0.4470.1), 2022 (16.0.4255.1) ve 2025 (17.0.1000.7), Azure sanal makineleri.

01 SQL Server 2022'de tempdb icin ALTER komutlari, is yuku ve kayit sayilari (td_ref normal referans veritabanidir).
02 uc surumde baslangic durumu (is_query_store_on, ayar gorunumundeki satir sayisi, ALTER sonuclari).
03 ve 04 model veritabaninda Query Store kapaliyken ve acikken SQL Server yeniden baslatildiktan sonra tempdb bayragi. Her iki durumda 1 cikti.
05 yeniden baslatma sonrasi sorgu.
06 SQL Server 2025 kataloginda Query Store nesneleri, XE olaylari, performans sayaclari, replica kolonlari.
07 izleme nesnelerinin tek dugumde dogrulanmasi ve olay oturumunun kurulumu.

Not 03 ve 04 numarali sonuclar yalnizca SQL Server 2022 makinesinde alindi. Secondary replica akisi (mesaj kuyrugu, geri basinc) coklu dugumlu bir Availability Group kurulamadigi icin OLCULMEDI.
