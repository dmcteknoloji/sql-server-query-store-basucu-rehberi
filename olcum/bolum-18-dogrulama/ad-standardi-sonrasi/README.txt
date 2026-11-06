Bolum 18 betiklerinin laboratuvar veritabani ve degisken adlari kurumsal standarda cekildikten sonra (qs_lab_* ve @plan_id_tarama gibi) tekrar calistirilmis ciktilari. SQL Server 2025 RTM.
Eski adlar ile yeni adlar
lc -> qs_lab_forced_plan, lim_f -> qs_lab_off_forced, lim_o -> qs_lab_off, lim_r2 -> qs_lab_read_only, ov -> qs_lab_yuk, psp_lab -> qs_lab_psp, flush_lab -> qs_lab_flush
@ptarama -> @plan_id_tarama, @pseek -> @plan_id_seek, @pl -> @plan_id, @q -> @query_id
Bu klasorun disindaki ham cikti dosyalari adlandirma oncesi alinmistir ve eski adlari icerir. Sonuc yapilari ayni cikti, sureler kosudan kosuya degisir.
