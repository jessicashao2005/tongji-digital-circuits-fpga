// 秒表顶层模块（分段记圈 + 查阅版）
module mb(clk, start, stop, rst, lap, inc, frac, mode, viewsw,
          sm_wei, sm_duan, led);
    input        clk;         // P17 100MHz
    input        start;       // S2(R15) 启动/继续 / 查阅时翻组
    input        stop;        // S0(R11) 停止 / 设置时秒-
    input        rst;         // S6(P15) 复位
    input        lap;         // S4(U4)  记圈(分段)
    input        inc;         // S1(R17) 设置时秒+
    input        frac;        // S3(V1)  设置时小数位+(0.1s, 0-9循环)
    input        mode;        // sw0(R1) 0=正计时 1=定时
    input        viewsw;      // sw1(N4) 查阅开关
    output [3:0] sm_wei;
    output [7:0] sm_duan;
    output [7:0] led;

    wire [15:0] data;

    time_counter U0 (.clk(clk), .start(start), .stop(stop), .rst(rst),
                     .lap(lap), .inc(inc), .frac(frac), .mode(mode), .viewsw(viewsw),
                     .data(data), .led(led));
    smg_ip_model U1 (.clk(clk), .data(data), .sm_wei(sm_wei), .sm_duan(sm_duan));
endmodule
