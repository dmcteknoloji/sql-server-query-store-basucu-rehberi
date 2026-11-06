$ErrorActionPreference = 'Continue'
function Faz($ad, $bas, $bit) { sqlcmd -E -C -d qs_lab_flush -Q "INSERT dbo.o_faz VALUES ('$ad', '$($bas.ToString('yyyy-MM-dd HH:mm:ss.fff'))', '$($bit.ToString('yyyy-MM-dd HH:mm:ss.fff')))" | Out-Null }
function Wait-Snap($ad) { sqlcmd -E -C -d qs_lab_flush -Q "INSERT dbo.o_wait SELECT '$ad', wait_type, wait_time_ms, waiting_tasks_count FROM sys.dm_os_wait_stats" | Out-Null }
function Isci($sure) { 1..4 | ForEach-Object { Start-Process sqlcmd -ArgumentList '-E','-C','-d','qs_lab_flush','-v',"SURE=$sure",'-i','C:\qs\fl_isci.sql','-o','NUL' -PassThru -WindowStyle Hidden } }
'kurulum' | Out-File C:\qs\fl_log.txt
sqlcmd -E -C -b -i C:\qs\fl_kurulum.sql -o C:\qs\fl_kurulum.txt
'faz B' | Add-Content C:\qs\fl_log.txt
sqlcmd -E -C -W -s'|' -i C:\qs\fl_fazb.sql -o C:\qs\fl_fazb.txt
'faz C' | Add-Content C:\qs\fl_log.txt
sqlcmd -E -C -d qs_lab_flush -Q "ALTER DATABASE qs_lab_flush SET QUERY_STORE (DATA_FLUSH_INTERVAL_SECONDS = 60); ALTER DATABASE qs_lab_flush SET QUERY_STORE CLEAR; CHECKPOINT;" | Out-Null
Wait-Snap 'once'
$perf = Start-Job -ScriptBlock {
  Get-Counter -Counter '\PhysicalDisk(* F:)\Avg. Disk Queue Length','\PhysicalDisk(* F:)\Avg. Disk sec/Write','\PhysicalDisk(* F:)\Disk Write Bytes/sec','\PhysicalDisk(* F:)\Disk Writes/sec' -SampleInterval 1 -MaxSamples 165 | ForEach-Object {
    $t = $_.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'); $v = @{}
    foreach ($s in $_.CounterSamples) { $v[$s.Path.Split('\')[-1]] = $s.CookedValue }
    "$t,$($v['avg. disk queue length']),$($v['avg. disk sec/write'] * 1000),$($v['disk write bytes/sec'] / 1MB),$($v['disk writes/sec'])" } }
$probe = Start-Job -ScriptBlock {
  $cn = New-Object System.Data.SqlClient.SqlConnection('Server=.;Database=qs_lab_flush;Integrated Security=True;TrustServerCertificate=True;Encrypt=False')
  $cn.Open(); $cmd = $cn.CreateCommand(); $cmd.CommandText = 'SELECT v FROM dbo.t WHERE id = 1'
  $sw = New-Object System.Diagnostics.Stopwatch; $end = [DateTime]::UtcNow.AddSeconds(158); $rows = New-Object System.Collections.Generic.List[string]
  while ([DateTime]::UtcNow -lt $end) { $sw.Restart(); $null = $cmd.ExecuteScalar(); $ms = $sw.Elapsed.TotalMilliseconds; $rows.Add([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss') + ',' + $ms.ToString('0.000', [Globalization.CultureInfo]::InvariantCulture)); Start-Sleep -Milliseconds 2 }
  $rows }
$samp = Start-Process sqlcmd -ArgumentList '-E','-C','-d','qs_lab_flush','-v','SURE=162','-i','C:\qs\fl_sampler.sql','-o','NUL' -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 4
$c0 = Get-Date
$w = Isci 150
$w | Wait-Process
$c1 = Get-Date
Faz 'C' $c0 $c1
$samp | Wait-Process
Wait-Snap 'sonra'
Wait-Job $perf, $probe | Out-Null
Receive-Job $perf | Set-Content C:\qs\fl_disk.csv -Encoding ASCII
Receive-Job $probe | Set-Content C:\qs\fl_probe.csv -Encoding ASCII
'faz D' | Add-Content C:\qs\fl_log.txt
sqlcmd -E -C -d qs_lab_flush -Q "ALTER DATABASE qs_lab_flush SET QUERY_STORE = OFF" | Out-Null
Start-Sleep -Seconds 3
$d0 = Get-Date
$w = Isci 60
$w | Wait-Process
$d1 = Get-Date
Faz 'D' $d0 $d1
sqlcmd -E -C -d qs_lab_flush -Q "ALTER DATABASE qs_lab_flush SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE)" | Out-Null
'analiz' | Add-Content C:\qs\fl_log.txt
sqlcmd -E -C -W -s'|' -w 400 -i C:\qs\fl_analiz.sql -o C:\qs\fl_analiz.txt
'BITTI' | Add-Content C:\qs\fl_log.txt
