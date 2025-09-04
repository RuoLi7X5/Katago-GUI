# KataGo 命令大全（中文）

本文件汇总 KataGo 可执行程序的所有子命令与常用参数，并给出安全、实用的示例。建议配合各子命令的 `-help` 获取完整即时帮助。

参考源码中子命令清单：<mcfile name="main.cpp" path="d:\FromGithub\KataGo\cpp\main.cpp"></mcfile>
关键实现位置（部分）：
- GTP 引擎：<mcfile name="gtp.cpp" path="d:\FromGithub\KataGo\cpp\command\gtp.cpp"></mcfile>
- 基准测试/生成配置：<mcfile name="benchmark.cpp" path="d:\FromGithub\KataGo\cpp\command\benchmark.cpp"></mcfile>

## 目录
- 1. 基本用法
- 2. 通用参数约定（多命令通用）
- 3. 子命令总览（一句话速览）
- 4. 常用子命令详解
- 5. 诊断/测试子命令一览（开发者向）
- 6. 速查示例
- 7. 注意事项
- 8. 常见场景操作清单
- 9. 时间控制与规则（GTP/Kata 扩展）
- 10. 终局判断与分析结束
  - 10.1 快速参考（时间制与终局）

## 1. 基本用法
- 通用形式：
  - `katago SUBCOMMAND [参数...]`
- 查看帮助：
  - `katago help` 或 `katago -help`
  - `katago SUBCOMMAND -help`
- 查看版本与编译信息：
  - `katago version`

- 启动 GTP 引擎
  - 步骤（PowerShell，逐行执行）：
   1. 设置路径变量
   $exe   = "D:\FromGithub\KataGo\build-msvc-eigen\Release\katago.exe"
   $model = "D:\FromGithub\KataGo\models\kata1-b28c512nbt-s10454102784-d5202721081.bin.gz"
   $cfg   = "D:\FromGithub\KataGo\build-msvc-eigen\Release\default_gtp.cfg"
   2.  启动 GTP 引擎（前台运行）
   & $exe gtp -model $model -config $cfg
   3. 结束引擎
   在该终端直接输入 quit 回车（或关闭窗口）
   4. 启动 GTP 引擎（后台运行）
   & $exe gtp -model $model -config $cfg -background
   5. 结束引擎
   在该终端直接输入 quit 回车（或关闭窗口）
   6. 查看日志
   日志文件通常在 `logDir` 目录下，文件名包含日期与时间。
   可以使用文本编辑器打开查看，或使用 `tail -f` 实时监控。
   7. 查看日志（实时监控，带颜色）
   tail -f <日志文件路径> | grep --color=auto "关键词"
- 启动 JSON Analysis 引擎
  - 1.设置路径变量
    $exe   = "D:\FromGithub\KataGo\build-msvc-eigen\Release\katago.exe"
    $model = "D:\FromGithub\KataGo\models\kata1-b28c512nbt-s10454102784-d5202721081.bin.gz"
    $cfg   = "D:\FromGithub\KataGo\build-msvc-eigen\Release\default_analysis.cfg"
  - 2.启动 Analysis 引擎（前台运行）
    - & $exe analysis -model $model -config $cfg
  - 3.结束引擎
    - 在该终端按 Ctrl+C 结束（或关闭窗口）

  需要解析某个sgf
  - 脚本路径：d:\FromGithub\KataGo\scripts\analyze_sgf.ps1
  - 用法示例（生成 clean.jsonl/clean.json/log.txt）：
    .\scripts\analyze_sgf.ps1 -Sgf '替换为sgf路径地址' -MoveStart 0 -MoveEnd 50 -Visits 200 -Threads 6 -OutName '替换为输出文件名称'

## 2. 通用参数约定（多命令通用）
- `-config <FILE>`：配置文件路径（不同命令使用的示例 cfg 略有不同）。
- `-model <FILE>`：神经网络模型（.bin.gz 或 .gz）。
- `-override-config KEY=VALUE[,KEY=VALUE...]`：临时覆盖配置，不修改 cfg 文件。
- Windows 路径建议使用绝对路径；日志通常写入配置中的 `logDir` 目录。
- 日志文件默认使用 UTF-8 编码，避免中文乱码问题。

## 3. 子命令总览（一句话速览）
- gtp：启动 GTP 引擎用于对局与实时分析。
- analysis：通过 JSON 流式接口进行批量/服务端分析。
- benchmark：跑性能基准，评估线程/并发设置。
- genconfig：交互式生成配置文件并进行初步调优。
- match：让多个 Bot 自动对局，输出 SGF 与统计。
- selfplay：单 Bot 自对弈，持续生成训练数据。
- gatekeeper：新模型门控评估与接纳/拒绝。
- contribute：连接服务器贡献自对弈数据（需服务端参数）。
- evalsgf：对 SGF 某一步做定点分析/复盘。
- tuner（OpenCL）：OpenCL 显卡参数调优。
- version/help：查看版本与帮助信息。

## 4. 常用子命令详解

### 4.1 gtp（棋力/分析用 GTP 引擎）
一句话：启动 GTP 引擎，对局与实时分析。
- 用途：接入任意 GTP GUI（Sabaki、Lizzie、KaTrain 等）进行对弈和分析。
- 基本：
  - `katago gtp -model <模型> -config <GTP配置> [-override-config ...]`
  - 可选：`-human-model <较小模型>`（混合人机体验，少用）
  - 可选：`-override-version <STRING>`（覆盖 GTP `version` 输出）
- 常见 GTP 指令（会话内输入）：
  - 基础：`name` `version` `protocol_version`
  - 局面：`boardsize 19` `komi 7.5` `clear_board` `showboard`
  - 行棋：`play B D4` `play W Q16` `genmove b|w` `undo`
  - 终局：`final_score` `final_status_list dead|alive`
  - 时间：`time_settings <main> <byo> <inc>` `time_left b 60 0`
  - 分析（扩展）：`kata-analyze B 100` `lz-analyze` `kata-genmove_analyze b`

### 4.2 analysis（JSON 批量分析引擎）
一句话：用 JSON 驱动的批量/服务端分析。
- 用途：后端服务、批量/并行分析；从 stdin 收 JSON，stdout 回 JSON。
- 基本：
  - `katago analysis -model <模型> -config <分析配置>`
- 入门 JSON（示意）：
  - `{"id":"1","moves":[],"rules":"Chinese","komi":7.5,"boardXSize":19,"boardYSize":19,"maxVisits":200}`
- 示例（Windows PowerShell 批处理，管道方式）：
  - `Get-Content .\in.json | katago analysis -model <模型> -config <分析配置> | Set-Content .\out.json`

### 4.3 benchmark（性能基准/调优）
一句话：评估不同线程/并发下的性能，指导参数设置。
- 用途：评估不同线程/并发下的性能；为 `numSearchThreads` 提供依据。
- 建议参数（CPU/Eigen）：
  - `katago benchmark -model <模型> -config <配置> -concurrency 12 -v 200 -numPositions 64`
  - 说明：`-concurrency` 近似线程数；`-v` 每位置访问数；`-numPositions` 采样量。
- 小技巧：用 `-override-config numSearchThreads=<N>` 测不同 N。

### 4.4 genconfig（交互式生成/调优配置）
一句话：交互式生成 GTP 配置并做基础调优。
- 用途：一步生成 GTP 配置，并做基础性能调优问答。
- 基本：
  - `katago genconfig -output <目标cfg> [-model <模型>]`

### 4.5 match（高性能对战引擎）
一句话：让一组 Bot 自动对局并生成 SGF/统计。
- 用途：让一组 Bot 在共享 GPU/CPU 条件下互博，输出 SGF 与统计。
- 基本：
  - `katago match -config <匹配配置> -log-file match.log -sgf-output-dir <SGF目录>`
- 说明：对局双方/参数/对局数等在配置中定义，适合自动化“对局”场景。

### 4.6 selfplay（自对弈数据生成）
一句话：单 Bot 自对弈以生成训练数据。
- 用途：生成训练所需数据；输出路径与细节在配置中定义。
- 基本：
  - `katago selfplay -config <自对弈配置>`
- 说明：适合“自对弈开始”的全自动场景，由配置控制棋局数与落子策略等。

### 4.7 gatekeeper（模型门控）
一句话：评估候选模型并自动接纳/拒绝。
- 用途：轮询目录新模型，与基准模型对弈评估，接受/拒绝并写入对应目录。
- 基本（关键参数，来自实现）：
  - `katago gatekeeper -config <cfg> -test-models-dir <DIR> -sgf-output-dir <DIR> -accepted-models-dir <DIR> -rejected-models-dir <DIR> [-selfplay-dir <DIR>] [-required-candidate-win-prop <0..1>] [--no-auto-reject-old-models] [--quit-if-no-nets-to-test]`

### 4.8 tuner（仅 OpenCL）
一句话：对 OpenCL 后端进行参数调优。
- 用途：强制/重新进行 OpenCL 参数调优。
- 基本：
  - `katago tuner -config <GTP配置>`

### 4.9 contribute（分布式自对弈贡献）
一句话：连接训练服务器持续贡献自对弈。
- 用途：连接在线训练服务器，持续贡献自对弈；需要服务端信息与凭据（见官方说明）。

### 4.10 evalsgf（单点位 SGF 分析/调试）
一句话：对棋谱中的某步做定点分析。
- 用途：对一盘棋的某一步/位置做定点分析，常用于复盘脚本或调试。
- 用法视实现为准，建议：`katago evalsgf -help`

## 5. 诊断/测试子命令一览（开发者向，普通用户可忽略）
以下命令用于内部测试、基准或调试：
- `testgpuerror` `runtests` `runnnlayertests` `runnnontinyboardtest` `runnnsymmetriestest`
- `runownershiptests` `runoutputtests` `runsearchtests` `runsearchtestsv3` `runsearchtestsv8` `runsearchtestsv9`
- `runselfplayinittests` `runselfplayinitstattests` `runsekitrainwritetests`
- `runnnonmanyposestest` `runnnbatchingtest` `runtinynntests` `runnnevalcanarytests`
- `runconfigtests` `samplesgfs` `dataminesgfs`
- `genbook` `writebook` `checkbook` `booktoposes` `trystartposes` `viewstartposes` `checksgfhintpolicy`
- `genposesfromselfplayinit` `demoplay` `writetrainingdata` `sampleinitializations` `evalrandominits`
- `runbeginsearchspeedtest` `runownershipspeedtest` `runsleeptest` `printclockinfo` `sandbox`
- 获取具体参数：`katago <子命令> -help`

## 6. 速查示例
- 启动 GTP：
  - `katago gtp -model D:\FromGithub\KataGo\models\kata1-xxx.bin.gz -config D:\FromGithub\KataGo\build-msvc-eigen\Release\default_gtp.cfg`
- 启动 JSON 分析：
  - `katago analysis -model <模型> -config <分析cfg>`
- 跑一次基准：
  - `katago benchmark -model <模型> -config <cfg> -concurrency 12 -v 200 -numPositions 64`
- 生成配置：
  - `katago genconfig -output D:\FromGithub\KataGo\build-msvc-eigen\Release\default_gtp.cfg`
- 临时覆盖：
  - `-override-config numSearchThreads=12,maxTime=10,logAllGTPCommunication=false`
- GTP 会话（示例顺序）：
  - `boardsize 19` → `komi 7.5` → `clear_board` → `genmove b`

## 7. 注意事项
- 线程与并发：`numSearchThreads` 与 `-concurrency` 的最佳值需基准测试确定。
- 模型/配置匹配：不同网络与后端（Eigen/CUDA/OpenCL）性能差异显著，建议单机基准后固定参数。
- 日志与性能：大量日志会影响速度，发布/对战时可关闭 `logAllGTPCommunication`。

## 8. 常见场景操作清单
- 对局（GTP 引擎方式）
  - 启动：`katago gtp -model <模型> -config <GTP配置>`
  - 会话：`boardsize 19` → `komi 7.5` → `clear_board` → `genmove b|w` → `final_score`
- 自对弈开始（自动化）
  - 训练型：`katago selfplay -config <自对弈配置>`（完全由配置控制局数/输出）
  - 对战型：`katago match -config <匹配配置> -sgf-output-dir <DIR>`（多 Bot 自动对局）
- 开始分析
  - 交互分析（GTP）：`kata-analyze B 100` 或 `kata-genmove_analyze b`
  - 批量分析（JSON）：`Get-Content .\in.json | katago analysis -model <模型> -config <分析配置> | Set-Content .\out.json`

## 9. 时间控制与规则（GTP/Kata 扩展）

- time_settings <main_time> <byo-yomi_time> <byo-yomi_stones>
  - 简介：标准 GTP 时间设置，支持绝对、加秒（秒读）、加拿大。单位为秒。
  - 规则细节：
    - 若 byo-yomi_stones == 0 且 byo-yomi_time > 0，则视为“无时间限制”。
    - 若 byo-yomi_stones == 0 且 byo-yomi_time <= 0，则为“绝对用时”（仅 main_time）。
    - 否则为“加拿大/秒读”模式（内部统一处理）。
  - 示例：
    - 绝对用时：time_settings 600 0 0  （主时间 10 分钟）
    - 秒读：time_settings 900 30 1   （主时间 15 分钟，30 秒/手）
    - 加拿大：time_settings 1200 60 25 （主时间 20 分钟，加赛每 60 秒下 25 手）

- kata-list_time_settings
  - 简介：列出 KataGo 支持的时间制度名称枚举。
  - 返回：none absolute byoyomi canadian fischer fischer-capped

- kgs-time_settings <mode> [...]
  - 简介：KGS 风格的时间设置，支持 none/absolute/byoyomi/canadian 四种。
  - 用法：
    - none
    - absolute <main_time>
    - byoyomi <main_time> <period_time> <periods>
    - canadian <main_time> <period_time> <stones>
  - 说明：canadian 模式下 <stones> 为每个加赛时段需要下的手数；byoyomi 模式下 <periods> 为可用的读秒次数。

- kata-time_settings <mode> [...]
  - 简介：KataGo 扩展的时间设置，除 KGS 同款外，还支持 Fischer 与封顶的 Fischer。
  - 用法：
    - none
    - absolute <main_time>
    - byoyomi <main_time> <period_time> <periods>
    - canadian <main_time> <period_time> <stones>
    - fischer <main_time> <increment>
    - fischer-capped <main_time> <increment> <main_time_limit> <max_time_per_move>
  - 说明：fischer-capped 中 <main_time_limit>/<max_time_per_move> 允许为负数，表示“不限制”（将被内部替换为最大允许值）。

- time_left <b|w> <time> <stones>
  - 简介：更新某一方当前剩余时间与当前阶段剩余手数/子数（取决于时间制）。
  - 规则细节：<time> 可容忍轻微负值（>-10），用于对接部分平台的时序采样；<stones> 范围为 0..100000。
  - 提示：在加拿大制下 <stones> 表示本时段剩余需落子数；在读秒制下可表示本读秒剩余手数（部分前端约定）。
  - 示例：time_left b 28.5 1

- kata-debug-print-tc
  - 简介：打印当前内部生效的时间控制（TimeControls）以便调试确认。


## 10. 终局判断与分析结束

- final_score
  - 简介：基于当前棋局形势给出胜负与目差，返回如 “B+3.5”“W+1.0” 或 “0”。
  - 示例交互：
    - final_score -> W+2.0

- final_status_list <alive|seki|dead>
  - 简介：列出对应存活状态的棋子坐标集合。
  - 说明：
    - alive：输出所有被判定为活的棋子坐标。
    - seki：输出共活（世弃/劫争等视作共生）棋子坐标。
    - dead：输出被判为死子的棋子坐标。
  - 示例：
    - final_status_list dead -> D4 Q16 R3 ...

- stop
  - 简介：停止当前的分析/可取消搜索（如 kata-analyze、kata-search_analyze_cancellable 等），用于结束持续输出。
  - 示例：在持续 kata-analyze 输出过程中发送一行 “stop” 即可终止。


### 10.1 快速参考（时间制与终局）

- 设置 15+30 秒读：kata-time_settings byoyomi 900 30 1
- 设置 20+5 延时（Fischer）：kata-time_settings fischer 1200 5
- 设置 Fischer 封顶（总时长 30 分钟，每手最多 60 秒）：kata-time_settings fischer-capped 1800 5 1800 60
- 无时间限制：kata-time_settings none 或 time_settings 0 1 0
- 列出支持的时间制：kata-list_time_settings
- 查询终局目数：final_score
- 列出死子：final_status_list dead
- 终止分析：stop