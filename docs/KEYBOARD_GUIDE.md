# TX35 键盘使用阅读

## 硬件重要资料

实物：LIMEIDE TX35 COLORFUL，USB，5V/100mA。照片为全尺寸QWERTY，含F1～F12、导航区、方向键、小键盘及Fn。
2026-10-14 Windows设备查询如下。当时未做拔插差分，VID/PID与实物绑定仍保留该限制；2026-10-15使用者确认USB连接成功。

| 字段 | 值 |
|---|---|
| 产品字符串 | CASUE USB KB |
| VID/PID | 2A7A/959F |
| 实际连接速度 | Low-speed 1.5Mbps，来自连接状态查询 |
| bcdUSB / bcdDevice | 0x0110 / 0x0001 |
| EP0最大包 | 8字节 |
| 接口0 | HID/Boot/Keyboard，03/01/01 |
| 键盘端点 | 0x81，中断IN，最大8字节，间隔10ms |
| 接口0报告描述符 | 声明64字节，未读取内容 |
| 接口1 | HID非Boot；0x82，最大4字节，间隔10ms |
| 接口1报告描述符 | 声明129字节，内容/用途未确认 |
| 电流 | 配置声明100mA，不是实测消耗 |

六个Boot普通键槽不代表任意六键组合无冲突。Fn可能由键盘内部处理，多媒体可能走接口1；不用它们做关键控制。普通键盘没有压力/力度传感值。

## 接线与开关

| 信号 | FPGA引脚 | 电气/用途 |
|---|---|---|
| USB D+/D− | H13/G13 | USB-A2实际线路，LVCMOS33 |
| 外部时钟 | V22 | 50MHz |
| 板载KEY1/KEY2 | AB13/Y12 | 低有效，LVCMOS15上拉 |
| UART_TX | U15 | 3.3V，底板串口链路 |
| WS2812 | J16 | 状态彩灯 |
| 音频BCK/WS/DIN | Y17/AB17/AA16 | DAC输出 |
| PA_EN | AB16 | 低有效功放开关 |

USB-A插座上方USBA Switch小滑动开关选FPGA侧。DBG侧接调试芯片；不等于整板调试模式。参考31004原理图第9页，VBUS由5V_Peripheral经U41限流开关供给，软件不能替代物理供电。背光和锁定灯可能依赖主机命令，不以键盘是否亮灯单独判断枚举。

## 初始化与源码索引

1. `src/top.v`：OSCA/4提供52.5MHz音频与串口时钟；KEY2同步释放后startup计数形成ready。
2. `src/usb_pll.v`、`usb_pll_mod.v`、`pll_init.v`：官方60K PLLA初始化；50MHz输入，倍频24形成1200MHz VCO，输出分频100得到12MHz。含PLL_INIT校准流程。
3. PLL锁定后USB域计数释放usb_ready，再开始主机枚举。
4. `src/usb_hid_host.v`中的UKP读取`usb_hid_host_rom.v/.hex`。上游可读微程序见[upstream_ukp.s](upstream_ukp.s)：等待设备、约200ms连接等待、总线复位、读取配置/接口0、再次复位、设置地址1与配置1，再轮询端点1。
5. 当前是紧凑低速HID核心，不是通用USB协议栈。没有添加SET_PROTOCOL、SET_IDLE、LED SET_REPORT或背光厂商命令；不得据此保证所有键盘/Hub兼容。
6. `dbg_hid_report`包含8个字节，byte0在低位，report为报告完成脉冲。
7. `src/usb_a_key.v`扫描byte2～7的0x04；正常空报告清除A，rollover错误1～3保留旧状态，非键盘类型清除A。
8. A、键盘类型判定、PLL锁定各以单比特两级同步进入音频域。未来整个报告必须使用握手快照或FIFO，不逐位随意跨域。
9. `tone_enable=key1_enable|a_down`；正弦连续运行，原版`vofa_uart`控制发送开启。USB不应阻塞KEY1的串口测试路径。

相对路径`src/usb_hid_host_rom.hex`要求在仓库根目录构建和仿真。阅读用ukp.s不在build.tcl中自动重新汇编；实际构建使用已复制ROM。

## HID报告示例

```text
byte0: Ctrl/Shift/Alt等修饰键位图
byte1: 保留
byte2..7: 普通键usage集合，槽位置可变化
A按住: 00 00 04 00 00 00 00 00
松开:  00 00 00 00 00 00 00 00
```

HID usage 0x04不是ASCII 'a'=0x61，在VOFA发送框输入a不会模拟USB键盘。
[标准：USB-IF Keyboard/Keypad Usage Page 0x07](https://www.usb.org/sites/default/files/hut1_5.pdf)。

## VOFA与操作

串口921600、8N1、无流控、JustFloat、I0、Δt≈0.1658ms。
帧为小端float32加`00 00 80 7F`。实际波特率约921052.6（52.5MHz/57）；约48253.676Hz音频，每8帧抽取一次，约6031.71点/秒。
KEY1切换，A保持；任意一个开启均发送。上电不按不发送。KEY2复位清除KEY1状态；A若仍按住，枚举后可能恢复发送。耳机当前持续输出正弦，不能用听到声音推断UART已开启。

## 排障和边界

- 多个工程的位流都叫audio_tone.fs，核对完整路径和生成时间。
- 先KEY2复位、KEY1开启，独立验证UART，再看USB的绿/蓝/紫。
- 蓝色仅表示接口类型识别，紫色表示A状态成立，不代替USB抓包。
- 没字节、收到全零、有字节但图表不显示，是三种问题。先看原始字节再改RTL。
- 关闭VOFA后读取原始COM数据时仍须保证发送开启。串口同时只能被一个程序占用。
- 烧录/拔插可能中止Windows串口I/O，应等设备恢复后重连，不能只凭报错判定硬件坏。
- 10ms端点轮询间隔不是总延迟；键盘扫描、等待、调度和起音均需计入。
- 尚未验收所有键、任意多键、长期热插拔、真实响应时间、LED回写及接口1。
