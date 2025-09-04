<#
文件: scripts\analyze_sgf.ps1
用途: 一键运行 KataGo evalsgf 对 SGF 逐手分析，并“流式”分离日志与 JSON，最终同时生成 clean.jsonl（JSON Lines）、clean.json（数组版）与 log.txt。

执行步骤与原因:
1) 调用 evalsgf 输出分析 JSON (-print-json)：evalsgf 是 KataGo 用于离线/调试 SGF 的子命令，速度快、可批量逐手定位信息（winrate/score/policy/ownership 等）。
2) 流式分离日志与 JSON：evalsgf 会把日志与 JSON 混合输出到控制台。脚本将合并标准输出/错误后逐行尝试 JSON 解析，解析成功的写入 clean.jsonl，失败的写入 log.txt，这样可以边跑边产出“干净 JSONL”。
3) 汇总生成 clean.json（数组）：任务结束后，把 clean.jsonl 每行 JSON 解析为对象数组再导出为一个 JSON 数组文件，方便一次性加载或后续数据处理。

注意事项:
- 性能: -v（每手访问次数）与 -t（线程）越高越慢、越耗资源，可按机器调小/调大；如后台还在运行 GTP，请考虑先退出以避免资源竞争。
- 手数范围: -m 与 -move-num-end 是闭区间 [start,end]，例如 -m 0 -move-num-end 50 会分析第0手到第50手。
- 规则/贴目: 如需要可用 -override-rules 或 -override-komi 覆盖，默认为 SGF 或配置中的设置。
- “Unused key” 警告: 使用 default_gtp.cfg 跑 evalsgf 时常见，因为该配置包含大量仅 GTP 引擎需要的键；对离线分析无害，日志已单独写入 log.txt，不会污染 JSON。

命令示例（PowerShell）:
# 基础用法（与前文案例一致）：
# .\analyze_sgf.ps1 -Sgf 'D:\野狐自战棋谱\20240919[zjp88]vs[赤那少侠].sgf' -MoveStart 0 -MoveEnd 50 -Visits 200 -Threads 6 -OutName '20240919_first50'
# 自定义可执行/模型/配置路径：
# .\analyze_sgf.ps1 -Sgf 'X:\some\game.sgf' -MoveStart 0 -MoveEnd 200 -Visits 400 -Threads 8 -OutName 'case_200' -Exe 'D:\FromGithub\KataGo\build-msvc-eigen\Release\katago.exe' -Model 'D:\FromGithub\KataGo\models\your_model.bin.gz' -Config 'D:\FromGithub\KataGo\build-msvc-eigen\Release\default_gtp.cfg'

#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)] [string] $Sgf,
  [Parameter(Mandatory=$true)] [int]    $MoveStart,
  [Parameter(Mandatory=$true)] [int]    $MoveEnd,
  [Parameter(Mandatory=$true)] [int]    $Visits,
  [Parameter(Mandatory=$true)] [int]    $Threads,
  [Parameter(Mandatory=$true)] [string] $OutName,
  [string] $Exe    = 'D:\FromGithub\KataGo\build-msvc-eigen\Release\katago.exe',
  [string] $Model  = 'D:\FromGithub\KataGo\models\kata1-b28c512nbt-s10454102784-d5202721081.bin.gz',
  [string] $Config = 'D:\FromGithub\KataGo\build-msvc-eigen\Release\default_gtp.cfg'
)

set-strictmode -version Latest
$ErrorActionPreference = 'Stop'

# 0) 路径与参数校验
if (!(Test-Path -LiteralPath $Sgf))   { throw "找不到 SGF: $Sgf" }
if (!(Test-Path -LiteralPath $Exe))   { throw "找不到 katago.exe: $Exe" }
if (!(Test-Path -LiteralPath $Model)) { throw "找不到模型文件: $Model" }
if (!(Test-Path -LiteralPath $Config)){ throw "找不到配置文件: $Config" }
if ($MoveEnd -lt $MoveStart)          { throw "MoveEnd ($MoveEnd) 必须 >= MoveStart ($MoveStart)" }

# 1) 输出目录准备
$rootOut = Join-Path 'D:\FromGithub\KataGo\analyses' $OutName
New-Item -ItemType Directory -Path $rootOut -Force | Out-Null
$cleanJsonl = Join-Path $rootOut 'clean.jsonl'
$cleanJson  = Join-Path $rootOut 'clean.json'
$logFile    = Join-Path $rootOut 'log.txt'
$metaFile   = Join-Path $rootOut 'meta.txt'

# 清理旧文件
foreach($f in @($cleanJsonl,$cleanJson,$logFile,$metaFile)){
  if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force }
}

# 2) 记录元信息
$cmdLine = @(
  "exe=`"$Exe`"",
  "model=`"$Model`"",
  "config=`"$Config`"",
  "sgf=`"$Sgf`"",
  "-m $MoveStart -move-num-end $MoveEnd -v $Visits -t $Threads -print-json"
) -join ' '
@(
  (Get-Date -Format 'yyyy-MM-dd HH:mm:ss K'),
  "Command: $cmdLine"
) | Out-File -LiteralPath $metaFile -Encoding UTF8

# 3) 计时器
$sw = [System.Diagnostics.Stopwatch]::StartNew()

Write-Host "[1/3] 开始运行 evalsgf 并流式分离日志与 JSON ..."
# 4) 运行 evalsgf，并实时把 JSON 行写 clean.jsonl，其他写 log.txt
$psi = & $Exe evalsgf -model $Model -config $Config -m $MoveStart -move-num-end $MoveEnd -v $Visits -t $Threads -print-json -- $Sgf 2>&1 |
  ForEach-Object {
    $line = $_
    # 先尝试按 JSON 解析，成功就写入 JSONL，否则写入日志
    try {
      $null = $line | ConvertFrom-Json -ErrorAction Stop
      Add-Content -LiteralPath $cleanJsonl -Value $line -Encoding UTF8
    }
    catch {
      Add-Content -LiteralPath $logFile -Value $line -Encoding UTF8
    }
  }

Write-Host "[2/3] evalsgf 结束，开始汇总 JSON Lines 为数组 ..."

# 5) 汇总生成 clean.json（数组）
if (Test-Path -LiteralPath $cleanJsonl) {
  $objs = New-Object System.Collections.Generic.List[object]
  Get-Content -LiteralPath $cleanJsonl -Encoding UTF8 | ForEach-Object {
    if ([string]::IsNullOrWhiteSpace($_)) { return }
    try { $objs.Add( ($_ | ConvertFrom-Json) ) } catch { }
  }
  $objs | ConvertTo-Json -Depth 50 | Out-File -LiteralPath $cleanJson -Encoding UTF8
}

$sw.Stop()

# 6) 汇报
$lines = (Test-Path $cleanJsonl) ? (Get-Content -LiteralPath $cleanJsonl -Encoding UTF8 | Measure-Object -Line).Lines : 0
$sizeL = (Test-Path $cleanJsonl) ? (Get-Item -LiteralPath $cleanJsonl).Length : 0
$sizeA = (Test-Path $cleanJson)  ? (Get-Item -LiteralPath $cleanJson).Length  : 0
Write-Host ("[3/3] 完成，耗时 {0:n1}s | clean.jsonl {1} 行 / {2:n0} B | clean.json {3:n0} B" -f ($sw.Elapsed.TotalSeconds), $lines, $sizeL, $sizeA)
Write-Host "输出目录：$rootOut"