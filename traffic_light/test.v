// 交通灯核心逻辑（编辑模式版，南北/东西转弯时间独立可调）
//   S2 进/出编辑；编辑模式下数码管左两位=南北转弯秒、右两位=东西转弯秒
//   S1 南北+  S0 南北-   S4 东西+  S3 东西-   （均支持长按连续加减，上限99）
//   lights: [0]南北红 [1]南北黄 [2]南北绿 [3]东西红 [4]东西黄 [5]东西绿
//           [6]南北左转绿 [7]东西左转绿
module test(clk, ns_inc, ns_dec, we_inc, we_dec, s2, data, lights);
    input             clk, ns_inc, ns_dec, we_inc, we_dec, s2;
    output reg [15:0] data;
    output reg [7:0]  lights;

    // ---- 精确 1 秒脉冲 ----
    localparam CLK_HZ = 32'd100000000;
    reg [31:0] cnt = 0;  reg tick_1s = 0;
    always @(posedge clk)
        if (cnt == CLK_HZ - 1) begin cnt <= 0; tick_1s <= 1; end
        else begin cnt <= cnt + 1; tick_1s <= 0; end

    // ---- 黄灯/左转 闪烁 1Hz（黄灯3秒正好闪3次）----
    wire blink = (cnt >= CLK_HZ/2);

    // ---- 去抖采样：每 ~10ms 一个 stick ----
    reg [19:0] scnt = 0;  reg stick = 0;
    always @(posedge clk)
        if (scnt == 20'd1000000 - 1) begin scnt <= 0; stick <= 1; end
        else begin scnt <= scnt + 1; stick <= 0; end

    // ---- S2 边沿（仅单次切换）----
    reg s2a=0, s2b=0, s2_p=0;
    always @(posedge clk) begin
        s2_p <= 0;
        if (stick) begin
            if (s2a && !s2b) s2_p <= 1;
            s2b <= s2a; s2a <= s2;
        end
    end

    // ---- 4 个调节键：按下即触发，按住 0.4s 后每 0.16s 自动重复 ----
    // 每个键一份 8bit 按住计数 hold；hold==1 首次触发；hold>=40 且低4位为0 重复
    reg [7:0] h_ni=0, h_nd=0, h_wi=0, h_wd=0;
    reg       p_ni=0, p_nd=0, p_wi=0, p_wd=0;
    reg       r_ni=0, r_nd=0, r_wi=0, r_wd=0;  // 同步寄存
    always @(posedge clk) begin
        p_ni<=0; p_nd<=0; p_wi<=0; p_wd<=0;
        if (stick) begin
            r_ni<=ns_inc; r_nd<=ns_dec; r_wi<=we_inc; r_wd<=we_dec;
            // 南北 +
            if (r_ni) begin h_ni<=h_ni+1;
                if (h_ni==8'd0) p_ni<=1;
                else if (h_ni>=8'd40 && h_ni[3:0]==4'd0) p_ni<=1;
            end else h_ni<=0;
            // 南北 -
            if (r_nd) begin h_nd<=h_nd+1;
                if (h_nd==8'd0) p_nd<=1;
                else if (h_nd>=8'd40 && h_nd[3:0]==4'd0) p_nd<=1;
            end else h_nd<=0;
            // 东西 +
            if (r_wi) begin h_wi<=h_wi+1;
                if (h_wi==8'd0) p_wi<=1;
                else if (h_wi>=8'd40 && h_wi[3:0]==4'd0) p_wi<=1;
            end else h_wi<=0;
            // 东西 -
            if (r_wd) begin h_wd<=h_wd+1;
                if (h_wd==8'd0) p_wd<=1;
                else if (h_wd>=8'd40 && h_wd[3:0]==4'd0) p_wd<=1;
            end else h_wd<=0;
        end
    end

    // ---- 模式 + 两个独立转弯时长 (1~99) ----
    reg       edit = 0;
    reg [6:0] ns_turn = 7'd10, we_turn = 7'd10;
    always @(posedge clk) begin
        if (s2_p) edit <= ~edit;
        if (edit) begin
            if (p_ni & (ns_turn < 7'd99)) ns_turn <= ns_turn + 1;
            if (p_nd & (ns_turn > 7'd1 )) ns_turn <= ns_turn - 1;
            if (p_wi & (we_turn < 7'd99)) we_turn <= we_turn + 1;
            if (p_wd & (we_turn > 7'd1 )) we_turn <= we_turn - 1;
        end
    end

    // ---- 时间参数 ----
    localparam T_NS = 7'd25, T_WE = 7'd15, T_YEL = 7'd3;

    // ---- 正常模式 6 相位 ----
    // 0南北绿 1南北黄 2南北左转 3东西绿 4东西黄 5东西左转 -> 回0
    // 左转结束后直接切对向绿灯(红->绿直接转，无黄)；只有直行绿->红才经黄
    reg [2:0] st = 0;  reg [6:0] tmr = T_NS;
    always @(posedge clk) begin
        if (edit) begin st <= 0; tmr <= T_NS; end
        else if (tick_1s) begin
            if (tmr <= 1) begin
                if (st >= 3'd5) st <= 0;
                else st <= st + 1;
                case (st)
                    0: tmr <= T_YEL;     // 南北绿->南北黄
                    1: tmr <= ns_turn;   // 南北黄->南北左转
                    2: tmr <= T_WE;      // 南北左转->东西绿(直接)
                    3: tmr <= T_YEL;     // 东西绿->东西黄
                    4: tmr <= we_turn;   // 东西黄->东西左转
                    5: tmr <= T_NS;      // 东西左转->南北绿(直接)
                endcase
            end else tmr <= tmr - 1;
        end
    end

    // ---- 编辑模式 4 相位演示 ----
    reg [1:0] est = 0;  reg [6:0] etmr = T_WE;
    always @(posedge clk) begin
        if (~edit) begin est <= 0; etmr <= T_WE; end
        else if (tick_1s) begin
            if (etmr <= 1) begin
                est <= est + 1;
                case (est)
                    0: etmr <= T_YEL;
                    1: etmr <= T_NS;
                    2: etmr <= T_YEL;
                    3: etmr <= T_WE;
                endcase
            end else etmr <= etmr - 1;
        end
    end

    // ---- 数码管 ----
    wire [3:0] c_ten = tmr / 10, c_one = tmr % 10;        // 正常倒计时
    wire [3:0] ns_t  = ns_turn/10, ns_o = ns_turn%10;     // 编辑:南北
    wire [3:0] we_t  = we_turn/10, we_o = we_turn%10;     // 编辑:东西

    always @(*) begin
        lights = 8'b0;
        if (edit) begin
            data = {ns_t, ns_o, we_t, we_o};        // 左两位南北, 右两位东西
            lights[6] = blink; lights[7] = blink;   // 两个左转绿常闪
            case (est)
                0: begin lights[0]=1; lights[5]=1;     end
                1: begin lights[0]=1; lights[4]=blink; end
                2: begin lights[3]=1; lights[2]=1;     end
                3: begin lights[3]=1; lights[1]=blink; end
            endcase
        end else begin
            data = {c_ten, c_one, c_ten, c_one};
            case (st)
                0: begin lights[2]=1;     lights[3]=1; end              // 南北绿,    东西红
                1: begin lights[1]=blink; lights[3]=1; end              // 南北黄闪,  东西红
                2: begin lights[6]=1; lights[0]=1; lights[3]=1; end     // 南北左转绿+南北红+东西红
                3: begin lights[5]=1;     lights[0]=1; end              // 东西绿,    南北红
                4: begin lights[4]=blink; lights[0]=1; end              // 东西黄闪,  南北红
                5: begin lights[7]=1; lights[3]=1; lights[0]=1; end     // 东西左转绿+东西红+南北红
            endcase
        end
    end
endmodule
