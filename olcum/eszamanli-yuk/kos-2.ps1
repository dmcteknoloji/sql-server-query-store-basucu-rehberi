$ErrorActionPreference = 'Continue'
$out = 'C:\qs\ov2_sonuc.txt'
"is|mod|tekrar|saniye|query_sayisi|qs_mb" | Set-Content $out
# kurulum yeniden yapilmaz
function Q($s) { sqlcmd -E -C -h -1 -W -d qs_lab_yuk -Q "SET NOCOUNT ON; $s" }
function Mod($m) {
  if ($m -eq 'OFF') { Q "ALTER DATABASE qs_lab_yuk SET QUERY_STORE = OFF" | Out-Null }
  else { Q "ALTER DATABASE qs_lab_yuk SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = $m, DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60)" | Out-Null; Q "ALTER DATABASE qs_lab_yuk SET QUERY_STORE CLEAR" | Out-Null }
}
$orders = @(@('OFF','AUTO','ALL'), @('ALL','OFF','AUTO'), @('AUTO','ALL','OFF'), @('OFF','ALL','AUTO'))
foreach ($w in @('w2b')) {
  $rep = 0
  foreach ($ord in $orders) {
    $rep++
    foreach ($m in $ord) {
      Mod $m
      $t = Measure-Command {
        $ps = 1..8 | ForEach-Object { Start-Process sqlcmd -ArgumentList '-E','-C','-d','qs_lab_yuk','-i',"C:\qs\$w.sql",'-o','NUL' -PassThru -WindowStyle Hidden }
        $ps | Wait-Process
      }
      $n = 'NA'; $mb = 'NA'
      if ($m -ne 'OFF') { $n = (Q "SELECT COUNT(*) FROM sys.query_store_query") | Select-Object -First 1; $mb = (Q "SELECT current_storage_size_mb FROM sys.database_query_store_options") | Select-Object -First 1 }
      "$w|$m|$rep|$([math]::Round($t.TotalSeconds,2))|$n|$mb" | Add-Content $out
    }
  }
}
'BITTI' | Add-Content $out
