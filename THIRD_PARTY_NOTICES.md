# 第三方来源与许可证边界

- USB Host：Sipeed官方示例 https://github.com/sipeed/TangMega-138K-example 引用 https://github.com/AlanCui4080/sipeed_usb_hid_host_138k ，上游基于nand2mario/hi631。保留USB_HOST_LICENSE（Apache-2.0）及原文件注释。改动：数组范围/声明兼容、显式复位、60K集成；新增A状态提取。
- PLL初始化来自 https://github.com/sipeed/TangMega-60K-example 的 ch569_hspi2cdc/CH569_HSPI_FPGA_60K；Sipeed仓库Apache-2.0。Gowin生成的PLL/OSC包装保留原版权注释及工具器件信息，PLL输出分频为本项目12MHz适配；Gowin工具及器件库需用户自行安装，不随仓库再分发。
- 正弦表源于本地保存的Sipeed TangMega138KPro audio_sinewave示例，当前表及输出驱动来自工作工程TangMega60K_vofashuchu。该本地示例快照未找到独立LICENSE，未替其版权持有人重新授权；进一步分发/商用须核实上游条款。
- 其他工程集成、UART、状态灯和文档来自本项目。未给所有混合来源文件强行套统一许可证；各文件保留原有声明。
- USB-IF规范仅提供链接，不转载PDF。赛题PDF只用于本地阅读，发布文档为要求摘要而非完整文件。

上游快照提交：USB Host `5370379525dde1a25561bcf250dd9f18a023180d`；60K示例 `f0347d830305ef3efb921f47bb51701e569beefd`。
