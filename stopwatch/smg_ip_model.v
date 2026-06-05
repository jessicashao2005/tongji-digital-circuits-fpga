// 数码管封装模块（动态扫描 + 译码），实验6/7/8 共用
module smg_ip_model(clk, data, sm_wei, sm_duan);
    input        clk;
    input  [15:0] data;
    output [3:0]  sm_wei;
    output [7:0]  sm_duan;

    // 分频：产生数码管扫描时钟
    integer clk_cnt = 0;
    reg     clk_400Hz = 0;
    always @(posedge clk)
        if (clk_cnt == 32'd100000) begin
            clk_cnt   <= 0;
            clk_400Hz <= ~clk_400Hz;
        end else
            clk_cnt <= clk_cnt + 1'b1;

    // 位控制：四位轮流选通
    reg [3:0] wei_ctrl = 4'b1110;
    always @(posedge clk_400Hz)
        wei_ctrl <= {wei_ctrl[2:0], wei_ctrl[3]};

    // 段控制：取出当前位要显示的 4bit 数据（已反转，使高位在左、低位在右）
    reg [3:0] duan_ctrl;
    always @(*)
        case (wei_ctrl)
            4'b1110: duan_ctrl = data[15:12];
            4'b1101: duan_ctrl = data[11:8];
            4'b1011: duan_ctrl = data[7:4];
            4'b0111: duan_ctrl = data[3:0];
            default: duan_ctrl = 4'hf;
        endcase

    // 译码：数字 -> 七段码（共阴）
    reg [7:0] duan;
    always @(*)
        case (duan_ctrl)
            4'h0: duan = 8'b0011_1111;
            4'h1: duan = 8'b0000_0110;
            4'h2: duan = 8'b0101_1011;
            4'h3: duan = 8'b0100_1111;
            4'h4: duan = 8'b0110_0110;
            4'h5: duan = 8'b0110_1101;
            4'h6: duan = 8'b0111_1101;
            4'h7: duan = 8'b0000_0111;
            4'h8: duan = 8'b0111_1111;
            4'h9: duan = 8'b0110_1111;
            4'ha: duan = 8'b0111_0111;
            4'hb: duan = 8'b0111_1100;
            4'hc: duan = 8'b0011_1001;
            4'hd: duan = 8'b0101_1110;
            4'he: duan = 8'b0111_1000;
            4'hf: duan = 8'b0111_0001;
            default: duan = 8'b0011_1111;
        endcase

    assign sm_wei  = ~wei_ctrl;
    assign sm_duan = duan;
endmodule
