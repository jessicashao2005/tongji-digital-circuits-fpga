// 交通灯顶层模块（开关选择 + 编辑 + 灯测试版）
//   SW0 进入编辑模式；SW1~SW4 选择修改 南北直行/东西直行/东西转弯/南北转弯 绿灯时间
//   S3 +1   S0 -1   范围 0~99
//   S2 按一下进入/退出灯测试模式：数码管显示 99，SW0~SW7 直接控制 8 个 LED
module smg(clk, sw, key_inc, key_dec, s2, sm_wei, sm_duan, led_panel);
    input        clk;        // P17 100MHz
    input [7:0]  sw;         // SW0~SW7 拨码开关
    input        key_inc;    // S3(V1) +1
    input        key_dec;    // S0(R11) -1
    input        s2;         // S2(R15) 切换灯测试模式
    output [3:0] sm_wei;
    output [7:0] sm_duan;
    output [7:0] led_panel;

    wire [15:0] data;

    test         U0 (.clk(clk), .sw(sw), .key_inc(key_inc), .key_dec(key_dec),
                     .s2(s2), .data(data), .lights(led_panel));
    smg_ip_model U1 (.clk(clk), .data(data), .sm_wei(sm_wei), .sm_duan(sm_duan));
endmodule
