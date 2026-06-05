# 八位数码管时钟/秒表 约束文件 (EGO1)
set_property PACKAGE_PIN P17 [get_ports clk]
# S2(R15)启动  S0(R11)暂停/秒减  S6(P15)复位  S4(U4)记录  S1(R17)秒加  S3(V1)分加
set_property PACKAGE_PIN R15 [get_ports start]
set_property PACKAGE_PIN R11 [get_ports stop]
set_property PACKAGE_PIN P15 [get_ports rst]
set_property PACKAGE_PIN U4  [get_ports lap]
set_property PACKAGE_PIN R17 [get_ports inc]
set_property PACKAGE_PIN V1  [get_ports frac]
# sw0(R1) 模式: 下=正计时 上=定时    sw1(N4) 查阅开关
set_property PACKAGE_PIN R1  [get_ports mode]
set_property PACKAGE_PIN N4  [get_ports viewsw]

# 数码管位选 — 左四位 seg_cs[3:0] (HHMM)
set_property PACKAGE_PIN G2 [get_ports {sm_wei0[0]}]
set_property PACKAGE_PIN C2 [get_ports {sm_wei0[1]}]
set_property PACKAGE_PIN C1 [get_ports {sm_wei0[2]}]
set_property PACKAGE_PIN H1 [get_ports {sm_wei0[3]}]
# 数码管位选 — 右四位 seg_cs[7:4] (SSCC)
set_property PACKAGE_PIN G1 [get_ports {sm_wei1[0]}]
set_property PACKAGE_PIN F1 [get_ports {sm_wei1[1]}]
set_property PACKAGE_PIN E1 [get_ports {sm_wei1[2]}]
set_property PACKAGE_PIN G6 [get_ports {sm_wei1[3]}]

# 数码管段选 — 左四位 seg_data_0
set_property PACKAGE_PIN B4 [get_ports {sm_duan0[0]}]
set_property PACKAGE_PIN A4 [get_ports {sm_duan0[1]}]
set_property PACKAGE_PIN A3 [get_ports {sm_duan0[2]}]
set_property PACKAGE_PIN B1 [get_ports {sm_duan0[3]}]
set_property PACKAGE_PIN A1 [get_ports {sm_duan0[4]}]
set_property PACKAGE_PIN B3 [get_ports {sm_duan0[5]}]
set_property PACKAGE_PIN B2 [get_ports {sm_duan0[6]}]
set_property PACKAGE_PIN D5 [get_ports {sm_duan0[7]}]
# 数码管段选 — 右四位 seg_data_1
set_property PACKAGE_PIN D4 [get_ports {sm_duan1[0]}]
set_property PACKAGE_PIN E3 [get_ports {sm_duan1[1]}]
set_property PACKAGE_PIN D3 [get_ports {sm_duan1[2]}]
set_property PACKAGE_PIN F4 [get_ports {sm_duan1[3]}]
set_property PACKAGE_PIN F3 [get_ports {sm_duan1[4]}]
set_property PACKAGE_PIN E2 [get_ports {sm_duan1[5]}]
set_property PACKAGE_PIN D2 [get_ports {sm_duan1[6]}]
set_property PACKAGE_PIN H2 [get_ports {sm_duan1[7]}]

# LED 状态指示
set_property PACKAGE_PIN K2 [get_ports {led[0]}]
set_property PACKAGE_PIN J2 [get_ports {led[1]}]
set_property PACKAGE_PIN J3 [get_ports {led[2]}]
set_property PACKAGE_PIN H4 [get_ports {led[3]}]
set_property PACKAGE_PIN J4 [get_ports {led[4]}]
set_property PACKAGE_PIN G3 [get_ports {led[5]}]
set_property PACKAGE_PIN G4 [get_ports {led[6]}]
set_property PACKAGE_PIN F6 [get_ports {led[7]}]

# ---- IO 电平标准 ----
set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports start]
set_property IOSTANDARD LVCMOS33 [get_ports stop]
set_property IOSTANDARD LVCMOS33 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports lap]
set_property IOSTANDARD LVCMOS33 [get_ports inc]
set_property IOSTANDARD LVCMOS33 [get_ports frac]
set_property IOSTANDARD LVCMOS33 [get_ports mode]
set_property IOSTANDARD LVCMOS33 [get_ports viewsw]
set_property IOSTANDARD LVCMOS33 [get_ports {sm_wei0[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sm_wei1[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sm_duan0[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sm_duan1[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]