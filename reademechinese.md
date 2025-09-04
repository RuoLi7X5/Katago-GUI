# KataGo 中文使用指南

本文件为 KataGo 的中文入门与常见问题说明，涵盖下载、安装、运行、后端选择、性能调优、与常见 GUI 的对接方法等信息。

- 官方训练站点（最新模型与参与训练）：https://katagotraining.org/
- 源代码与预编译发布页（Windows/Linux）：https://github.com/lightvector/KataGo
- 讨论与求助：计算机围棋 Discord https://discord.gg/bqkZAz3

---

## 目录

- 概览
- 训练历史与研究
- 下载位置
- 安装与运行 KataGo
  - 图形界面（GUI）
  - Windows 与 Linux
  - macOS
- 后端对比：OpenCL / CUDA / TensorRT / Eigen（CPU）
- 命令行用法示例
- 性能调优要点
- 常见问题（含特定 GPU/驱动问题）
- 开发者向功能
- 编译 KataGo
- 源代码结构概览
- 自对弈训练
- 贡献者
- 许可证
- 附：快速上手（5 分钟）

---

## 概览

KataGo 是一款开源围棋引擎，采用类似 AlphaZero 的自我对弈训练流程，并在训练管线与搜索算法上加入多项改进。其目标是：

- 不仅给出胜率，还估计实地与目差，便于分析不同水平的棋局。
- 在让子局或官子阶段的实战目标更加合理（如最大化目差）。
- 支持 7x7–19x19 棋盘、支持多种规则（含与日本规则等价的设置）。
- 面向研究与工程，提供 JSON 分析引擎、GTP 扩展等，便于集成与批量评估。

KataGo 的公共分布式训练持续进行中，欢迎参与或下载最新神经网络模型以获得更强的棋力。

---

## 训练历史与研究

- 论文：Accelerating Self-Play Learning in Go（arXiv）
- 训练管线与方法：docs/KataGoMethods.md
- Monte-Carlo Graph Search 说明：docs/GraphSearch.md
- 历史记录与一些外部数据的尝试：TrainingHistory.md

部分研究利用围棋问题的结构信息，也有不少通用技巧可迁移到其他博弈学习任务。

---

## 下载位置

- 预编译可执行文件（Windows/Linux）：https://github.com/lightvector/KataGo/releases
- 最新神经网络模型： https://katagotraining.org/

部分 GUI（如 KaTrain、Lizzie 集成包）可能已经内置 KataGo 与模型；若需替换到最新版本，可手动下载新引擎与模型后在 GUI 设置中更新路径。

---

## 安装与运行 KataGo

KataGo 本体是遵循 GTP 协议的引擎（文本协议），通常配合 GUI（如 Sabaki、Lizzie、KaTrain 等）或分析程序使用。

### 图形界面（GUI）

- KaTrain：上手友好，带一体化安装包，支持减弱强度机器人与复盘分析。
- Lizzie：适合可视化与交互分析，常见有集成包；首次用 OpenCL 会进行较久调参，注意查看命令行日志定位问题。
- Ogatak：KataGo 专用 GUI，强调快速与流畅显示基础信息。
- q5Go / Sabaki：通用 SGF 编辑器，可配置使用 KataGo 分析与目差评估。

对于未内置 KataGo 的 GUI，需要在 GUI 设置中输入 KataGo 可执行文件路径与启动参数（见“命令行用法示例”）。

### Windows 与 Linux

- 官方发布提供 Windows 与 Linux 的预编译包，通常解压即用。
- 如在 Linux 上遇到系统库不兼容或需特殊优化，建议从源码编译（见 Compiling.md）。

### macOS（由社区维护的包）

- 可通过 Homebrew 安装：`brew install katago`
- 可执行与示例配置、模型位置可通过 `brew list --verbose katago` 查看。

---

## 后端对比：OpenCL / CUDA / TensorRT / Eigen（CPU）

- OpenCL（GPU，通用）：支持 NVIDIA/AMD/Intel 等多种设备，安装门槛低；首次运行会自动调参，时长通常数秒到半分钟不等。
- CUDA（GPU，仅 NVIDIA）：需安装 CUDA 与 cuDNN；在多数现代卡上，实际速度常不如 TensorRT 或 OpenCL。
- TensorRT（GPU，仅 NVIDIA）：基于高优化算子，现代 NVIDIA GPU 上通常最快（需安装 Nvidia TensorRT）。
- Eigen（CPU）：纯 CPU 版本；在较强 CPU 与小网络（如 15/20 blocks）上也能达到可用的搜索速度；可按 CPU 指令集（AVX2/FMA）编译优化。

无论哪种后端，“线程数/并发数”等参数会显著影响性能，建议通过 benchmark 自动调参或手动测试寻找最佳设置。

---

## 命令行用法示例

以下命令以 Windows 为例，Linux/macOS 将 `katago.exe` 改为 `katago`，路径与引号按平台调整。

- 运行基准测试（会尝试不同线程并给出推荐值）：

```
katago.exe benchmark -model path\to\model.bin.gz -config path\to\gtp_example.cfg
```

- 生成配置（交互式）：

```
katago.exe genconfig -model path\to\model.bin.gz -output gtp_custom.cfg
```

- 启动 GTP 引擎（供 GUI 连接）：

```
katago.exe gtp -model path\to\model.bin.gz -config path\to\gtp_custom.cfg
```

- JSON 分析引擎（批量评估/服务化）：

```
katago.exe analysis -model path\to\model.bin.gz -config path\to\analysis.cfg
```

小技巧：若将模型命名为 `default_model.bin.gz` 且与可执行文件放在同一目录，很多 GUI 或命令可省略 `-model` 参数；配置文件若命名为 `default_gtp.cfg` 也可简化命令。

---

## 性能调优要点

- 最重要的是搜索线程数（`numSearchThreads`），不同设置可能相差 2–3 倍。
- 建议先运行 `benchmark`，参考其推荐值，再在配置中更新 `numSearchThreads`。
- 通读你的 GTP 配置（`default_gtp.cfg` 或 `cpp/configs/gtp_example.cfg` 等），其中包含：
  - 资源占用、GPU 选择与并发批量；
  - 投降阈值、思考（ponder）行为；
  - 规则设置与效用函数等。

---

## 常见问题（含特定 GPU/驱动问题）

- 首次运行 OpenCL 需要自动调参，时间从数秒到数十秒不等；如过久或卡住，请在命令行直接跑 `benchmark` 以查看日志。
- 部分驱动/设备已知问题：
  - 某些旧 AMD 驱动在 OpenCL 上可能不稳定；
  - OpenCL Mesa 驱动问题较多，如日志中出现 “(Mesa)” 建议更换；
  - Intel 集显可运行但通常较慢，个别驱动版本存在问题。
- GUI 中“卡住”或“加载很久”：
  - 可能是路径/权限/配置错误，许多 GUI 会吞掉错误信息；请先在命令行验证；
  - Windows 下请避免把引擎与配置放在无写权限的目录（如 Program Files）。
- 不会配置路径：
  - 优先尝试把模型与配置命名为默认名，并与可执行文件放在同一目录；
  - 或参考 GUI 文档填写绝对路径。

若仍需帮助，请加入 Discord 的 #help 频道，或在 GitHub 提交 Issue，并附完整命令、日志、配置、模型与硬件/系统信息。

---

## 开发者向功能

- GTP 扩展与命令（如 `kata-analyze` 同时报告期望目差与全盘地盘热力图）详见 `docs/GTP_Extensions.md`。
- JSON 分析引擎：`docs/Analysis_Engine.md`，内含 Python 示例 `python/query_analysis_engine_example.py`，便于构建后端服务或批量评估。

---

## 编译 KataGo

- 语言：C++（需 C++14 及以上）。
- Windows：MSVC 2017+ 或 MinGW；Linux/macOS：g++/clang 等。
- 详细步骤与依赖请参见 `Compiling.md`（含 zlib、Eigen3、OpenCL/CUDA/TensorRT 选项等）。

---

## 源代码结构概览

- C++ 与配置：`cpp/`、`cpp/configs/`
- Python 示例与工具：`python/`
- 文档：`docs/`

详见 `cpp/README.md` 与 `python/README.md`。

---

## 自对弈训练

参见 `SelfplayTraining.md`，包含从零训练与数据管线说明。

---

## 贡献者

感谢所有贡献者！完整列表见 `CONTRIBUTORS`。

---

## 许可证

除 `cpp/external/` 下若干第三方库及单文件 `cpp/core/sha2.cpp`（它们各自按独立许可证）外，其余代码与内容遵循仓库根目录 `LICENSE` 许可条款。

---

## 附：快速上手（5 分钟）

1) 准备三个文件在同一目录：
   - `katago.exe`
   - `default_gtp.cfg`（可先复制 `cpp/configs/gtp_example.cfg` 并按需调整）
   - `default_model.bin.gz`（从 https://katagotraining.org/ 下载一个最新模型并改名）

2) 运行基准测试以获得线程建议：

```
katago.exe benchmark
```

3) 根据输出建议修改 `default_gtp.cfg` 中的 `numSearchThreads`，然后启动引擎：

```
katago.exe gtp
```

4) 若使用 GUI，在其设置中把“引擎/命令”指向上面的命令或可执行文件路径即可。