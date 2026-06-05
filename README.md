# 同济大学 数字电路实验 — FPGA 大作业
（感谢kiro 老登希望能帮学弟学妹们省点时间吧 我其实根本没耐心看23G的资料）

基于 **EGO1 开发板**（Xilinx Artix-7 XC7A35T，`xc7a35tcsg324-1`）、**Vivado** 完成的两个 Verilog 设计。

## 目录结构

```
.
├── traffic_light/   交通灯
│   ├── smg.v            顶层模块
│   ├── test.v           交通灯核心逻辑（状态机 + 编辑模式）
│   ├── smg_ip_model.v   数码管动态扫描显示
│   └── traffic.xdc      引脚约束
└── stopwatch/       秒表
    ├── mb.v             顶层模块
    ├── time_counter.v   计时核心（正计时/定时倒计时/记圈）
    ├── smg_ip_model.v   数码管动态扫描显示
    └── stopwatch.xdc    引脚约束
```

## 如何在 Vivado 中重建工程

1. 新建 RTL Project，器件选 `xc7a35tcsg324-1`
2. Add Sources → 添加该作业目录下的 3 个 `.v` 文件
3. Add Constraints → 添加 `.xdc` 文件
4. 设顶层：交通灯为 `smg`，秒表为 `mb`
5. Generate Bitstream → Program Device 下载到板子

> 仓库只保存源码（`.v` / `.xdc`）。不包含 Vivado 工程文件（`.xpr`）和编译产物（`.runs` / `.cache`），因为它们体积大且与本机路径绑定，不可移植。

## 交通灯功能

南北/东西双向红黄绿 + 左转相位，数码管倒计时；黄灯 1Hz 闪烁；
按 S2 进入编辑模式，可独立调节南北/东西左转绿灯时长（支持长按连续加减）。

## 秒表功能

正计时与定时倒计时双模式（SW0 切换）；0.1s 精度；
启动/暂停/复位；S4 分段记圈、保存 5 组并可查阅；
定时模式可用按键设定秒数与 0.1s 小数位，倒计时到 0 闪烁提示。
