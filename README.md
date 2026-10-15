# Tang Mega 60K · TX35 USB键盘接入与VOFA正弦验证

USB键盘实验的源码快照、连接使用说明与后续演奏规划。2026-10-15用户确认USB项目连接成功；这里没有宣称全部键位、六键无冲突或总延迟已经验收。

## 阅读入口

- [键盘资料、接线、初始化及代码](docs/KEYBOARD_GUIDE.md)
- [键位映射提案——待审阅，不是现有功能](docs/KEYMAP_PROPOSAL.md)
- [赛题对照及滑音等功能计划](docs/FEATURE_ROADMAP.md)
- [验证记录](docs/VERIFICATION.md) / [源码清单](docs/source-manifest.json) / [第三方来源](THIRD_PARTY_NOTICES.md)

## 当前功能

- 板载KEY1：按一次开启串口正弦，再按一次停止；KEY2复位。
- USB键盘A：按住发送、松开停止；KEY1已开启时松开A不停止。
- VOFA：921600、8N1、无流控、JustFloat，单通道I0，Δt≈0.1658ms。
- 空闲不发数据；VOFA可能保留历史波形。耳机沿用原例程，持续输出约440Hz正弦，按键只控制UART。
- 板载彩灯：绿等待键盘类型，蓝识别接口，紫A状态成立。

## 构建

目标器件GW5AT-LV60PG484AC1/I0，Tang Mega NEO Dock。USB-A旁USBA Switch小滑动开关置FPGA侧，不是蓝色六位拨码开关。
电脑连接调试串口，COM号按本机识别选择。Gowin V1.9.12.03，ModelSim 10.5b已用于此工程。

```powershell
# 仓库根目录运行；工具路径按本机安装位置调整
& 'D:/gowin/Gowin_V1.9.12.03_x64/IDE/bin/gw_sh.exe' build.tcl
# 输出 impl/pnr/audio_tone.fs
vsim.exe -c -do sim/run_usb.do
```

也可打开audio_tone.gprj。所有构建输入包含在仓库；不上传本机缓存、竞赛PDF、大型位流或私人工作目录。位流请本地构建。

## 范围

本仓库仅有A键测试。键位映射与新功能需要用户审阅后再实施，未写进RTL。钢琴/吉他主引擎另行维护，本次没有修改它。
USB采用UKP微程序协议控制，不参与声音计算；不要把它描述为整机完全不存在指令执行，也不要将音频通路HDL合规与协议控制实现混为一谈。
