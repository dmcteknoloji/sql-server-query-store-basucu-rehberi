-- SQL Server Query Store Handbook, Chapter 12, 'Watching state transitions and raising alerts'
-- Run in a test environment only.

SELECT g.oneri_adi, g.query_id, g.regressed_plan_id, g.recommended_plan_id,
       g.onceki_durum, g.durum, g.neden, g.revert_baslatan, g.revert_zamani, g.ilk_gorulme_utc,
       LEFT(t.query_sql_text, 200) AS metin
FROM dbo.qs_apc_gecmis AS g
LEFT JOIN sys.query_store_query AS q ON q.query_id = g.query_id
LEFT JOIN sys.query_store_query_text AS t ON t.query_text_id = q.query_text_id
WHERE g.onceki_durum = N'Verifying' AND g.durum IN (N'Reverted', N'Expired')
  AND ISNULL(g.revert_baslatan, N'System') <> N'User' AND g.alarm_gonderildi = 0
ORDER BY g.son_gorulme_utc DESC;
-- For information only, recommendations the user reverted by hand do not raise alerts
SELECT g.oneri_adi, g.query_id, g.neden, g.revert_baslatan, g.revert_zamani
FROM dbo.qs_apc_gecmis AS g
WHERE g.durum = N'Reverted' AND g.revert_baslatan = N'User';
-- After the alert has been sent
-- UPDATE dbo.qs_apc_gecmis SET alarm_gonderildi = 1 WHERE onceki_durum = N'Verifying' AND durum IN (N'Reverted', N'Expired') AND alarm_gonderildi = 0;
-- Choose the alert channel to suit your organization. Send test messages only to @dmcteknoloji.com addresses.
