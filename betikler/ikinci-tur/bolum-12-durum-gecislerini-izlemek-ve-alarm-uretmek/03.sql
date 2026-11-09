-- SQL Server Query Store Basucu Rehberi, Bolum 12, 'Durum geçişlerini izlemek ve alarm üretmek'
-- Test ortaminda calistirin.

SELECT g.oneri_adi, g.query_id, g.regressed_plan_id, g.recommended_plan_id,
       g.onceki_durum, g.durum, g.neden, g.revert_baslatan, g.revert_zamani, g.ilk_gorulme_utc,
       LEFT(t.query_sql_text, 200) AS metin
FROM dbo.qs_apc_gecmis AS g
LEFT JOIN sys.query_store_query AS q ON q.query_id = g.query_id
LEFT JOIN sys.query_store_query_text AS t ON t.query_text_id = q.query_text_id
WHERE g.onceki_durum = N'Verifying' AND g.durum IN (N'Reverted', N'Expired')
  AND ISNULL(g.revert_baslatan, N'System') <> N'User' AND g.alarm_gonderildi = 0
ORDER BY g.son_gorulme_utc DESC;
-- Bilgi amacli, kullanicinin elle geri aldigi oneriler alarm uretmez
SELECT g.oneri_adi, g.query_id, g.neden, g.revert_baslatan, g.revert_zamani
FROM dbo.qs_apc_gecmis AS g
WHERE g.durum = N'Reverted' AND g.revert_baslatan = N'User';
-- Alarm gonderildikten sonra
-- UPDATE dbo.qs_apc_gecmis SET alarm_gonderildi = 1 WHERE onceki_durum = N'Verifying' AND durum IN (N'Reverted', N'Expired') AND alarm_gonderildi = 0;
-- Alarm kanali kuruma gore secilir. Test gonderimleri yalniz @dmcteknoloji.com adreslerine yapilir.
