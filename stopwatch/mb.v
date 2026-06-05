// 八位数码管时钟/秒表顶层模块 (HH MM SS CC)
module mb(clk, start, stop, rst, lap, inc, frac, mode, viewsw,
          sm_wei0, sm_wei1, sm_duan0, sm_duan1, led);
    input        clk;         // P17 100MHz
    input        start;       // S2(R15) 启动/继续 / 查阅时翻组
    input        stop;        // S0(R11) 暂停 / 设置时秒-
    input        rst;         // S6(P15) 复位
    input        lap;         // S4(U4)  记录当前显示读数
    input        inc;         // S1(R17) 设置时秒+
    input        frac;        // S3(V1)  设置时分+
    input        mode;        // sw0(R1) 0=正计时 1=定时
    input        viewsw;      // sw1(N4) 查阅开关
    output [3:0] sm_wei0;     // 左四位位选 (seg_cs[3:0])
    output [3:0] sm_wei1;     // 右四位位选 (seg_cs[7:4])
    output [7:0] sm_duan0;    // 左四位段选 (seg_data_0, HHMM)
    output [7:0] sm_duan1;    // 右四位段选 (seg_data_1, SSCC)
    output [7:0] led;

    wire [31:0] data;

    time_counter U0 (.clk(clk), .start(start), .stop(stop), .rst(rst),
                     .lap(lap), .inc(inc), .frac(frac), .mode(mode), .viewsw(viewsw),
                     .data(data), .led(led));
    smg_ip_model U1 (.clk(clk), .data(data),
                     .sm_wei0(sm_wei0), .sm_wei1(sm_wei1),
                     .sm_duan0(sm_duan0), .sm_duan1(sm_duan1));
endmodule