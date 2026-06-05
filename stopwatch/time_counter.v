// 八位数码管计时核心  (HH MM SS CC = 时-分-秒-厘秒)
//   时 00-23(24进制)  分/秒 00-59(60进制)  厘秒 00-99(100进制, 0.01s)
//   SW0(mode):  0=正计时   1=定时倒计时
//   SW1(viewsw):查阅开关，拨上后每按 S2 切换查看第 0~4 组记录
//   S2 启动/继续(查阅态=翻组)   S0 暂停 / 设置态秒-
//   S6 复位   S4 记录“当前数码管显示的读数”(时刻, 非时间段)
//   S1 设置态秒+    S3 设置态分+   (仅定时模式未启动时为设置态)
module time_counter(clk, start, stop, rst, lap, inc, frac, mode, viewsw, data, led);
    input         clk, start, stop, rst, lap, inc, frac, mode, viewsw;
    output [31:0] data;            // 8 位 BCD
    output reg [7:0] led;

    // ---- 厘秒节拍: 100MHz / 1,000,000 = 100Hz (10ms) ----
    reg [31:0] cnt = 0;  reg tick = 0;
    always @(posedge clk)
        if (cnt == 32'd1000000 - 1) begin cnt <= 0; tick <= 1; end
        else begin cnt <= cnt + 1; tick <= 0; end

    // ---- 去抖采样 ~10ms ----
    reg [19:0] scnt = 0;  reg stick = 0;
    always @(posedge clk)
        if (scnt == 20'd1000000 - 1) begin scnt <= 0; stick <= 1; end
        else begin scnt <= scnt + 1; stick <= 0; end

    // ---- ~2Hz 闪烁 ----
    reg [31:0] fcnt = 0;  reg blink = 0;
    always @(posedge clk)
        if (fcnt == 32'd25000000 - 1) begin fcnt <= 0; blink <= ~blink; end
        else fcnt <= fcnt + 1;

    reg run = 0, done = 0, ack = 0, started = 0;
    wire setting = mode & ~run & ~done & ~viewsw & ~started;   // 定时设置态
    wire set_up  = ~mode & ~run & ~started & ~viewsw;          // 正计时调整态(S4 调小时)

    // ---- 按键边沿 + S1/S3 长按连加 ----
    reg a_st=0,b_st=0, a_sp=0,b_sp=0, a_rs=0,b_rs=0, a_lp=0,b_lp=0;
    reg p_st=0,p_sp=0,p_rs=0,p_lp=0;
    reg [7:0] h_in=0;  reg a_in=0;  reg p_in=0;
    reg [7:0] h_fr=0;  reg a_fr=0;  reg p_fr=0;
    always @(posedge clk) begin
        p_st<=0; p_sp<=0; p_rs<=0; p_lp<=0; p_in<=0; p_fr<=0;
        if (stick) begin
            if (a_st&&!b_st) p_st<=1;   b_st<=a_st; a_st<=start;
            if (a_sp&&!b_sp) p_sp<=1;   b_sp<=a_sp; a_sp<=stop;
            if (a_rs&&!b_rs) p_rs<=1;   b_rs<=a_rs; a_rs<=~rst;   // S6 低有效
            if (a_lp&&!b_lp) p_lp<=1;   b_lp<=a_lp; a_lp<=lap;
            a_in <= inc;
            if (a_in) begin h_in<=h_in+1;
                if (h_in==8'd0) p_in<=1;
                else if (h_in>=8'd40 && h_in[3:0]==4'd0) p_in<=1;
            end else h_in<=0;
            a_fr <= frac;
            if (a_fr) begin h_fr<=h_fr+1;
                if (h_fr==8'd0) p_fr<=1;
                else if (h_fr>=8'd40 && h_fr[3:0]==4'd0) p_fr<=1;
            end else h_fr<=0;
        end
    end

    // ---- 定时设定值(时=0, 分/秒可调) ----
    reg [5:0] set_min = 6'd0;
    reg [5:0] set_sec = 6'd10;
    always @(posedge clk)
        if (p_rs) begin set_min<=6'd0; set_sec<=6'd10; end
        else if (setting) begin
            if (p_in) set_sec <= (set_sec==6'd59)?6'd0:set_sec+1;  // S1 秒+
            if (p_sp) set_sec <= (set_sec==6'd0 )?6'd59:set_sec-1; // S0 秒-
            if (p_fr) set_min <= (set_min==6'd59)?6'd0:set_min+1;  // S3 分+
        end

    // ---- 主计数: 厘秒/秒/分/时 ----
    reg [6:0] cs  = 0;   // 厘秒 0-99
    reg [5:0] sec = 0;   // 秒   0-59
    reg [5:0] mnt = 0;   // 分   0-59
    reg [6:0] hr  = 0;   // 时   0-99 (100进制)

    // ---- 当前显示读数(8 位 BCD) ----
    wire [3:0] h10 = hr  / 10,  h01 = hr  % 10;
    wire [3:0] m10 = mnt / 10,  m01 = mnt % 10;
    wire [3:0] s10 = sec / 10,  s01 = sec % 10;
    wire [3:0] c10 = cs  / 10,  c01 = cs  % 10;
    wire [31:0] live = { h10, h01, m10, m01, s10, s01, c10, c01 };

    // ---- 5 组记录 + 查阅指针 ----
    reg [31:0] rec0=0, rec1=0, rec2=0, rec3=0, rec4=0;
    reg [2:0]  lidx = 0;   // 下一写入位置 0..4
    reg [2:0]  vidx = 0;   // 查阅第几组

    always @(posedge clk) begin
        if (p_rs) begin
            run<=0; done<=0; ack<=0; started<=0; vidx<=0; lidx<=0;
            cs<=0; sec<=0; mnt<=0; hr<=0;
            rec0<=0; rec1<=0; rec2<=0; rec3<=0; rec4<=0;
        end else begin
            // 设置态: 计数跟随设定值
            if (setting) begin cs<=0; sec<=set_sec; mnt<=set_min; hr<=0; end
            // 正计时未启动时分秒归零(小时保留, 由 S4 调整)
            else if (mode==0 & ~started & ~run) begin cs<=0; sec<=0; mnt<=0; end

            // S2: 查阅翻组 / 完成确认 / 启动继续
            if (p_st) begin
                if (viewsw)    vidx <= (vidx==3'd4)?3'd0:vidx+1;
                else if (done) ack  <= 1;
                else           begin run <= 1; started <= 1; end
            end
            // S0: 暂停 (非设置/非查阅); 完成态可确认
            if (p_sp & ~setting & ~viewsw) begin
                if (done) ack <= 1;
                else      run <= 0;
            end

            // S4: 正计时调整态=小时+ (0-99循环, 100进制); 否则=记录当前读数
            if (p_lp & ~viewsw) begin
                if (set_up)
                    hr <= (hr==7'd99) ? 7'd0 : hr+1;
                else begin
                    case (lidx)
                        0: rec0<=live; 1: rec1<=live; 2: rec2<=live;
                        3: rec3<=live; 4: rec4<=live;
                    endcase
                    lidx <= (lidx==3'd4)?3'd0:lidx+1;
                end
            end

            // 计时推进
            if (run & tick) begin
                if (mode==0) begin
                    // 正计时: 厘秒→秒→分→时 级联进位, 时 24 进制
                    if (cs==7'd99) begin cs<=0;
                        if (sec==6'd59) begin sec<=0;
                            if (mnt==6'd59) begin mnt<=0;
                                hr <= (hr==7'd99)?7'd0:hr+1;
                            end else mnt<=mnt+1;
                        end else sec<=sec+1;
                    end else cs<=cs+1;
                end else begin
                    // 倒计时: 借位递减, 到 0 完成
                    if (cs==0) begin
                        if (sec==0) begin
                            if (mnt==0) begin
                                if (hr==0) begin run<=0; done<=1; end
                                else begin hr<=hr-1; mnt<=6'd59; sec<=6'd59; cs<=7'd99; end
                            end else begin mnt<=mnt-1; sec<=6'd59; cs<=7'd99; end
                        end else begin sec<=sec-1; cs<=7'd99; end
                    end else cs<=cs-1;
                end
            end
        end
    end

    // ---- 显示来源 ----
    reg [31:0] showv;
    always @(*)
        if (viewsw)
            case (vidx)
                3'd0: showv=rec0; 3'd1: showv=rec1; 3'd2: showv=rec2;
                3'd3: showv=rec3; 3'd4: showv=rec4; default: showv=rec0;
            endcase
        else showv = live;
    assign data = showv;

    // ---- LED 状态 ----
    //  正计时: [7]运行 [6]暂停
    //  倒计时: [5]运行 [4]暂停 [3]完成(闪/确认常亮)
    //  查阅:   [3:0]组号
    always @(*) begin
        led = 8'b0;
        if (viewsw) led[3:0] = vidx;
        else if (mode==0) begin led[7]=run; led[6]=started&~run; end
        else begin
            led[5]=run;
            if (done) led[3] = ack ? 1'b1 : blink;
            else      led[4] = started & ~run;
        end
    end
endmodule
