// 交通灯顶层模块（编辑模式版，南北/东西独立调时间）
module smg(clk, ns_inc, ns_dec, we_inc, we_dec, s2, sm_wei, sm_duan, led_panel);
    input        clk;        // P17 100MHz
    input        ns_inc;     // S1(R17) 南北转弯 +
    input        ns_dec;     // S0(R11) 南北转弯 -
    input        we_inc;     // S4(U4)  东西转弯 +
    input        we_dec;     // S3(V1)  东西转弯 -
    input        s2;         // S2(R15) 进/出编辑模式
    output [3:0] sm_wei;
    output [7:0] sm_duan;
    output [7:0] led_panel;

    wire [15:0] data;

    test         U0 (.clk(clk), .ns_inc(ns_inc), .ns_dec(ns_dec),
                     .we_inc(we_inc), .we_dec(we_dec), .s2(s2),
                     .data(data), .lights(led_panel));
    smg_ip_model U1 (.clk(clk), .data(data), .sm_wei(sm_wei), .sm_duan(sm_duan));
endmodule
