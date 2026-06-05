// 交通灯核心逻辑（开关选择 + 编辑 + 灯测试版）
//   SW0 拨上=进入编辑模式；SW1~SW4 选择修改的绿灯时间：
//       SW1 南北直行  SW2 东西直行  SW3 东西转弯  SW4 南北转弯（优先级 SW1>SW2>SW3>SW4）
//   S3 选中项 +1   S0 选中项 -1   范围 0~99（支持长按连续加减）
//   S2 按一下进入/退出“灯测试模式”：数码管显示 99，SW0~SW7 直接控制 8 个 LED 亮灭
//   数码管只点亮右两位，左两位熄灭
//   lights: [0]南北红 [1]南北黄 [2]南北绿 [3]东西红 [4]东西黄 [5]东西绿
//           [6]南北左转绿 [7]东西左转绿
module test(clk, sw, key_inc, key_dec, s2, data, lights);
    input             clk;
    input      [7:0]  sw;        // SW0~SW7 拨码开关
    input             key_inc;   // S3(V1) +1
    input             key_dec;   // S0(R11) -1
    input             s2;        // S2(R15) 按一下切换灯测试模式
    output reg [15:0] data;
    output reg [7:0]  lights;

    // ---- 精确 1 秒脉冲 ----
    localparam CLK_HZ = 32'd100000000;
    reg [31:0] cnt = 0;  reg tick_1s = 0;
    always @(posedge clk)
        if (cnt == CLK_HZ - 1) begin cnt <= 0; tick_1s <= 1; end
        else begin cnt <= cnt + 1; tick_1s <= 0; end

    // ---- 黄灯/左转 闪烁 1Hz ----
    wire blink = (cnt >= CLK_HZ/2);

    // ---- 去抖采样：每 ~10ms 一个 stick ----
    reg [19:0] scnt = 0;  reg stick = 0;
    always @(posedge clk)
        if (scnt == 20'd1000000 - 1) begin scnt <= 0; stick <= 1; end
        else begin scnt <= scnt + 1; stick <= 0; end

    // ---- S2 边沿：按一下切换灯测试模式 ----
    reg s2a=0, s2b=0, s2_p=0;
    reg test_mode = 0;
    always @(posedge clk) begin
        s2_p <= 0;
        if (stick) begin
            if (s2a && !s2b) s2_p <= 1;
            s2b <= s2a; s2a <= s2;
        end
    end
    always @(posedge clk) if (s2_p) test_mode <= ~test_mode;

    wire edit = sw[0] & ~test_mode;   // 灯测试时不算编辑

    // ---- 加/减键：按下即触发，按住 0.4s 后每 0.16s 自动重复 ----
    reg [7:0] h_inc=0, h_dec=0;
    reg       p_inc=0, p_dec=0;
    reg       r_inc=0, r_dec=0;
    always @(posedge clk) begin
        p_inc<=0; p_dec<=0;
        if (stick) begin
            r_inc<=key_inc; r_dec<=key_dec;
            if (r_inc) begin h_inc<=h_inc+1;
                if (h_inc==8'd0) p_inc<=1;
                else if (h_inc>=8'd40 && h_inc[3:0]==4'd0) p_inc<=1;
            end else h_inc<=0;
            if (r_dec) begin h_dec<=h_dec+1;
                if (h_dec==8'd0) p_dec<=1;
                else if (h_dec>=8'd40 && h_dec[3:0]==4'd0) p_dec<=1;
            end else h_dec<=0;
        end
    end

    // ---- 4 个可调绿灯时长 (0~99) ----
    reg [6:0] t_ns_str = 7'd25;  // 南北直行
    reg [6:0] t_we_str = 7'd15;  // 东西直行
    reg [6:0] we_turn  = 7'd10;  // 东西转弯
    reg [6:0] ns_turn  = 7'd10;  // 南北转弯

    // 通道选择（优先级 SW1>SW2>SW3>SW4）
    wire sel_ns_str  = sw[1];
    wire sel_we_str  = sw[2] & ~sw[1];
    wire sel_we_turn = sw[3] & ~sw[2] & ~sw[1];
    wire sel_ns_turn = sw[4] & ~sw[3] & ~sw[2] & ~sw[1];

    always @(posedge clk) begin
        if (edit) begin
            if (p_inc) begin
                if      (sel_ns_str ) begin if (t_ns_str<7'd99) t_ns_str<=t_ns_str+1; end
                else if (sel_we_str ) begin if (t_we_str<7'd99) t_we_str<=t_we_str+1; end
                else if (sel_we_turn) begin if (we_turn <7'd99) we_turn <=we_turn +1; end
                else if (sel_ns_turn) begin if (ns_turn <7'd99) ns_turn <=ns_turn +1; end
            end
            if (p_dec) begin
                if      (sel_ns_str ) begin if (t_ns_str>7'd0) t_ns_str<=t_ns_str-1; end
                else if (sel_we_str ) begin if (t_we_str>7'd0) t_we_str<=t_we_str-1; end
                else if (sel_we_turn) begin if (we_turn >7'd0) we_turn <=we_turn -1; end
                else if (sel_ns_turn) begin if (ns_turn >7'd0) ns_turn <=ns_turn -1; end
            end
        end
    end

    // ---- 黄灯固定时长 ----
    localparam T_YEL = 7'd3;

    // ---- 正常 6 相位 FSM（始终运行）----
    // 0南北绿 1南北黄 2南北左转 3东西绿 4东西黄 5东西左转 -> 回0
    reg [2:0] st = 0;  reg [6:0] tmr = 7'd25;
    always @(posedge clk) begin
        if (tick_1s) begin
            if (tmr <= 1) begin
                if (st >= 3'd5) st <= 0;
                else st <= st + 1;
                case (st)
                    0: tmr <= T_YEL;     // 南北绿->南北黄
                    1: tmr <= ns_turn;   // 南北黄->南北左转
                    2: tmr <= t_we_str;  // 南北左转->东西绿
                    3: tmr <= T_YEL;     // 东西绿->东西黄
                    4: tmr <= we_turn;   // 东西黄->东西左转
                    5: tmr <= t_ns_str;  // 东西左转->南北绿
                endcase
            end else tmr <= tmr - 1;
        end
    end

    // ---- 显示译码（只用右两位，左两位 4'hf=熄灭）----
    wire [3:0] c_ten = tmr / 10, c_one = tmr % 10;       // 正常倒计时

    // 编辑模式：选中通道的值与编号
    reg [6:0] sel_val;
    reg [3:0] ch;
    always @(*) begin
        if      (sel_ns_str ) begin sel_val = t_ns_str; ch = 4'd1; end
        else if (sel_we_str ) begin sel_val = t_we_str; ch = 4'd2; end
        else if (sel_we_turn) begin sel_val = we_turn;  ch = 4'd3; end
        else if (sel_ns_turn) begin sel_val = ns_turn;  ch = 4'd4; end
        else                  begin sel_val = 7'd0;     ch = 4'd0; end
    end
    wire [3:0] s_ten = sel_val / 10, s_one = sel_val % 10;

    always @(*) begin
        if (test_mode) begin
            // ---- 灯测试模式：8 个开关直接控制 8 个 LED ----
            // 位序反转：使 SW7->LED7, SW0->LED0（物理上原本 SW7 对应 LD0）
            lights = {sw[0], sw[1], sw[2], sw[3], sw[4], sw[5], sw[6], sw[7]};
            data   = {4'hf, 4'hf, 4'd9, 4'd9};        // 右两位 99，左两位熄灭
        end else begin
            // ---- LED 反映 FSM 当前相位 ----
            // 左转灯始终有状态：常亮=允许左转，闪烁=不允许（基线设为闪烁）
            lights = 8'b0;
            lights[6] = blink;   // 南北左转：默认闪烁(不允许)
            lights[7] = blink;   // 东西左转：默认闪烁(不允许)
            case (st)
                0: begin lights[2]=1;     lights[3]=1; end          // 南北绿,    东西红
                1: begin lights[1]=blink; lights[3]=1; end          // 南北黄闪,  东西红
                2: begin lights[6]=1; lights[0]=1; lights[3]=1; end // 南北左转绿(常亮)+南北红+东西红
                3: begin lights[5]=1;     lights[0]=1; end          // 东西绿,    南北红
                4: begin lights[4]=blink; lights[0]=1; end          // 东西黄闪,  南北红
                5: begin lights[7]=1; lights[3]=1; lights[0]=1; end // 东西左转绿(常亮)+东西红+南北红
            endcase

            // ---- 数码管：只用右两位 ----
            if (edit & ch!=0) data = {4'hf, 4'hf, s_ten, s_one};   // 选中通道:右两位=值
            else              data = {4'hf, 4'hf, c_ten, c_one};   // 未选/正常:右两位=倒计时
        end
    end
endmodule

