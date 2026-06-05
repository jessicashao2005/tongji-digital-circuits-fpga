// 八位数码管封装模块 (动态扫描 + 译码), EGO1 双段总线
//   data: 8 位 BCD, [31:16]=左四位(HHMM)  [15:0]=右四位(SSCC)
//   两组数码管共用 4 位位选(sm_wei), 同步扫描:
//     sm_duan0 驱动左 4 位(seg_data_0)  sm_duan1 驱动右 4 位(seg_data_1)
module smg_ip_model(clk, data, sm_wei0, sm_wei1, sm_duan0, sm_duan1);
    input         clk;
    input  [31:0] data;
    output [3:0]  sm_wei0;     // 左四位位选 (seg_cs[3:0])
    output [3:0]  sm_wei1;     // 右四位位选 (seg_cs[7:4])
    output [7:0]  sm_duan0;
    output [7:0]  sm_duan1;

    // 分频: 数码管扫描时钟
    integer clk_cnt = 0;
    reg     clk_400Hz = 0;
    always @(posedge clk)
        if (clk_cnt == 32'd100000) begin
            clk_cnt   <= 0;
            clk_400Hz <= ~clk_400Hz;
        end else
            clk_cnt <= clk_cnt + 1'b1;

    // 位控制: 四位轮流选通
    reg [3:0] wei_ctrl = 4'b1110;
    always @(posedge clk_400Hz)
        wei_ctrl <= {wei_ctrl[2:0], wei_ctrl[3]};

    // 当前位的两组 4bit 数据(高位在左)
    reg [3:0] d0_ctrl, d1_ctrl;
    always @(*)
        case (wei_ctrl)
            4'b1110: begin d0_ctrl = data[31:28]; d1_ctrl = data[15:12]; end
            4'b1101: begin d0_ctrl = data[27:24]; d1_ctrl = data[11:8];  end
            4'b1011: begin d0_ctrl = data[23:20]; d1_ctrl = data[7:4];   end
            4'b0111: begin d0_ctrl = data[19:16]; d1_ctrl = data[3:0];   end
            default: begin d0_ctrl = 4'hf;        d1_ctrl = 4'hf;        end
        endcase

    // 共阴七段译码函数
    function [7:0] seg7;
        input [3:0] v;
        case (v)
            4'h0: seg7 = 8'b0011_1111;
            4'h1: seg7 = 8'b0000_0110;
            4'h2: seg7 = 8'b0101_1011;
            4'h3: seg7 = 8'b0100_1111;
            4'h4: seg7 = 8'b0110_0110;
            4'h5: seg7 = 8'b0110_1101;
            4'h6: seg7 = 8'b0111_1101;
            4'h7: seg7 = 8'b0000_0111;
            4'h8: seg7 = 8'b0111_1111;
            4'h9: seg7 = 8'b0110_1111;
            4'ha: seg7 = 8'b0111_0111;
            4'hb: seg7 = 8'b0111_1100;
            4'hc: seg7 = 8'b0011_1001;
            4'hd: seg7 = 8'b0101_1110;
            4'he: seg7 = 8'b0111_1000;
            4'hf: seg7 = 8'b0111_0001;
            default: seg7 = 8'b0011_1111;
        endcase
    endfunction

    assign sm_wei0  = ~wei_ctrl;        // 左四位低有效位选
    assign sm_wei1  = ~wei_ctrl;        // 右四位同步选通
    assign sm_duan0 = seg7(d0_ctrl);
    assign sm_duan1 = seg7(d1_ctrl);
endmodule
